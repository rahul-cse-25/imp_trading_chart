import 'package:imp_trading_chart/imp_trading_chart.dart' show Candle;
import 'package:imp_trading_chart/src/engine/chart_viewport.dart'
    show ChartViewport;
import 'package:imp_trading_chart/src/engine/price_scale.dart' show PriceScale;
import 'package:imp_trading_chart/src/math/coordinate_mapper.dart'
    show CoordinateMapper;

/// ─────────────────────────────────────────────────────────────
/// 🧠 ChartEngine
/// ─────────────────────────────────────────────────────────────
///
/// The **core logic layer** of the chart system.
///
/// This class is responsible for:
/// - Managing the viewport (what portion of data is visible)
/// - Calculating price scales for visible data
/// - Providing coordinate mapping for rendering
/// - Handling pan / zoom operations
/// - Supporting live tick updates (append or update candles)
///
/// ❌ This class does NOT:
/// - Render anything
/// - Know about Flutter widgets
/// - Handle gestures directly
///
/// ### Design philosophy
/// - Immutable-by-convention (returns new instances)
/// - Cache-heavy for performance
/// - Data-driven, not UI-driven
///
/// ---
///
/// ### Price scale modes
/// - **Line charts**: use *close prices only*
///   → better vertical space utilization
/// - **Candlestick charts**: use *high/low prices*
///   → full price range visibility
///
/// This choice is controlled by [_useCloseOnlyPriceScale].
class ChartEngine {
  /// Immutable candle dataset.
  ///
  /// IMPORTANT INVARIANT:
  /// - This list must never be mutated.
  /// - All updates create a new engine instance.
  final List<Candle> _candles;

  /// Current viewport describing which candles are visible.
  final ChartViewport _viewport;

  /// Controls how price scale is calculated.
  ///
  /// true  → use close prices only (line chart)
  /// false → use high/low prices (candlestick chart)
  final bool _useCloseOnlyPriceScale;

  /// Cached price scale for current viewport.
  ///
  /// This cache avoids recomputing min/max on every paint.
  PriceScale? _cachedScale;

  /// Version number of the cached scale.
  ///
  /// Used to validate cache correctness.
  int _cachedScaleVersion = 0;

  /// Monotonic version counter incremented whenever
  /// viewport or visible candles change.
  ///
  /// When this changes, cached scale becomes invalid.
  int _scaleVersion = 0;

  ChartEngine({
    required List<Candle> candles,
    ChartViewport? initialViewport,
    int? defaultVisibleCount,
    bool useCloseOnlyPriceScale = true,
  })  : _candles = List.unmodifiable(candles),
        _viewport = initialViewport ??
            _defaultViewport(candles.length, defaultVisibleCount),
        _useCloseOnlyPriceScale = useCloseOnlyPriceScale;

  /// Create default viewport for initial render.
  ///
  /// Behavior:
  /// - If no data → empty viewport
  /// - Otherwise → show last N candles (default 100)
  static ChartViewport _defaultViewport(
      int totalCount, int? defaultVisibleCount) {
    final visibleCount = defaultVisibleCount ?? 100;

    if (totalCount == 0) {
      return ChartViewport(
        startIndex: 0,
        visibleCount: visibleCount,
        totalCount: 0,
      );
    }

    return ChartViewport.last(
      visibleCount.clamp(1, totalCount),
      totalCount,
    );
  }

  /// Public read-only access to candles.
  List<Candle> get candles => _candles;

  /// Current viewport.
  ChartViewport get viewport => _viewport;

  /// Replace candle dataset.
  ///
  /// IMPORTANT:
  /// - Returns a NEW engine instance
  /// - Preserves viewport position when possible
  /// - Invalidates price scale cache
  ChartEngine withCandles(
    List<Candle> newCandles, {
    int? defaultVisibleCount,
  }) {
    final engine = ChartEngine(
      candles: newCandles,
      initialViewport: _viewport.copyWith(
        totalCount: newCandles.length,
      ),
      defaultVisibleCount: defaultVisibleCount,
      useCloseOnlyPriceScale: _useCloseOnlyPriceScale,
    );

    // Invalidate cached scale
    engine._cachedScaleVersion = _scaleVersion + 1;
    return engine;
  }

