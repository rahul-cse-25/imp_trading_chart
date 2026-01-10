import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart'
    show Candle, ChartStyle;
import 'package:imp_trading_chart/src/engine/chart_engine.dart'
    show ChartEngine;
import 'package:imp_trading_chart/src/engine/chart_viewport.dart'
    show ChartViewport;
import 'package:imp_trading_chart/src/rendering/chart_painter.dart'
    show ChartPainter;

/// High-performance chart widget with gesture support.
///
/// This widget:
/// - Manages ChartEngine state
/// - Handles gestures (pan, zoom, double tap)
/// - Supports live updates with pulse animation
/// - Uses RepaintBoundary for performance
/// - Supports multiple instances without lag
class ImpChart extends StatefulWidget {
  final List<Candle> candles;
  final ChartStyle style;
  final double? currentPrice;
  final bool enableGestures;
  final void Function(ChartEngine)? onViewportChanged;
  final int? defaultVisibleCount;

  /// Callback when crosshair hovers over a candle.
  ///
  /// Called with:
  /// - The [Candle] data when hovering over a valid candle
  /// - `null` when crosshair is released/hidden
  ///
  /// Useful for displaying candle details in a tooltip or info panel.
  final void Function(Candle? candle)? onCrosshairChanged;

  /// Enable haptic feedback when new candle data is plotted/added.
  ///
  /// Default: `false` (disabled)
  ///
  /// When enabled, triggers light haptic feedback when:
  /// - A new candle is added to the chart
  /// - Existing candle data is updated (live updates)
  final bool plotFeedback;

  /// Enable haptic feedback when crosshair changes position.
  ///
  /// Default: `false` (disabled)
  ///
  /// When enabled, triggers light haptic feedback when:
  /// - Crosshair moves to a different candle
  /// - Crosshair is first shown
  final bool crosshairChangeFeedback;

  ImpChart({
    super.key,
    required this.candles,
    ChartStyle? style,
    this.currentPrice,
    this.enableGestures = true,
    this.onViewportChanged,
    this.defaultVisibleCount,
    this.onCrosshairChanged,
    this.plotFeedback = false,
    this.crosshairChangeFeedback = false,
  }) : style = style ?? ChartStyle();

  @override
  State<ImpChart> createState() => _ImpChartState();

  /// Factory: Minimal chart - just the line, no labels, grid, or animations
  /// Perfect for embedding in small spaces or when you need maximum simplicity
  factory ImpChart.minimal({
    required List<Candle> candles,
    Color? lineColor,
    double? lineWidth,
    bool showLineGlow = true,
    void Function(ChartEngine)? onViewportChanged,
    void Function(Candle?)? onCrosshairChanged,
    int? defaultVisibleCount,
    bool plotFeedback = false,
    bool crosshairChangeFeedback = false,
  }) {
    return ImpChart(
      candles: candles,
      enableGestures: false,
      onViewportChanged: onViewportChanged,
      onCrosshairChanged: onCrosshairChanged,
      defaultVisibleCount: defaultVisibleCount,
      plotFeedback: plotFeedback,
      crosshairChangeFeedback: crosshairChangeFeedback,
      style: ChartStyle.minimal(
        lineColor: lineColor ?? const Color.fromRGBO(15, 173, 0, 1),
        lineWidth: lineWidth ?? 2.0,
        showLineGlow: showLineGlow,
      ),
    );
  }

  /// Factory: Simple chart - line with basic labels, no grid or animations
  /// Good for general purpose usage with minimal styling
  factory ImpChart.simple({
    required List<Candle> candles,
    Color? lineColor,
    Color? textColor,
    Color? backgroundColor,
    double? lineWidth,
    double? currentPrice,
    bool enableGestures = true,
    void Function(ChartEngine)? onViewportChanged,
    void Function(Candle?)? onCrosshairChanged,
    int? defaultVisibleCount,
    bool plotFeedback = false,
    bool crosshairChangeFeedback = false,
  }) {
    return ImpChart(
      candles: candles,
      currentPrice: currentPrice,
      enableGestures: enableGestures,
      onViewportChanged: onViewportChanged,
      onCrosshairChanged: onCrosshairChanged,
      defaultVisibleCount: defaultVisibleCount,
      plotFeedback: plotFeedback,
      crosshairChangeFeedback: crosshairChangeFeedback,
      style: ChartStyle.simple(
        backgroundColor: backgroundColor ?? Colors.transparent,
        textColor: textColor ?? Colors.white,
        lineColor: lineColor ?? Colors.blue,
        lineWidth: lineWidth ?? 2.0,
      ),
    );
  }

