
import 'package:imp_trading_chart/imp_trading_chart.dart' show Candle;
import 'package:imp_trading_chart/src/engine/chart_viewport.dart' show ChartViewport;
import 'package:imp_trading_chart/src/engine/price_scale.dart' show PriceScale;
import 'package:imp_trading_chart/src/math/coordinate_mapper.dart' show CoordinateMapper;

/// Chart engine that manages viewport, scaling, and coordinate mapping.
/// 
/// This is the core logic layer - it computes what to render and how,
/// but does NOT render anything itself.
/// 
/// ## Price Scale Modes:
/// - Line charts: Use close prices only for proper vertical space utilization
/// - Candlestick charts: Use high/low prices to show full price range
class ChartEngine {
    final List<Candle> _candles;
    final ChartViewport _viewport;
    final bool _useCloseOnlyPriceScale;
    PriceScale? _cachedScale;
    int _cachedScaleVersion = 0;
    int _scaleVersion = 0;

    ChartEngine({
        required List<Candle> candles,
        ChartViewport? initialViewport,
        int? defaultVisibleCount,
        bool useCloseOnlyPriceScale = true, // Default to true for line charts
    }) : _candles = List.unmodifiable(candles),
        _viewport = initialViewport ?? _defaultViewport(candles.length, defaultVisibleCount),
        _useCloseOnlyPriceScale = useCloseOnlyPriceScale;

    static ChartViewport _defaultViewport(int totalCount, int? defaultVisibleCount) {
        final visibleCount = defaultVisibleCount ?? 100;
        if (totalCount == 0) {
            return ChartViewport(startIndex: 0, visibleCount: visibleCount, totalCount: 0);
        }
        // Show last N candles by default (where N is defaultVisibleCount or 100), or all if less than N
        return ChartViewport.last(visibleCount.clamp(1, totalCount), totalCount);
    }

    /// Get current candles (immutable)
    List<Candle> get candles => _candles;

    /// Get current viewport
    ChartViewport get viewport => _viewport;

    /// Update candles (creates new engine instance - immutable pattern)
    ChartEngine withCandles(List<Candle> newCandles, {int? defaultVisibleCount}) {
        final engine = ChartEngine(
            candles: newCandles,
            initialViewport: _viewport.copyWith(totalCount: newCandles.length),
            defaultVisibleCount: defaultVisibleCount,
            useCloseOnlyPriceScale: _useCloseOnlyPriceScale,
        );
        // Invalidate scale cache
        engine._cachedScaleVersion = _scaleVersion + 1;
        return engine;
    }

    /// Get visible candles based on current viewport
    List<Candle> getVisibleCandles() {
        final range = _viewport.visibleRange;
        if (range.start >= _candles.length) return [];
        return _candles.sublist(
            range.start,
            range.end.clamp(0, _candles.length),
        );
    }

    /// Calculate price scale for visible candles (cached)
    /// 
    /// For line charts, uses close prices only (default).
    /// For candlestick charts, uses high/low prices.
    PriceScale getPriceScale({double paddingPercent = 0.05}) {
        // Check cache
        if (_cachedScale != null && _cachedScaleVersion == _scaleVersion) {
            return _cachedScale!;
        }

        // Recalculate using appropriate method based on chart type
        final visibleCandles = getVisibleCandles();
        if (_useCloseOnlyPriceScale) {
            // Line chart: use close prices only for proper vertical space utilization
            _cachedScale = PriceScale.fromCandlesCloseOnly(visibleCandles, paddingPercent: paddingPercent);
        } else {
            // Candlestick chart: use high/low prices
            _cachedScale = PriceScale.fromCandles(visibleCandles, paddingPercent: paddingPercent);
        }
        _cachedScaleVersion = _scaleVersion;
        return _cachedScale!;
    }

    /// Update viewport (pan/zoom)
    ChartEngine withViewport(ChartViewport newViewport) {
        final engine = ChartEngine(
            candles: _candles,
            initialViewport: newViewport,
            useCloseOnlyPriceScale: _useCloseOnlyPriceScale,
        );
        // Invalidate scale cache since visible candles changed
        engine._scaleVersion = _scaleVersion + 1;
        engine._cachedScale = null;
        return engine;
    }

    /// Pan viewport
    ChartEngine pan(int delta) {
        return withViewport(_viewport.pan(delta));
    }

    /// Zoom viewport
    ChartEngine zoom(int delta, {int minVisible = 5, int maxVisible = 1000}) {
        return withViewport(_viewport.zoom(delta, minVisible: minVisible, maxVisible: maxVisible));
    }

    /// Zoom around a specific index
    ChartEngine zoomAround(int anchorIndex, int delta, {int minVisible = 5, int maxVisible = 1000}) {
        return withViewport(_viewport.zoomAround(anchorIndex, delta, minVisible: minVisible, maxVisible: maxVisible));
    }

    /// Reset viewport to show last N candles
    ChartEngine resetViewport({int visibleCount = 100}) {
        final newViewport = ChartViewport.last(visibleCount, _candles.length);
        return withViewport(newViewport);
    }

    /// Create coordinate mapper for rendering
    CoordinateMapper createMapper({
        required double chartWidth,
        required double chartHeight,
        double paddingLeft = 60.0,
        double paddingRight = 10.0,
        double paddingTop = 10.0,
        double paddingBottom = 40.0,
        double paddingPercent = 0.05,
    }) {
        final scale = getPriceScale(paddingPercent: paddingPercent);
        return CoordinateMapper(
            viewport: _viewport,
            priceScale: scale,
            chartWidth: chartWidth,
            chartHeight: chartHeight,
            paddingLeft: paddingLeft,
            paddingRight: paddingRight,
            paddingTop: paddingTop,
            paddingBottom: paddingBottom,
        );
    }

    /// Handle live tick update
    /// 
    /// If tick belongs to current candle, update it.
    /// If new candle started, append it.
    /// Returns new engine and whether viewport should auto-scroll
    (ChartEngine, bool) handleTick(int time, double price) {
        if (_candles.isEmpty) {
            // First candle
            final newCandle = Candle(
                time: time,
                open: price,
                high: price,
                low: price,
                close: price,
            );
            return (withCandles([newCandle]), true);
        }

        final lastCandle = _candles.last;

        // Check if tick belongs to current candle (same time)
        // Note: This assumes time represents the candle's start time
        // In production, you'd need interval logic here, but as per requirements,
        // aggregation is handled by data layer, so we just compare times
        if (lastCandle.time == time) {
            // Update last candle
            final updatedCandle = lastCandle.updateWithTick(price);
            final newCandles = [..._candles];
            newCandles[newCandles.length - 1] = updatedCandle;
            final newEngine = withCandles(newCandles);

            // Auto-scroll if we're at the end
            final shouldScroll = _viewport.endIndex >= _candles.length;
            if (shouldScroll) {
                return (newEngine.resetViewport(visibleCount: _viewport.visibleCount), true);
            }
            return (newEngine, false);
        } else {
            // New candle started
            final newCandle = Candle(
                time: time,
                open: price,
                high: price,
                low: price,
                close: price,
            );
            final newCandles = [..._candles, newCandle];
            final newEngine = withCandles(newCandles);

            // Auto-scroll if we were at the end
            final shouldScroll = _viewport.endIndex >= _candles.length;
            if (shouldScroll) {
                return (newEngine.resetViewport(visibleCount: _viewport.visibleCount), true);
            }
            return (newEngine, false);
        }
    }

    /// Get latest price (for current price line)
    double? getLatestPrice() {
        if (_candles.isEmpty) return null;
        return _candles.last.close;
    }
}