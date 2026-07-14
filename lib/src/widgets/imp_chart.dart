import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart';
import 'package:imp_trading_chart/src/engine/chart_engine.dart'
    show ChartEngine;
import 'package:imp_trading_chart/src/layout/padding_resolver.dart';
import 'package:imp_trading_chart/src/math/coordinate_mapper.dart';
import 'package:imp_trading_chart/src/rendering/chart_painter.dart'
    show ChartPainter;
import 'package:imp_trading_chart/src/widgets/chart_gesture_session.dart';
import 'package:imp_trading_chart/src/widgets/chart_live_update_indicator.dart';
import 'package:imp_trading_chart/src/widgets/chart_pulse_coordinator.dart';

/// High-performance Flutter widget that renders a trading chart
/// using a CustomPainter-driven rendering engine.
///
/// Public design goals:
/// - keep widget usage simple for package consumers
/// - preserve compatibility with existing `candles:`-driven integrations
/// - support advanced orchestration through an optional controller
///
/// Runtime responsibilities:
/// - bind Flutter lifecycle to chart controller state
/// - translate gestures into controller commands
/// - compose the paint surface and widget-only overlays
/// - forward legacy callbacks alongside newer snapshot/event APIs
class ImpChart extends StatefulWidget {
  /// Candle dataset rendered by the chart.
  final List<Candle> candles;

  /// Visual configuration for chart rendering.
  final ChartStyle style;

  /// Optional explicit current price override.
  final double? currentPrice;

  /// Whether user gesture interactions are enabled.
  final bool enableGestures;

  /// Legacy engine callback preserved for backward compatibility.
  final void Function(ChartEngine)? onViewportChanged;

  /// Snapshot callback for viewport-only observation.
  final void Function(ChartViewportSnapshot viewport)?
      onViewportSnapshotChanged;

  /// Snapshot callback for the full controller-visible render state.
  final void Function(ChartRenderSnapshot snapshot)? onChartStateChanged;

  /// Semantic event callback for resets, live updates, and other chart events.
  final void Function(ChartEvent event)? onChartEvent;

  /// Optional default visible count used by internally managed controllers.
  final int? defaultVisibleCount;

  /// Callback fired when the selected crosshair candle changes.
  final void Function(Candle? candle)? onCrosshairChanged;

  /// Whether live data feedback may trigger light haptics.
  final bool plotFeedback;

  /// Whether crosshair selection changes may trigger light haptics.
  final bool crosshairChangeFeedback;

  /// Optional external controller. If omitted, the widget manages an internal
  /// controller automatically.
  final ImpChartController? controller;

  /// Creates a configurable chart widget with optional controller injection.
  ImpChart({
    super.key,
    required this.candles,
    ChartStyle? style,
    this.currentPrice,
    this.enableGestures = true,
    this.onViewportChanged,
    this.onViewportSnapshotChanged,
    this.onChartStateChanged,
    this.onChartEvent,
    this.defaultVisibleCount,
    this.onCrosshairChanged,
    this.plotFeedback = false,
    this.crosshairChangeFeedback = false,
    this.controller,
  }) : style = style ?? ChartStyle();

  @override
  State<ImpChart> createState() => _ImpChartState();

  /// Minimal sparkline-style preset with gestures disabled by default.
  factory ImpChart.minimal({
    required List<Candle> candles,
    Color? lineColor,
    double? lineWidth,
    bool showLineGlow = true,
    void Function(ChartEngine)? onViewportChanged,
    void Function(ChartViewportSnapshot viewport)? onViewportSnapshotChanged,
    void Function(ChartRenderSnapshot snapshot)? onChartStateChanged,
    void Function(ChartEvent event)? onChartEvent,
    void Function(Candle?)? onCrosshairChanged,
    int? defaultVisibleCount,
    bool plotFeedback = false,
    bool crosshairChangeFeedback = false,
    ImpChartController? controller,
  }) {
    return ImpChart(
      candles: candles,
      enableGestures: false,
      onViewportChanged: onViewportChanged,
      onViewportSnapshotChanged: onViewportSnapshotChanged,
      onChartStateChanged: onChartStateChanged,
      onChartEvent: onChartEvent,
      onCrosshairChanged: onCrosshairChanged,
      defaultVisibleCount: defaultVisibleCount,
      plotFeedback: plotFeedback,
      crosshairChangeFeedback: crosshairChangeFeedback,
      controller: controller,
      style: ChartStyle.minimal(
        lineColor: lineColor ?? const Color.fromRGBO(15, 173, 0, 1),
        lineWidth: lineWidth ?? 2.0,
        showLineGlow: showLineGlow,
      ),
    );
  }