  /// Factory: Full featured trading chart - all features enabled
  /// Perfect for professional trading applications with all bells and whistles
  factory ImpChart.trading({
    Key? key,
    required List<Candle> candles,
    Color? lineColor,
    Color? backgroundColor,
    Color? pulseColor,
    double? currentPrice,
    bool showCrosshair = true,
    bool enableGestures = true,
    void Function(ChartEngine)? onViewportChanged,
    void Function(Candle? candle)? onCrosshairChanged,
    int? defaultVisibleCount,
    bool plotFeedback = true,
    bool crosshairChangeFeedback = true,
  }) {
    return ImpChart(
      key: key,
      candles: candles,
      currentPrice: currentPrice,
      enableGestures: enableGestures,
      onViewportChanged: onViewportChanged,
      onCrosshairChanged: onCrosshairChanged,
      defaultVisibleCount: defaultVisibleCount,
      plotFeedback: plotFeedback,
      crosshairChangeFeedback: crosshairChangeFeedback,
      style: ChartStyle.trading(
          backgroundColor: backgroundColor ?? Colors.transparent,
          lineColor: lineColor ?? const Color(0xFF78D99B),
          pulseColor: pulseColor ?? lineColor ?? const Color(0xFF78D99B),
          showCrosshair: showCrosshair),
    );
  }

  /// Factory: Compact chart - optimized for small spaces
  /// Minimal padding, smaller fonts, perfect for dashboards
  factory ImpChart.compact({
    required List<Candle> candles,
    Color? lineColor,
    Color? backgroundColor,
    double? currentPrice,
    bool enableGestures = true,
    bool showGrid = true,
    bool showPriceLabels = true,
    bool showTimeLabels = true,
    void Function(ChartEngine)? onViewportChanged,
    void Function(Candle?)? onCrosshairChanged,
    int? defaultVisibleCount,
    bool plotFeedback = false,
    bool crosshairChangeFeedback = false,
  }) {
    return ImpChart(
      candles: candles,
      currentPrice: currentPrice,
      enableGestures: enableGestures,
      onViewportChanged: onViewportChanged,
      onCrosshairChanged: onCrosshairChanged,
      defaultVisibleCount: defaultVisibleCount,
      plotFeedback: plotFeedback,
      crosshairChangeFeedback: crosshairChangeFeedback,
      style: ChartStyle.compact(
        backgroundColor: backgroundColor ?? Colors.transparent,
        lineColor: lineColor ?? Colors.blue,
        showGrid: showGrid,
        showPriceLabels: showPriceLabels,
        showTimeLabels: showTimeLabels,
      ),
    );
  }
}

