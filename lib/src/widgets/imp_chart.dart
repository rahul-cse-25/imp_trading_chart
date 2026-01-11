import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart';
// INTERNAL ENGINE IMPORTS (INTENTIONALLY NOT EXPORTED)
//
// These imports are used ONLY by the widget layer to
// coordinate engine state and rendering.
//
// Consumers of the package must NOT rely on these classes directly.
import 'package:imp_trading_chart/src/engine/chart_engine.dart'
    show ChartEngine;
import 'package:imp_trading_chart/src/engine/chart_viewport.dart'
    show ChartViewport;
import 'package:imp_trading_chart/src/rendering/chart_painter.dart'
    show ChartPainter;

/// ─────────────────────────────────────────────────────────
/// 🧩 ImpChart
/// ─────────────────────────────────────────────────────────
///
/// High-performance Flutter widget that renders a trading chart
/// using a CustomPainter-driven rendering engine.
///
/// This widget is intentionally **thin** and acts as:
/// - A bridge between Flutter gestures and the chart engine
/// - A lifecycle owner for animations and timers
/// - A coordinator between data, engine state, and rendering
///
/// ### Responsibilities
/// - Owns and updates [ChartEngine]
/// - Handles user interactions (pan, zoom, double tap, crosshair)
/// - Manages live-update ripple animation
/// - Calculates dynamic layout padding
///
/// ### Non-responsibilities
/// - ❌ Does NOT perform heavy calculations
/// - ❌ Does NOT draw candles directly
/// - ❌ Does NOT contain chart math or scaling logic
///
/// All heavy logic lives in the engine and rendering layers.
class ImpChart extends StatefulWidget {
  /// Full candle dataset (already aggregated).
  ///
  /// The engine decides which candles are visible based on viewport.
  final List<Candle> candles;

  /// Visual styling and layout configuration.
  ///
  /// This object is immutable and declarative.
  final ChartStyle style;

  /// Optional externally supplied current price.
  ///
  /// If null, the engine’s latest candle close is used.
  final double? currentPrice;

  /// Enable or disable all gesture interactions.
  ///
  /// When false:
  /// - Panning
  /// - Zooming
  /// - Double-tap reset
  /// are disabled.
  final bool enableGestures;

  /// Callback whenever the chart engine updates its viewport.
  ///
  /// Useful for:
  /// - Syncing multiple charts
  /// - Observing zoom / pan changes
  ///
  /// IMPORTANT:
  /// onViewportChanged is OBSERVATIONAL only.
  ///
  /// Do NOT call engine.pan / engine.zoom / engine.withViewport
  /// inside this callback.
  ///
  /// ChartViewport is immutable and safe to use for calculations.
  final void Function(ChartEngine)? onViewportChanged;

  /// Initial number of candles visible on first render.
  ///
  /// Defaults to engine-defined value (usually 100).
  final int? defaultVisibleCount;

  /// Callback when crosshair hovers over a candle.
  ///
  /// - Called with a [Candle] when crosshair is over valid data
  /// - Called with `null` when crosshair is released
  final void Function(Candle? candle)? onCrosshairChanged;

  /// Enable haptic feedback when new candle data is plotted.
  ///
  /// Triggered when:
  /// - A new candle is added
  /// - Existing candle data is updated (live updates)
  final bool plotFeedback;

  /// Enable haptic feedback when crosshair moves between candles.
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

  // ─────────────────────────────────────────────────────────
  // 🏭 FACTORY CONSTRUCTORS
  // ─────────────────────────────────────────────────────────

  /// Minimal chart preset.
  ///
  /// - No grid
  /// - No labels
  /// - Line-only rendering
  ///
  /// Ideal for:
  /// - Small embeds
  /// - Sparkline-style charts
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

  /// Simple chart preset.
  ///
  /// - Line chart
  /// - Basic labels
  /// - No grid or animations
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