  /// Lightweight line-chart preset for simple read-only chart use cases.
  factory ImpChart.simple({
    required List<Candle> candles,
    Color? lineColor,
    Color? textColor,
    Color? backgroundColor,
    double? lineWidth,
    double? currentPrice,
    bool enableGestures = true,
    void Function(ChartEngine)? onViewportChanged,
    void Function(ChartViewportSnapshot viewport)? onViewportSnapshotChanged,
    void Function(ChartRenderSnapshot snapshot)? onChartStateChanged,
    void Function(ChartEvent event)? onChartEvent,
    void Function(Candle?)? onCrosshairChanged,
    int? defaultVisibleCount,
    bool plotFeedback = false,
    bool crosshairChangeFeedback = false,
    ImpChartController? controller,
  }) {
    return ImpChart(
      candles: candles,
      currentPrice: currentPrice,
      enableGestures: enableGestures,
      onViewportChanged: onViewportChanged,
      onViewportSnapshotChanged: onViewportSnapshotChanged,
      onChartStateChanged: onChartStateChanged,
      onChartEvent: onChartEvent,
      onCrosshairChanged: onCrosshairChanged,
      defaultVisibleCount: defaultVisibleCount,
      plotFeedback: plotFeedback,
      crosshairChangeFeedback: crosshairChangeFeedback,
      controller: controller,
      style: ChartStyle.simple(
        backgroundColor: backgroundColor ?? Colors.transparent,
        textColor: textColor ?? Colors.white,
        lineColor: lineColor ?? Colors.blue,
        lineWidth: lineWidth ?? 2.0,
      ),
    );
  }