  /// Get candles currently visible in viewport.
  ///
  /// This method NEVER allocates more data than necessary.
  List<Candle> getVisibleCandles() {
    final range = _viewport.visibleRange;

    if (range.start >= _candles.length) return [];

    return _candles.sublist(
      range.start,
      range.end.clamp(0, _candles.length),
    );
  }

  /// Calculate price scale for visible candles.
  ///
  /// Uses caching to avoid repeated calculations during repaint.
  ///
  /// Cache is invalidated when:
  /// - Viewport changes
  /// - Candle data changes
  PriceScale getPriceScale({double paddingPercent = 0.05}) {
    if (_cachedScale != null && _cachedScaleVersion == _scaleVersion) {
      return _cachedScale!;
    }

    final visibleCandles = getVisibleCandles();

    if (_useCloseOnlyPriceScale) {
      _cachedScale = PriceScale.fromCandlesCloseOnly(
        visibleCandles,
        paddingPercent: paddingPercent,
      );
    } else {
      _cachedScale = PriceScale.fromCandles(
        visibleCandles,
        paddingPercent: paddingPercent,
      );
    }

    _cachedScaleVersion = _scaleVersion;
    return _cachedScale!;
  }

  /// Replace viewport.
  ///
  /// This invalidates price scale cache because
  /// visible candles change.
  ChartEngine withViewport(ChartViewport newViewport) {
    final engine = ChartEngine(
      candles: _candles,
      initialViewport: newViewport,
      useCloseOnlyPriceScale: _useCloseOnlyPriceScale,
    );

    engine._scaleVersion = _scaleVersion + 1;
    engine._cachedScale = null;
    return engine;
  }

  /// Pan viewport horizontally by candle delta.
  ChartEngine pan(int delta) {
    return withViewport(_viewport.pan(delta));
  }

  /// Zoom viewport around center.
  ChartEngine zoom(
    int delta, {
    int minVisible = 5,
    int maxVisible = 1000,
  }) {
    return withViewport(
      _viewport.zoom(
        delta,
        minVisible: minVisible,
        maxVisible: maxVisible,
      ),
    );
  }

  /// Zoom viewport around a specific candle index.
  ///
  /// Used to keep candle under finger stable during pinch-zoom.
  ChartEngine zoomAround(
    int anchorIndex,
    int delta, {
    int minVisible = 5,
    int maxVisible = 1000,
  }) {
    return withViewport(
      _viewport.zoomAround(
        anchorIndex,
        delta,
        minVisible: minVisible,
        maxVisible: maxVisible,
      ),
    );
  }

  /// Reset viewport to show last N candles.
  ChartEngine resetViewport({int visibleCount = 100}) {
    return withViewport(
      ChartViewport.last(visibleCount, _candles.length),
    );
  }

  /// Create coordinate mapper for rendering.
  ///
  /// This bridges:
  /// engine-space → screen-space
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

  /// Handle live tick update.
  ///
  /// ASSUMPTIONS:
  /// - Data aggregation is handled upstream
  /// - [time] represents candle start time
  ///
  /// Returns:
  /// - New engine instance
  /// - Whether viewport should auto-scroll
  (ChartEngine, bool) handleTick(int time, double price) {
    if (_candles.isEmpty) {
      final candle = Candle(
        time: time,
        open: price,
        high: price,
        low: price,
        close: price,
      );
      return (withCandles([candle]), true);
    }

    final lastCandle = _candles.last;

    if (lastCandle.time == time) {
      final updated = lastCandle.updateWithTick(price);

      final newCandles = [..._candles];
      newCandles[newCandles.length - 1] = updated;

      final engine = withCandles(newCandles);
      final shouldScroll = _viewport.endIndex >= _candles.length;

      return shouldScroll
          ? (
              engine.resetViewport(
                visibleCount: _viewport.visibleCount,
              ),
              true
            )
          : (engine, false);
    } else {
      final candle = Candle(
        time: time,
        open: price,
        high: price,
        low: price,
        close: price,
      );

      final engine = withCandles([..._candles, candle]);
      final shouldScroll = _viewport.endIndex >= _candles.length;

      return shouldScroll
          ? (
              engine.resetViewport(
                visibleCount: _viewport.visibleCount,
              ),
              true
            )
          : (engine, false);
    }
  }

  /// Get latest close price.
  ///
  /// Used for:
  /// - Current price line
  /// - Current price label
  double? getLatestPrice() {
    if (_candles.isEmpty) return null;
    return _candles.last.close;
  }
}