class _ImpChartState extends State<ImpChart>
    with SingleTickerProviderStateMixin {
  late ChartEngine _engine;
  late AnimationController _pulseController;
  Timer? _rippleTimer; // Timer for continuous ripple cycle
  double _pulseProgress = 0.0;
  double _baseScale = 1.0; // For gesture zoom accumulation
  Offset? _lastPanPosition; // For pan gesture tracking
  double _accumulatedPanDelta = 0.0; // Accumulate small pan movements
  Offset? _crosshairPosition; // For crosshair tracking
  int? _crosshairIndex; // Candle index at crosshair

  @override
  void initState() {
    super.initState();
    _engine = ChartEngine(
      candles: widget.candles,
      defaultVisibleCount: widget.defaultVisibleCount,
    );

    // Pulse animation for live updates - continuous ripple effect
    // Duration from style configuration (default 2000ms)
    final rippleStyle = widget.style.rippleStyle;
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: rippleStyle.animationDurationMs),
    );
    _pulseController.addListener(_pulseListener);

    // Start continuous ripple cycle if enabled
    if (widget.candles.isNotEmpty && widget.style.rippleStyle.show) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startContinuousRipple();
        }
      });
    }
  }

  @override
  void didUpdateWidget(ImpChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Always check if candles changed (by reference or content)
    final candlesChanged = widget.candles != oldWidget.candles;
    final candleCountChanged =
        widget.candles.length != oldWidget.candles.length;

    // Check if last candle changed (for live updates even if list reference is same)
    // This handles cases where list is mutated in place
    bool lastCandleChanged = false;
    if (!candleCountChanged &&
        widget.candles.isNotEmpty &&
        oldWidget.candles.isNotEmpty &&
        _engine.candles.isNotEmpty) {
      final currentLastCandle = widget.candles.last;
      final engineLastCandle = _engine.candles.last;
      // Compare with engine's last candle to detect changes
      lastCandleChanged = currentLastCandle.close != engineLastCandle.close ||
          currentLastCandle.high != engineLastCandle.high ||
          currentLastCandle.low != engineLastCandle.low ||
          currentLastCandle.open != engineLastCandle.open;
    }

    if (candlesChanged || lastCandleChanged) {
      final oldCandleCount = oldWidget.candles.length;
      final newCandleCount = widget.candles.length;
      final oldEndIndex = _engine.viewport.endIndex;

      // Check if we were viewing near the end (within last 3 candles)
      // This ensures auto-scroll works when user is viewing recent data
      final wasNearEnd = oldEndIndex >= (oldCandleCount - 3);

      // CRITICAL: Check if this is a data replacement (old was empty, new has data)
      // This happens when range/timeframe changes - we should reset viewport to defaultVisibleCount
      final isDataReplacement = oldCandleCount == 0 && newCandleCount > 0;

      // Also detect if first candle time changed (indicates completely new data, not just update)
      bool isCompletelyNewData = false;
      if (oldCandleCount > 0 && newCandleCount > 0) {
        isCompletelyNewData =
            widget.candles.first.time != oldWidget.candles.first.time;
      }

      // Update engine with new candles
      var newEngine = _engine.withCandles(widget.candles,
          defaultVisibleCount: widget.defaultVisibleCount);

      // If this is a data replacement or completely new data, reset viewport to defaultVisibleCount
      if (isDataReplacement || isCompletelyNewData) {
        final targetVisibleCount = widget.defaultVisibleCount ?? 100;
        newEngine = newEngine.withViewport(
          ChartViewport.last(
              targetVisibleCount.clamp(1, newCandleCount), newCandleCount),
        );
        _updateEngine(newEngine);
      }
      // Check if new candle was added (not just updated)
      else if (newCandleCount > oldCandleCount) {
        // New candle added - trigger pulse animation
        _triggerPulse();

        // Haptic feedback for new data plot
        if (widget.plotFeedback) {
          HapticFeedback.lightImpact();
        }

        // Auto-scroll to show the latest candle if we were near the end
        if (wasNearEnd) {
          // Keep current zoom level but ensure last candle is visible
          // Also ensure we expand to defaultVisibleCount if current count is smaller
          final targetVisibleCount = widget.defaultVisibleCount ?? 100;
          final currentVisibleCount = _engine.viewport.visibleCount;
          final visibleCount = math.max(currentVisibleCount,
              math.min(targetVisibleCount, newCandleCount));
          newEngine = newEngine.withViewport(
            ChartViewport.last(visibleCount, newCandleCount),
          );
        }
        _updateEngine(newEngine);
      } else if (newCandleCount == oldCandleCount &&
          (candlesChanged || lastCandleChanged)) {
        // Same count but data changed - live update
        // Auto-scroll to ensure last candle is visible if we're near the end
        if (wasNearEnd) {
          // Keep current zoom level but ensure last candle is visible
          final currentVisibleCount = _engine.viewport.visibleCount;
          newEngine = newEngine.withViewport(
            ChartViewport.last(currentVisibleCount, newCandleCount),
          );
          // Last candle was updated (live update) - trigger pulse if enabled
          if (widget.style.rippleStyle.show) {
            _triggerPulse();
          }

          // Haptic feedback for live data update
          if (widget.plotFeedback) {
            HapticFeedback.lightImpact();
          }
        } else {
          // Not near end, but still trigger pulse if we can see the last candle
          if (oldEndIndex >= oldCandleCount && widget.style.rippleStyle.show) {
            _triggerPulse();

            // Haptic feedback for live data update
            if (widget.plotFeedback) {
              HapticFeedback.lightImpact();
            }
          }
        }
        _updateEngine(newEngine);
      } else {
        // Count decreased (shouldn't happen, but handle it)
        _updateEngine(newEngine);
      }
    }

    // Handle ripple animation state changes
    final rippleEnabled =
        widget.style.rippleStyle.show && widget.candles.isNotEmpty;
    final wasRippleEnabled =
        oldWidget.style.rippleStyle.show && oldWidget.candles.isNotEmpty;

    if (rippleEnabled && !wasRippleEnabled) {
      // Ripple just became enabled - start continuous cycle
      _startContinuousRipple();
    } else if (!rippleEnabled && wasRippleEnabled) {
      // Ripple was disabled - stop everything
      _stopContinuousRipple();
    }
    // Note: If ripple is already running, DON'T interfere with it
    // The continuous cycle handles itself
  }

  void _pulseListener() {
    if (mounted) {
      // Update progress and trigger repaint when animation value changes
      final newProgress = _pulseController.value;
      setState(() {
        _pulseProgress = newProgress;
      });
    }
  }

  @override
  void dispose() {
    // Cancel timer and animation directly without setState
    _rippleTimer?.cancel();
    _rippleTimer = null;
    _pulseController.stop();
    _pulseController.removeListener(_pulseListener);
    _pulseController.dispose();
    super.dispose();
  }

  /// Start continuous ripple animation cycle
  /// Runs every (animationDurationMs + intervalMs) ms
  /// Default: 2s animation + 2s interval = 4s total cycle
  void _startContinuousRipple() {
    final rippleStyle = widget.style.rippleStyle;

    if (!mounted || widget.candles.isEmpty || !rippleStyle.show) {
      return;
    }

    // Cancel any existing timer
    _rippleTimer?.cancel();

    // Update animation duration
    _pulseController.duration =
        Duration(milliseconds: rippleStyle.animationDurationMs);

    // Start first animation immediately
    _playRippleAnimation();

    // Set up recurring timer for continuous ripple
    // Total cycle = animation duration + interval
    final totalCycleMs =
        rippleStyle.animationDurationMs + rippleStyle.intervalMs;
    _rippleTimer = Timer.periodic(Duration(milliseconds: totalCycleMs), (_) {
      if (mounted &&
          widget.candles.isNotEmpty &&
          widget.style.rippleStyle.show) {
        _playRippleAnimation();
      }
    });
  }

  /// Stop continuous ripple animation
  void _stopContinuousRipple() {
    _rippleTimer?.cancel();
    _rippleTimer = null;
    if (_pulseController.isAnimating) {
      _pulseController.stop();
    }
    if (mounted) {
      setState(() {
        _pulseProgress = 0.0;
      });
    }
  }

  /// Play a single ripple animation
  void _playRippleAnimation() {
    if (!mounted || !widget.style.rippleStyle.show || widget.candles.isEmpty)
      return;

    // Reset and play animation
    _pulseController.reset();
    _pulseController.forward();
  }

  void _triggerPulse() {
    // For backward compatibility - just ensure ripple is running
    if (!mounted || !widget.style.rippleStyle.show || widget.candles.isEmpty)
      return;

    // If continuous ripple is not running, start it
    if (_rippleTimer == null || !_rippleTimer!.isActive) {
      _startContinuousRipple();
    }
  }

  void _updateEngine(ChartEngine newEngine) {
    setState(() {
      _engine = newEngine;
    });
    widget.onViewportChanged?.call(newEngine);
  }

  void _handleScaleStart(ScaleStartDetails details, Size size) {
    _baseScale = 1.0;
    _lastPanPosition = details.focalPoint;
    _accumulatedPanDelta = 0.0;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details, Size size) {
    if (!widget.enableGestures || widget.style.crosshairStyle.show) return;

    // Check if this is a zoom (scale changed significantly) or pan (only position changed)
    final scaleChange = (details.scale - _baseScale).abs();
    final isZoom =
        scaleChange > 0.05; // Higher threshold to avoid false zoom detection

    if (isZoom) {
      // Handle zoom
      final zoomDelta = (details.scale - _baseScale) > 0 ? -1 : 1;

      // Convert focal point to candle index (relative to widget)
      final padding = _calculatePadding(size);
      final mapper = _engine.createMapper(
        chartWidth: size.width,
        chartHeight: size.height,
        paddingLeft: padding.left,
        paddingRight: padding.right,
        paddingTop: padding.top,
        paddingBottom: padding.bottom,
      );
      final anchorIndex = mapper.xToIndex(details.focalPoint.dx);

      if (anchorIndex >= 0 && anchorIndex < _engine.candles.length) {
        _updateEngine(_engine.zoomAround(anchorIndex, zoomDelta));
      } else {
        _updateEngine(_engine.zoom(zoomDelta));
      }

      _baseScale = details.scale;
      _lastPanPosition = details.focalPoint;
      _accumulatedPanDelta = 0.0;
    } else if (_lastPanPosition != null && !widget.style.crosshairStyle.show) {
      // Handle pan (scale is ~1.0, position changed) - only if crosshair disabled
      // Calculate delta - invert for natural pan (drag right = scroll right = pan left)
      final delta = _lastPanPosition!.dx - details.focalPoint.dx;
      _accumulatedPanDelta += delta;

      final candleWidth = _getCandleWidth(size);

      // Pan more smoothly by accumulating smaller movements
      // Update viewport when accumulated delta >= 1 candle width
      if (candleWidth > 0) {
        final candleDelta = (_accumulatedPanDelta / candleWidth).round();

        if (candleDelta.abs() >= 1) {
          _updateEngine(_engine.pan(candleDelta));
          // Keep the remainder for smooth continuous panning
          _accumulatedPanDelta =
              _accumulatedPanDelta - (candleDelta * candleWidth);
        }
      }

      _lastPanPosition = details.focalPoint;
    }
  }

  void _handleDoubleTap() {
    if (!widget.enableGestures || widget.style.crosshairStyle.show) return;

    // Reset viewport to show last N candles (defaultVisibleCount or 100)
    _updateEngine(
        _engine.resetViewport(visibleCount: widget.defaultVisibleCount ?? 100));
  }

  void _handleLongPressStart(LongPressStartDetails details, Size size) {
    if (!widget.enableGestures || !widget.style.crosshairStyle.show) return;
    _updateCrosshair(details.localPosition, size);
  }

  void _handleLongPressMoveUpdate(
      LongPressMoveUpdateDetails details, Size size) {
    if (!widget.enableGestures || !widget.style.crosshairStyle.show) return;
    _updateCrosshair(details.localPosition, size);
  }

  void _handleLongPressEnd() {
    setState(() {
      _crosshairPosition = null;
      _crosshairIndex = null;
    });

    // Notify listener that crosshair is hidden
    widget.onCrosshairChanged?.call(null);
  }

  void _updateCrosshair(Offset localPosition, Size size) {
    final padding = _calculatePadding(size);
    final mapper = _engine.createMapper(
      chartWidth: size.width,
      chartHeight: size.height,
      paddingLeft: padding.left,
      paddingRight: padding.right,
      paddingTop: padding.top,
      paddingBottom: padding.bottom,
    );

    // Convert touch position to candle index (absolute index in all candles)
    final absoluteIndex = mapper.xToIndex(localPosition.dx);

    if (absoluteIndex >= 0 && absoluteIndex < _engine.candles.length) {
      // Find the index in visible candles array
      final visibleCandles = _engine.getVisibleCandles();
      final relativeIndex = absoluteIndex - mapper.viewport.startIndex;

      if (relativeIndex >= 0 && relativeIndex < visibleCandles.length) {
        final candle = visibleCandles[relativeIndex];

        // Only call callback if candle index actually changed
        // This includes: first show (null -> index), move to different candle
        final indexChanged = _crosshairIndex != relativeIndex;

        setState(() {
          _crosshairPosition = localPosition;
          _crosshairIndex = relativeIndex; // Index in visible candles array
        });

        // Notify listener of candle change
        if (indexChanged) {
          widget.onCrosshairChanged?.call(candle);

          // Haptic feedback for crosshair change (first show or move to different candle)
          if (widget.crosshairChangeFeedback) {
            HapticFeedback.lightImpact();
          }
        }
      }
    }
  }

  double _getCandleWidth(Size size) {
    final padding = _calculatePadding(size);
    final mapper = _engine.createMapper(
      chartWidth: size.width,
      chartHeight: size.height,
      paddingLeft: padding.left,
      paddingRight: padding.right,
      paddingTop: padding.top,
      paddingBottom: padding.bottom,
    );
    return mapper.candleWidth;
  }

  /// Calculate dynamic padding based on visibility and label sizes
  _PaddingInfo _calculatePadding(Size size) {
    // Get layout configuration (use default if not provided)
    final layout = widget.style.layout;

    // Chart data padding (top and left are used directly)
    final chartDataLeft = layout.chartDataPadding.left;
    final chartDataTop = layout.chartDataPadding.top;

    // Calculate Y-axis area width if price labels are shown
    double yAxisAreaWidth = 0.0;
    final priceLabelStyle = widget.style.priceLabelStyle;
    if (priceLabelStyle.show && _engine.candles.isNotEmpty) {
      // Measure the widest price label
      final scale = _engine.getPriceScale();
      final labelFontSize = priceLabelStyle.fontSize;
      final formatter = priceLabelStyle.formatter;

      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      double maxLabelWidth = 0.0;

      final labelCount = priceLabelStyle.labelCount;
      for (int i = 0; i <= labelCount; i++) {
        final price = scale.max - ((scale.max - scale.min) * i / labelCount);
        final priceText = formatter.format(price);
        textPainter.text = TextSpan(
          text: priceText,
          style: TextStyle(fontSize: labelFontSize),
        );
        textPainter.layout();
        maxLabelWidth = math.max(maxLabelWidth, textPainter.width);
      }

      // TradingView approach: Current price label is in SAME column as Y-axis labels
      // Just styled differently (colored background). No extra space needed.

      // Check if current price label would be wider than regular labels
      final currentPriceStyle = widget.style.currentPriceStyle;
      double currentPriceLabelWidth = 0.0;
      if (currentPriceStyle.showLabel && _engine.candles.isNotEmpty) {
        final currentPrice = widget.currentPrice ?? _engine.getLatestPrice();
        if (currentPrice != null) {
          final currentPriceText = formatter.format(currentPrice);
          textPainter.text = TextSpan(
            text: currentPriceText,
            style: TextStyle(
              fontSize: currentPriceStyle.labelFontSize,
              fontWeight: FontWeight.bold,
            ),
          );
          textPainter.layout();
          currentPriceLabelWidth =
              textPainter.width + (currentPriceStyle.labelPaddingH * 2);
        }
      }

      // Y-axis area = gap + max(label width, current price label width) + padding
      final yAxisLabelPadding = layout.yAxisLabelPadding;
      final effectiveLabelWidth =
          math.max(maxLabelWidth, currentPriceLabelWidth);
      yAxisAreaWidth =
          layout.yAxisGap + effectiveLabelWidth + yAxisLabelPadding.horizontal;
    }

    // Calculate X-axis area height if time labels are shown
    double xAxisAreaHeight = 0.0;
    final timeLabelStyle = widget.style.timeLabelStyle;
    if (timeLabelStyle.show && _engine.candles.isNotEmpty) {
      final labelFontSize = timeLabelStyle.fontSize;

      final textPainter = TextPainter(
        text: TextSpan(
          text: '00:00', // Sample time format
          style: TextStyle(fontSize: labelFontSize),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // X-axis area = gap + label height + label padding
      final xAxisLabelPadding = layout.xAxisLabelPadding;
      xAxisAreaHeight =
          layout.xAxisGap + textPainter.height + xAxisLabelPadding.vertical;
    }

    return _PaddingInfo(
      left: chartDataLeft,
      right:
          yAxisAreaWidth > 0 ? yAxisAreaWidth : layout.chartDataPadding.right,
      top: chartDataTop,
      bottom: xAxisAreaHeight > 0
          ? xAxisAreaHeight
          : layout.chartDataPadding.bottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final padding = _calculatePadding(size);

          return GestureDetector(
            onScaleStart: widget.style.crosshairStyle.show
                ? null
                : (details) => _handleScaleStart(details, size),
            onScaleUpdate: widget.style.crosshairStyle.show
                ? null
                : (details) => _handleScaleUpdate(details, size),
            onDoubleTap:
                widget.style.crosshairStyle.show ? null : _handleDoubleTap,
            onLongPressStart: widget.style.crosshairStyle.show
                ? (details) => _handleLongPressStart(details, size)
                : null,
            onLongPressMoveUpdate: widget.style.crosshairStyle.show
                ? (details) => _handleLongPressMoveUpdate(details, size)
                : null,
            onLongPressEnd: widget.style.crosshairStyle.show
                ? (_) => _handleLongPressEnd()
                : null,
            child: CustomPaint(
              painter: ChartPainter(
                candles: _engine.getVisibleCandles(),
                mapper: _engine.createMapper(
                  chartWidth: size.width,
                  chartHeight: size.height,
                  paddingLeft: padding.left,
                  paddingRight: padding.right,
                  paddingTop: padding.top,
                  paddingBottom: padding.bottom,
                ),
                style: widget.style,
                currentPrice: widget.currentPrice ?? _engine.getLatestPrice(),
                pulseProgress: _pulseProgress,
                crosshairPosition: _crosshairPosition,
                crosshairIndex: _crosshairIndex,
              ),
              size: size,
            ),
          );
        },
      ),
    );
  }
}

/// Helper class for padding information
class _PaddingInfo {
  final double left;
  final double right;
  final double top;
  final double bottom;

  const _PaddingInfo({
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  });
}