  /// Full trading-oriented preset with richer live and interaction visuals.
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
    void Function(ChartViewportSnapshot viewport)? onViewportSnapshotChanged,
    void Function(ChartRenderSnapshot snapshot)? onChartStateChanged,
    void Function(ChartEvent event)? onChartEvent,
    void Function(Candle? candle)? onCrosshairChanged,
    int? defaultVisibleCount,
    bool plotFeedback = true,
    bool crosshairChangeFeedback = true,
    ImpChartController? controller,
  }) {
    return ImpChart(
      key: key,
      candles: candles,
      currentPrice: currentPrice,
      enableGestures: enableGestures,
      onViewportChanged: onViewportChanged,
      onViewportSnapshotChanged: onViewportSnapshotChanged,
      onChartStateChanged: onChartStateChanged,
      onChartEvent: onChartEvent,
      onCrosshairChanged: onCrosshairChanged,
      defaultVisibleCount: defaultVisibleCount,
      plotFeedback: plotFeedback,
      crosshairChangeFeedback: crosshairChangeFeedback,
      controller: controller,
      style: ChartStyle.trading(
        backgroundColor: backgroundColor ?? Colors.transparent,
        lineColor: lineColor ?? const Color(0xFF78D99B),
        pulseColor: pulseColor ?? lineColor ?? const Color(0xFF78D99B),
        showCrosshair: showCrosshair,
      ),
    );
  }

  /// Dashboard-friendly preset balancing compactness and readability.
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
    void Function(ChartViewportSnapshot viewport)? onViewportSnapshotChanged,
    void Function(ChartRenderSnapshot snapshot)? onChartStateChanged,
    void Function(ChartEvent event)? onChartEvent,
    void Function(Candle?)? onCrosshairChanged,
    int? defaultVisibleCount,
    bool plotFeedback = false,
    bool crosshairChangeFeedback = false,
    ImpChartController? controller,
  }) {
    return ImpChart(
      candles: candles,
      currentPrice: currentPrice,
      enableGestures: enableGestures,
      onViewportChanged: onViewportChanged,
      onViewportSnapshotChanged: onViewportSnapshotChanged,
      onChartStateChanged: onChartStateChanged,
      onChartEvent: onChartEvent,
      onCrosshairChanged: onCrosshairChanged,
      defaultVisibleCount: defaultVisibleCount,
      plotFeedback: plotFeedback,
      crosshairChangeFeedback: crosshairChangeFeedback,
      controller: controller,
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

/// Private Flutter binding state for [ImpChart].
///
/// This state object intentionally owns only widget-facing concerns:
/// - controller binding/lifecycle
/// - widget-only animation progress
/// - crosshair overlay position
/// - detached-live indicator visibility
class _ImpChartState extends State<ImpChart>
    with SingleTickerProviderStateMixin {
  final PaddingResolver _paddingResolver = const PaddingResolver();
  final ChartGestureSession _gestureSession = ChartGestureSession();

  late final ChartPulseCoordinator _pulseCoordinator;
  ImpChartController? _internalController;
  StreamSubscription<ChartEvent>? _eventSubscription;

  double _pulseProgress = 0.0;
  Offset? _crosshairPosition;
  int? _crosshairIndex;
  Candle? _lastCrosshairCandle;
  bool _hasPendingLatestData = false;
  int _pendingLatestCandleCount = 0;
  int? _lastKnownCandleCount;
  int? _lastKnownFirstCandleTime;
  bool _externalSyncScheduled = false;

  ImpChartController get _controller =>
      widget.controller ?? _internalController!;

  ChartEngine get _engine => _controller.engine;

  @override
  void initState() {
    super.initState();
    _ensureController();
    _pulseCoordinator = ChartPulseCoordinator(
      vsync: this,
      onProgressChanged: _handlePulseTick,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncPulseState();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ImpChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      _unbindController(oldWidget.controller ?? _internalController);
      if (oldWidget.controller == null) {
        _internalController?.dispose();
        _internalController = null;
      }
      _ensureController();
    }

    if (_didCandlesChange(oldWidget)) {
      _syncControllerCandles();
    }

    _syncPulseState();
  }

  @override
  void dispose() {
    _unbindController(widget.controller ?? _internalController);
    _internalController?.dispose();
    _pulseCoordinator.dispose();
    super.dispose();
  }

  void _ensureController() {
    if (widget.controller == null) {
      _internalController = ImpChartController(
        candles: widget.candles,
        defaultVisibleCount: widget.defaultVisibleCount ?? 100,
      );
    } else if (_shouldSyncExternalController(widget.controller!)) {
      _scheduleExternalControllerSync(widget.controller!);
    }

    _bindController(_controller);
  }

  /// Subscribes widget listeners to the active controller instance.
  void _bindController(ImpChartController controller) {
    controller.addListener(_handleControllerChanged);
    _eventSubscription = controller.events.listen((event) {
      _handleChartEvent(event);
      widget.onChartEvent?.call(event);
    });
    _handleControllerChanged();
  }

  /// Removes widget listeners from the previously active controller instance.
  void _unbindController(ImpChartController? controller) {
    controller?.removeListener(_handleControllerChanged);
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  /// Mirrors pulse animation progress into widget state for repainting.
  void _handlePulseTick() {
    if (!mounted) return;
    setState(() {
      _pulseProgress = _pulseCoordinator.progress;
    });
  }

  /// Responds to controller state changes and forwards public callbacks.
  void _handleControllerChanged() {
    if (!mounted) return;

    final selection = _controller.selection;
    final candle = selection?.candle;
    final visibleIndex = selection?.visibleIndex;
    final candleChanged = candle != _lastCrosshairCandle;
    final currentCandles = _controller.candles;
    final currentCount = currentCandles.length;
    final currentFirstTime =
        currentCandles.isEmpty ? null : currentCandles.first.time;
    final seriesChanged = _lastKnownFirstCandleTime != null &&
        currentFirstTime != null &&
        _lastKnownFirstCandleTime != currentFirstTime;
    final addedCandles = _lastKnownCandleCount == null || seriesChanged
        ? 0
        : currentCount - _lastKnownCandleCount!;

    if (candleChanged) {
      widget.onCrosshairChanged?.call(candle);
      if (candle != null && widget.crosshairChangeFeedback) {
        HapticFeedback.lightImpact();
      }
    }

    setState(() {
      _lastCrosshairCandle = candle;
      _crosshairIndex = visibleIndex;
      if (_controller.isFollowingLatest || seriesChanged) {
        _hasPendingLatestData = false;
        _pendingLatestCandleCount = 0;
      } else if (addedCandles > 0) {
        _hasPendingLatestData = true;
        _pendingLatestCandleCount += addedCandles;
      }
      if (selection == null) {
        _crosshairPosition = null;
      }
      _lastKnownCandleCount = currentCount;
      _lastKnownFirstCandleTime = currentFirstTime;
    });

    widget.onViewportChanged?.call(_engine);
    widget.onViewportSnapshotChanged?.call(_controller.viewport);
    widget.onChartStateChanged?.call(_controller.snapshot);
  }

  /// Detects meaningful candle input changes, including in-place list mutation.
  bool _didCandlesChange(ImpChart oldWidget) {
    final previousCandles = _controller.candles;
    final currentCandles = widget.candles;

    if (currentCandles.length != previousCandles.length) {
      return true;
    }

    if (currentCandles.isEmpty && previousCandles.isEmpty) {
      return false;
    }

    if (currentCandles.isEmpty || previousCandles.isEmpty) {
      return true;
    }

    if (currentCandles.first != previousCandles.first) {
      return true;
    }

    if (currentCandles.last != previousCandles.last) {
      return true;
    }

    if (oldWidget.defaultVisibleCount != widget.defaultVisibleCount) {
      return true;
    }

    return false;
  }

  /// Returns `true` when the external controller needs to be synchronized with
  /// the current widget candle input.
  bool _shouldSyncExternalController(ImpChartController controller) {
    final previousCandles = controller.candles;
    final currentCandles = widget.candles;

    if (identical(previousCandles, currentCandles)) {
      return false;
    }

    if (currentCandles.length != previousCandles.length) {
      return true;
    }

    if (currentCandles.isEmpty && previousCandles.isEmpty) {
      return false;
    }

    if (currentCandles.isEmpty || previousCandles.isEmpty) {
      return true;
    }

    return currentCandles.first != previousCandles.first ||
        currentCandles.last != previousCandles.last;
  }

  /// Synchronizes widget candles into the active controller.
  ///
  /// Internal controllers can be updated immediately because the widget owns
  /// their lifecycle. External controllers are synchronized after the current
  /// frame so ancestor listeners are never notified during build.
  void _syncControllerCandles() {
    if (widget.controller == null) {
      _controller.setCandles(widget.candles);
      return;
    }

    if (_shouldSyncExternalController(widget.controller!)) {
      _scheduleExternalControllerSync(widget.controller!);
    }
  }

  /// Schedules candle synchronization for an external controller after build.
  void _scheduleExternalControllerSync(ImpChartController controller) {
    if (_externalSyncScheduled) {
      return;
    }

    _externalSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _externalSyncScheduled = false;
      if (!mounted || widget.controller != controller) {
        return;
      }

      if (_shouldSyncExternalController(controller)) {
        controller.setCandles(widget.candles);
      }
    });
  }

  /// Handles semantic chart events emitted by the controller.
  void _handleChartEvent(ChartEvent event) {
    final shouldPulse = event.type == ChartEventType.liveCandleAppended ||
        event.type == ChartEventType.liveCandleUpdated;

    if (shouldPulse && widget.style.rippleStyle.show) {
      _pulseCoordinator.trigger(
        style: widget.style.rippleStyle,
        enabled: widget.style.rippleStyle.show,
        hasCandles: widget.candles.isNotEmpty,
      );
    }

    if (shouldPulse && widget.plotFeedback) {
      HapticFeedback.lightImpact();
    }

    if (event.type == ChartEventType.liveUpdatePreservedContext) {
      setState(() {
        _hasPendingLatestData = true;
      });
    }
  }

  /// Starts a new scale gesture tracking session.
  void _handleScaleStart(ScaleStartDetails details, Size size) {
    _gestureSession.start(details.focalPoint);
  }

  /// Routes the current scale update through the gesture session helper.
  void _handleScaleUpdate(ScaleUpdateDetails details, Size size) {
    if (!widget.enableGestures || widget.style.crosshairStyle.show) return;

    final mapper = _createMapper(size);
    _gestureSession.update(
      details: details,
      candleWidth: mapper.candleWidth,
      anchorIndex: mapper.xToIndex(details.focalPoint.dx),
      totalCount: _engine.candles.length,
      zoomIn: _controller.zoomIn,
      zoomOut: _controller.zoomOut,
      zoomAround: (anchorIndex, step) {
        _controller.zoomAround(anchorIndex, step: step);
      },
      panByCandles: _controller.panByCandles,
    );
  }

  /// Resets the viewport back to the controller's latest-following state.
  void _handleDoubleTap() {
    if (!widget.enableGestures || widget.style.crosshairStyle.show) return;
    _controller.resetViewport();
  }

  /// Begins crosshair tracking from a long-press gesture.
  void _handleLongPressStart(LongPressStartDetails details, Size size) {
    if (!widget.enableGestures || !widget.style.crosshairStyle.show) return;
    _updateCrosshair(details.localPosition, size);
  }

  /// Updates the active crosshair selection while the press moves.
  void _handleLongPressMoveUpdate(
    LongPressMoveUpdateDetails details,
    Size size,
  ) {
    if (!widget.enableGestures || !widget.style.crosshairStyle.show) return;
    _updateCrosshair(details.localPosition, size);
  }

  /// Clears crosshair selection when the long press ends.
  void _handleLongPressEnd() {
    _controller.hideCrosshair();
    setState(() {
      _crosshairPosition = null;
      _crosshairIndex = null;
    });
  }

  /// Resolves the candle under the current local position and updates
  /// controller selection accordingly.
  void _updateCrosshair(Offset localPosition, Size size) {
    final mapper = _createMapper(size);

    final absoluteIndex = mapper.xToIndex(localPosition.dx);
    if (absoluteIndex >= 0 && absoluteIndex < _engine.candles.length) {
      _controller.showCrosshairAtIndex(absoluteIndex);
      setState(() {
        _crosshairPosition = localPosition;
      });
    }
  }

  /// Returns the detached viewport to the latest candle position.
  void _handleLiveIndicatorTap() {
    _controller.scrollToLatest();
    if (widget.plotFeedback) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _hasPendingLatestData = false;
      _pendingLatestCandleCount = 0;
    });
  }

  /// Keeps the repeating ripple state aligned with current widget inputs.
  void _syncPulseState() {
    _pulseCoordinator.sync(
      style: widget.style.rippleStyle,
      enabled: widget.style.rippleStyle.show,
      hasCandles: widget.candles.isNotEmpty,
    );
  }

  /// Creates a coordinate mapper for the current widget size and chart padding.
  CoordinateMapper _createMapper(Size size) {
    final padding = _resolvePadding(size);
    return _engine.createMapper(
      chartWidth: size.width,
      chartHeight: size.height,
      paddingLeft: padding.left,
      paddingRight: padding.right,
      paddingTop: padding.top,
      paddingBottom: padding.bottom,
    );
  }

  /// Resolves chart padding for the current size and visible state.
  ChartPadding _resolvePadding(Size size) {
    return _paddingResolver.resolve(
      size: size,
      style: widget.style,
      engine: _engine,
      currentPrice: widget.currentPrice ?? _engine.getLatestPrice(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final mapper = _createMapper(size);

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
            child: Stack(
              children: [
                CustomPaint(
                  painter: ChartPainter(
                    candles: _engine.getVisibleCandles(),
                    mapper: mapper,
                    style: widget.style,
                    currentPrice:
                        widget.currentPrice ?? _engine.getLatestPrice(),
                    pulseProgress: _pulseProgress,
                    crosshairPosition: _crosshairPosition,
                    crosshairIndex: _crosshairIndex,
                  ),
                  size: size,
                ),
                if (_hasPendingLatestData && !_controller.isFollowingLatest)
                  ChartLiveUpdateIndicator(
                    onTap: _handleLiveIndicatorTap,
                    newCandleCount: _pendingLatestCandleCount <= 0
                        ? 1
                        : _pendingLatestCandleCount,
                    bottomInset: mapper.paddingBottom + 8,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