  /// Full-featured trading chart preset.
  ///
  /// Enables:
  /// - Crosshair
  /// - Ripple animation
  /// - Gestures
  /// - Live update feedback
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
        showCrosshair: showCrosshair,
      ),
    );
  }

  /// Compact chart preset.
  ///
  /// Optimized for:
  /// - Dashboards
  /// - Small screens
  /// - Dense layouts
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

/// ─────────────────────────────────────────────────────────
/// 🔧 Internal widget state
/// ─────────────────────────────────────────────────────────
///
/// Manages:
/// - Engine lifecycle
/// - Gesture handling
/// - Animation state
/// - Crosshair tracking
class _ImpChartState extends State<ImpChart>
    with SingleTickerProviderStateMixin {
  // ─────────────────────────────────────────────────────────────
  // 🔧 Internal state fields
  // ─────────────────────────────────────────────────────────────
  //
  // These fields are intentionally kept private to the widget state.
  // They coordinate engine state, gesture handling, and animations.
  //
  // IMPORTANT FOR CONTRIBUTORS:
  // - Do NOT mutate engine state directly
  // - Always replace the engine immutably via _updateEngine()
  late ChartEngine _engine;

  /// Controls the live-update ripple animation.
  ///
  /// This animation does NOT drive time itself.
  /// It only exposes a [0.0 → 1.0] progress value used by the painter.
  late AnimationController _pulseController;

  /// Periodic timer responsible for restarting the ripple animation
  /// at fixed intervals (continuous ripple cycle).
  ///
  /// The animation itself is driven by [_pulseController],
  /// this timer only schedules when it should start again.
  Timer? _rippleTimer;

  /// Current progress of the ripple animation (0.0 → 1.0).
  ///
  /// This value is passed directly into [ChartPainter] to render
  /// the pulse/ripple effect.
  double _pulseProgress = 0.0;

  /// Base scale used to differentiate zoom vs pan gestures.
  ///
  /// Flutter’s ScaleGesture mixes scale + translation.
  /// This value helps detect whether the user is actually zooming.
  double _baseScale = 1.0;

  /// Last pointer position used for pan gesture tracking.
  Offset? _lastPanPosition;

  /// Accumulates small pan deltas so we don’t pan on every tiny movement.
  ///
  /// Viewport only updates when accumulated delta crosses
  /// at least one candle width.
  double _accumulatedPanDelta = 0.0;

  /// Current crosshair position in local widget coordinates.
  Offset? _crosshairPosition;

  /// Index of the candle currently under the crosshair.
  ///
  /// IMPORTANT:
  /// This is the index within *visible candles*, not the full dataset.
  int? _crosshairIndex;

  @override
  void initState() {
    super.initState();

    // ─────────────────────────────────────────────────────────
    // Engine initialization
    // ─────────────────────────────────────────────────────────
    //
    // The engine owns:
    // - viewport
    // - scaling
    // - visible candle computation
    //
    // The widget NEVER mutates engine internals directly.
    _engine = ChartEngine(
      candles: widget.candles,
      defaultVisibleCount: widget.defaultVisibleCount,
    );

    // ─────────────────────────────────────────────────────────
    // Ripple / pulse animation setup
    // ─────────────────────────────────────────────────────────
    //
    // The ripple animation is used to visually highlight
    // live data updates (new candle or updated candle).
    //
    // Duration is configurable via style.
    final rippleStyle = widget.style.rippleStyle;
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: rippleStyle.animationDurationMs),
    );

    // Listener simply maps animation value → repaint trigger
    _pulseController.addListener(_pulseListener);

    // Start continuous ripple cycle AFTER first frame
    //
    // Why post-frame?
    // - Avoids starting animation before layout exists
    // - Prevents unnecessary early rebuilds
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

    // ─────────────────────────────────────────────────────────
    // 🔁 Detect candle data changes
    // ─────────────────────────────────────────────────────────
    //
    // We must handle multiple scenarios:
    // 1. Entire candle list replaced
    // 2. New candle appended
    // 3. Last candle updated (live data)
    // 4. Timeframe/range change (completely new dataset)
    //
    // IMPORTANT:
    // We cannot rely only on list reference equality because
    // some apps mutate candle lists in place.

    final candlesChanged = widget.candles != oldWidget.candles;
    final candleCountChanged =
        widget.candles.length != oldWidget.candles.length;

    // Detect last-candle mutation (live update)
    bool lastCandleChanged = false;
    if (!candleCountChanged &&
        widget.candles.isNotEmpty &&
        oldWidget.candles.isNotEmpty &&
        _engine.candles.isNotEmpty) {
      final currentLastCandle = widget.candles.last;
      final engineLastCandle = _engine.candles.last;

      // Compare OHLC values to detect live updates
      lastCandleChanged = currentLastCandle.close != engineLastCandle.close ||
          currentLastCandle.high != engineLastCandle.high ||
          currentLastCandle.low != engineLastCandle.low ||
          currentLastCandle.open != engineLastCandle.open;
    }

    if (candlesChanged || lastCandleChanged) {
      final oldCandleCount = oldWidget.candles.length;
      final newCandleCount = widget.candles.length;
      final oldEndIndex = _engine.viewport.endIndex;

      // Determine whether user was viewing the most recent candles
      //
      // We allow a small buffer (last 3 candles) to avoid jitter
      // when new data arrives rapidly.
      final wasNearEnd = oldEndIndex >= (oldCandleCount - 3);

      // Detect full data replacement (e.g. timeframe switch)
      final isDataReplacement = oldCandleCount == 0 && newCandleCount > 0;

      // Detect completely new dataset by comparing first candle
      bool isCompletelyNewData = false;
      if (oldCandleCount > 0 && newCandleCount > 0) {
        isCompletelyNewData =
            widget.candles.first.time != oldWidget.candles.first.time;
      }

      // Update engine with new candle list
      var newEngine = _engine.withCandles(
        widget.candles,
        defaultVisibleCount: widget.defaultVisibleCount,
      );

      // ─────────────────────────────────────────────────────
      // CASE 1: New dataset → reset viewport
      // ─────────────────────────────────────────────────────
      if (isDataReplacement || isCompletelyNewData) {
        final targetVisibleCount = widget.defaultVisibleCount ?? 100;
        newEngine = newEngine.withViewport(
          ChartViewport.last(
            targetVisibleCount.clamp(1, newCandleCount),
            newCandleCount,
          ),
        );
        _updateEngine(newEngine);
      }

      // ─────────────────────────────────────────────────────
      // CASE 2: New candle appended
      // ─────────────────────────────────────────────────────
      else if (newCandleCount > oldCandleCount) {
        _triggerPulse();

        if (widget.plotFeedback) {
          HapticFeedback.lightImpact();
        }

        // Auto-scroll only if user was near end
        if (wasNearEnd) {
          final targetVisibleCount = widget.defaultVisibleCount ?? 100;
          final currentVisibleCount = _engine.viewport.visibleCount;
          final visibleCount = math.max(
            currentVisibleCount,
            math.min(targetVisibleCount, newCandleCount),
          );

          newEngine = newEngine.withViewport(
            ChartViewport.last(visibleCount, newCandleCount),
          );
        }
        _updateEngine(newEngine);
      }

      // ─────────────────────────────────────────────────────
      // CASE 3: Live update (same candle count)
      // ─────────────────────────────────────────────────────
      else if (newCandleCount == oldCandleCount &&
          (candlesChanged || lastCandleChanged)) {
        if (wasNearEnd) {
          newEngine = newEngine.withViewport(
            ChartViewport.last(
              _engine.viewport.visibleCount,
              newCandleCount,
            ),
          );

          if (widget.style.rippleStyle.show) {
            _triggerPulse();
          }

          if (widget.plotFeedback) {
            HapticFeedback.lightImpact();
          }
        } else {
          // Trigger ripple only if last candle is visible
          if (oldEndIndex >= oldCandleCount && widget.style.rippleStyle.show) {
            _triggerPulse();

            if (widget.plotFeedback) {
              HapticFeedback.lightImpact();
            }
          }
        }
        _updateEngine(newEngine);
      }

      // ─────────────────────────────────────────────────────
      // CASE 4: Candle count decreased (rare / defensive)
      // ─────────────────────────────────────────────────────
      else {
        _updateEngine(newEngine);
      }
    }

    // ─────────────────────────────────────────────────────────
    // Ripple enable / disable transitions
    // ─────────────────────────────────────────────────────────
    //
    // We only start/stop the ripple cycle when the ENABLED STATE changes.
    final rippleEnabled =
        widget.style.rippleStyle.show && widget.candles.isNotEmpty;
    final wasRippleEnabled =
        oldWidget.style.rippleStyle.show && oldWidget.candles.isNotEmpty;

    if (rippleEnabled && !wasRippleEnabled) {
      _startContinuousRipple();
    } else if (!rippleEnabled && wasRippleEnabled) {
      _stopContinuousRipple();
    }
  }

  /// Animation listener that maps controller value → repaint.
  ///
  /// NOTE:
  /// We intentionally use setState here because the painter
  /// depends on [_pulseProgress].
  void _pulseListener() {
    if (mounted) {
      setState(() {
        _pulseProgress = _pulseController.value;
      });
    }
  }

  @override
  void dispose() {
    // Clean up timers and animations explicitly
    _rippleTimer?.cancel();
    _rippleTimer = null;

    _pulseController.stop();
    _pulseController.removeListener(_pulseListener);
    _pulseController.dispose();

    super.dispose();
  }

  /// Start continuous ripple animation cycle.
  ///
  /// The cycle is:
  /// [animationDurationMs] → [intervalMs] → repeat
  ///
  /// This design:
  /// - Avoids overlapping animations
  /// - Keeps ripple periodic and predictable
  void _startContinuousRipple() {
    final rippleStyle = widget.style.rippleStyle;

    if (!mounted || widget.candles.isEmpty || !rippleStyle.show) {
      return;
    }

    _rippleTimer?.cancel();

    _pulseController.duration =
        Duration(milliseconds: rippleStyle.animationDurationMs);

    _playRippleAnimation();

    final totalCycleMs =
        rippleStyle.animationDurationMs + rippleStyle.intervalMs;

    _rippleTimer = Timer.periodic(
      Duration(milliseconds: totalCycleMs),
      (timer) {
        // CRITICAL FIX: Cancel timer if conditions become invalid
        // This prevents memory leaks and unnecessary processing
        if (!mounted ||
            widget.candles.isEmpty ||
            !widget.style.rippleStyle.show) {
          timer.cancel();
          return;
        }
        _playRippleAnimation();
      },
    );
  }

  /// Stop the ripple animation and reset progress.
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

  /// Play a single ripple animation instance.
  void _playRippleAnimation() {
    if (!mounted || !widget.style.rippleStyle.show || widget.candles.isEmpty) {
      return;
    }

    _pulseController.reset();
    _pulseController.forward();
  }

  /// Trigger ripple animation when new data arrives.
  ///
  /// This method exists mainly for backward compatibility
  /// and to ensure ripple always runs in continuous mode.
  void _triggerPulse() {
    if (!mounted || !widget.style.rippleStyle.show || widget.candles.isEmpty) {
      return;
    }

    if (_rippleTimer == null || !_rippleTimer!.isActive) {
      _startContinuousRipple();
    }
  }

  /// Replace the current chart engine instance and notify listeners.
  ///
  /// IMPORTANT INVARIANT:
  /// - The engine must be treated as IMMUTABLE
  /// - Always replace it as a whole
  /// - Never mutate engine fields directly
  ///
  /// This ensures:
  /// - Predictable rebuilds
  /// - Correct painter invalidation
  /// - Safe future refactors
  void _updateEngine(ChartEngine newEngine) {
    setState(() {
      _engine = newEngine;
    });

    // Expose viewport changes for external synchronization
    widget.onViewportChanged?.call(newEngine);
  }

  /// Handle the beginning of a scale gesture.
  ///
  /// This resets all gesture-tracking state so that
  /// pan vs zoom can be detected reliably.
  void _handleScaleStart(ScaleStartDetails details, Size size) {
    // Reset base scale so we can detect actual zoom intent
    _baseScale = 1.0;

    // Track initial focal point for pan calculations
    _lastPanPosition = details.focalPoint;

    // Reset accumulated pan delta for smooth panning
    _accumulatedPanDelta = 0.0;
  }

  /// Handle scale gesture updates.
  ///
  /// Flutter merges pan + zoom into a single ScaleGesture.
  /// This method disambiguates intent by:
  /// - Detecting significant scale change → ZOOM
  /// - Otherwise → PAN
  ///
  /// IMPORTANT:
  /// - Zoom and pan must NEVER be applied simultaneously
  /// - Crosshair mode disables gestures entirely
  void _handleScaleUpdate(ScaleUpdateDetails details, Size size) {
    if (!widget.enableGestures || widget.style.crosshairStyle.show) return;

    // Measure how much scale has changed relative to baseline
    final scaleChange = (details.scale - _baseScale).abs();

    // Threshold prevents accidental zoom when user is panning
    final isZoom = scaleChange > 0.05;

    if (isZoom) {
      // ─────────────────────────────────────────────
      // 🔍 ZOOM HANDLING
      // ─────────────────────────────────────────────
      //
      // Zoom direction:
      // - Fingers apart (scale ↑) → zoom IN → fewer candles
      // - Fingers together (scale ↓) → zoom OUT → more candles
      //
      // Note: zoomDelta is inverted to match chart convention
      final zoomDelta = (details.scale - _baseScale) > 0 ? -1 : 1;

      // Convert focal point into candle index so we can
      // zoom AROUND the user’s touch position
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

      // Anchor-based zoom keeps the candle under the finger stable
      if (anchorIndex >= 0 && anchorIndex < _engine.candles.length) {
        _updateEngine(_engine.zoomAround(anchorIndex, zoomDelta));
      } else {
        // Fallback to center-based zoom
        _updateEngine(_engine.zoom(zoomDelta));
      }

      // Reset baseline for next scale delta
      _baseScale = details.scale;
      _lastPanPosition = details.focalPoint;
      _accumulatedPanDelta = 0.0;
    }
    // ─────────────────────────────────────────────
    // ✋ PAN HANDLING
    // ─────────────────────────────────────────────
    else if (_lastPanPosition != null && !widget.style.crosshairStyle.show) {
      // Calculate horizontal movement
      //
      // Inverted so:
      // - Drag right → scroll right → view earlier candles
      final delta = _lastPanPosition!.dx - details.focalPoint.dx;
      _accumulatedPanDelta += delta;

      final candleWidth = _getCandleWidth(size);

      // Accumulate small deltas to avoid jitter.
      // Only pan when movement exceeds 1 candle width.
      if (candleWidth > 0) {
        final candleDelta = (_accumulatedPanDelta / candleWidth).round();

        if (candleDelta.abs() >= 1) {
          _updateEngine(_engine.pan(candleDelta));

          // Preserve remainder for smooth continuous pan
          _accumulatedPanDelta =
              _accumulatedPanDelta - (candleDelta * candleWidth);
        }
      }

      _lastPanPosition = details.focalPoint;
    }
  }

  /// Handle double-tap gesture.
  ///
  /// Behavior:
  /// - Resets viewport to last N candles
  /// - Keeps engine state consistent
  ///
  /// Common UX pattern in trading charts.
  void _handleDoubleTap() {
    if (!widget.enableGestures || widget.style.crosshairStyle.show) return;

    _updateEngine(
      _engine.resetViewport(
        visibleCount: widget.defaultVisibleCount ?? 100,
      ),
    );
  }

  /// Start crosshair interaction.
  ///
  /// Crosshair is activated via long-press to avoid
  /// conflict with pan/zoom gestures.
  void _handleLongPressStart(LongPressStartDetails details, Size size) {
    if (!widget.enableGestures || !widget.style.crosshairStyle.show) return;
    _updateCrosshair(details.localPosition, size);
  }

  /// Update crosshair position while finger moves.
  void _handleLongPressMoveUpdate(
      LongPressMoveUpdateDetails details, Size size) {
    if (!widget.enableGestures || !widget.style.crosshairStyle.show) return;
    _updateCrosshair(details.localPosition, size);
  }

  /// End crosshair interaction.
  ///
  /// Clears crosshair state and notifies listeners.
  void _handleLongPressEnd() {
    setState(() {
      _crosshairPosition = null;
      _crosshairIndex = null;
    });

    widget.onCrosshairChanged?.call(null);
  }

  /// Update crosshair state based on touch position.
  ///
  /// Converts:
  /// local pixel position → candle index → visible candle
  ///
  /// IMPORTANT:
  /// - absoluteIndex refers to full dataset
  /// - relativeIndex refers to visible candles only
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

    // Absolute index in full candle list
    final absoluteIndex = mapper.xToIndex(localPosition.dx);

    if (absoluteIndex >= 0 && absoluteIndex < _engine.candles.length) {
      final visibleCandles = _engine.getVisibleCandles();
      final relativeIndex = absoluteIndex - mapper.viewport.startIndex;

      if (relativeIndex >= 0 && relativeIndex < visibleCandles.length) {
        final candle = visibleCandles[relativeIndex];

        // Prevent redundant callbacks for same candle
        final indexChanged = _crosshairIndex != relativeIndex;

        setState(() {
          _crosshairPosition = localPosition;
          _crosshairIndex = relativeIndex;
        });

        if (indexChanged) {
          widget.onCrosshairChanged?.call(candle);

          if (widget.crosshairChangeFeedback) {
            HapticFeedback.lightImpact();
          }
        }
      }
    }
  }

  /// Calculate candle width in pixels for the current viewport.
  ///
  /// Used for:
  /// - Pan delta normalization
  /// - Gesture smoothing
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

  /// Calculate dynamic padding for the chart based on:
  /// - Visible labels
  /// - Font sizes
  /// - Axis configuration
  ///
  /// This method determines how much space is RESERVED for:
  /// - Y-axis price labels (right side)
  /// - X-axis time labels (bottom)
  ///
  /// IMPORTANT DESIGN GOALS:
  /// - Never overlap chart data with labels
  /// - Avoid hard-coded axis sizes
  /// - Adapt automatically to font / formatter changes
  ///
  /// PERFORMANCE NOTE:
  /// This method is called during layout.
  /// Keep it deterministic and avoid allocations beyond TextPainter.
  _PaddingInfo _calculatePadding(Size size) {
    // ─────────────────────────────────────────────────────────
    // Layout configuration
    // ─────────────────────────────────────────────────────────
    //
    // Layout is a pure configuration object.
    // It contains spacing, gaps, and padding defaults.
    final layout = widget.style.layout;

    // Chart data padding that is ALWAYS applied
    // (left & top are fixed, right & bottom are dynamic)
    final chartDataLeft = layout.chartDataPadding.left;
    final chartDataTop = layout.chartDataPadding.top;

    // ─────────────────────────────────────────────────────────
    // Y-Axis (price labels) width calculation
    // ─────────────────────────────────────────────────────────
    double yAxisAreaWidth = 0.0;
    final priceLabelStyle = widget.style.priceLabelStyle;

    if (priceLabelStyle.show && _engine.candles.isNotEmpty) {
      // Price scale defines min/max visible prices
      final scale = _engine.getPriceScale();
      final labelFontSize = priceLabelStyle.fontSize;
      final formatter = priceLabelStyle.formatter;

      // Reuse TextPainter to measure text width
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
      );

      double maxLabelWidth = 0.0;

      // Measure ALL price labels to find the widest one
      //
      // We sample evenly across the price range
      // to avoid missing large formatted values.
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

      // ─────────────────────────────────────────────────────
      // Current price label handling (TradingView-style)
      // ─────────────────────────────────────────────────────
      //
      // IMPORTANT DESIGN DECISION:
      // The current price label lives in the SAME column
      // as Y-axis labels — just styled differently.
      //
      // This avoids layout jitter and wasted space.
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

          // Account for horizontal padding inside the label
          currentPriceLabelWidth =
              textPainter.width + (currentPriceStyle.labelPaddingH * 2);
        }
      }

      // Final Y-axis width:
      // gap + widest label + label padding
      final yAxisLabelPadding = layout.yAxisLabelPadding;
      final effectiveLabelWidth =
          math.max(maxLabelWidth, currentPriceLabelWidth);

      yAxisAreaWidth =
          layout.yAxisGap + effectiveLabelWidth + yAxisLabelPadding.horizontal;
    }

    // ─────────────────────────────────────────────────────────
    // X-Axis (time labels) height calculation
    // ─────────────────────────────────────────────────────────
    double xAxisAreaHeight = 0.0;
    final timeLabelStyle = widget.style.timeLabelStyle;

    if (timeLabelStyle.show && _engine.candles.isNotEmpty) {
      final labelFontSize = timeLabelStyle.fontSize;

      // Measure a representative time label
      //
      // Exact value does not matter as long as
      // it matches formatter’s typical output height.
      final textPainter = TextPainter(
        text: TextSpan(
          text: '00:00',
          style: TextStyle(fontSize: labelFontSize),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // X-axis height:
      // gap + text height + padding
      final xAxisLabelPadding = layout.xAxisLabelPadding;
      xAxisAreaHeight =
          layout.xAxisGap + textPainter.height + xAxisLabelPadding.vertical;
    }

    // ─────────────────────────────────────────────────────────
    // Final padding result
    // ─────────────────────────────────────────────────────────
    //
    // If axis labels are hidden, fallback to default padding.
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
    // RepaintBoundary isolates chart repaint from parent widgets
    //
    // CRITICAL for performance when data updates frequently.
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);

          // Padding must be recalculated whenever size changes
          final padding = _calculatePadding(size);

          return GestureDetector(
            // Gesture routing is DISABLED when crosshair is active
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
              // ChartPainter is PURELY responsible for drawing.
              //
              // It must remain stateless and deterministic.
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

/// Immutable value object representing resolved chart padding.
///
/// This class encapsulates the final padding values used by:
/// - Coordinate mapping
/// - Painter layout
/// - Gesture → candle index conversion
///
/// WHY THIS EXISTS:
/// - Keeps padding logic explicit and readable
/// - Avoids passing raw EdgeInsets everywhere
/// - Prevents accidental mutation of layout values
///
/// IMPORTANT INVARIANTS:
/// - All values are logical pixels
/// - Values are already FINAL (no further computation expected)
/// - Left & Top typically come from chartDataPadding
/// - Right & Bottom are often dynamically calculated
///
/// INTERNAL USE ONLY:
/// This is not exposed publicly because:
/// - It is tightly coupled to the rendering pipeline
/// - Its shape may evolve as layout logic grows
class _PaddingInfo {
  /// Space reserved on the left side of the chart.
  ///
  /// Usually fixed and defined by chartDataPadding.
  final double left;

  /// Space reserved on the right side of the chart.
  ///
  /// Typically used for Y-axis price labels.
  /// May be zero if price labels are hidden.
  final double right;

  /// Space reserved at the top of the chart.
  ///
  /// Often used for top padding or overlays.
  final double top;

  /// Space reserved at the bottom of the chart.
  ///
  /// Typically used for X-axis time labels.
  /// May be zero if time labels are hidden.
  final double bottom;

  const _PaddingInfo({
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  });
}
