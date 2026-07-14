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
class ImpChart extends StatefulWidget {
  final List<Candle> candles;
  final ChartStyle style;
  final double? currentPrice;
  final bool enableGestures;
  final void Function(ChartEngine)? onViewportChanged;
  final void Function(ChartViewportSnapshot viewport)?
      onViewportSnapshotChanged;
  final void Function(ChartRenderSnapshot snapshot)? onChartStateChanged;
  final void Function(ChartEvent event)? onChartEvent;
  final int? defaultVisibleCount;
  final void Function(Candle? candle)? onCrosshairChanged;
  final bool plotFeedback;
  final bool crosshairChangeFeedback;
  final ImpChartController? controller;

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
      _controller.setCandles(widget.candles);
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
    } else {
      widget.controller!.setCandles(widget.candles);
    }

    _bindController(_controller);
  }

  void _bindController(ImpChartController controller) {
    controller.addListener(_handleControllerChanged);
    _eventSubscription = controller.events.listen((event) {
      _handleChartEvent(event);
      widget.onChartEvent?.call(event);
    });
    _handleControllerChanged();
  }

  void _unbindController(ImpChartController? controller) {
    controller?.removeListener(_handleControllerChanged);
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  void _handlePulseTick() {
    if (!mounted) return;
    setState(() {
      _pulseProgress = _pulseCoordinator.progress;
    });
  }

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

  void _handleScaleStart(ScaleStartDetails details, Size size) {
    _gestureSession.start(details.focalPoint);
  }

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

  void _handleDoubleTap() {
    if (!widget.enableGestures || widget.style.crosshairStyle.show) return;
    _controller.resetViewport();
  }

  void _handleLongPressStart(LongPressStartDetails details, Size size) {
    if (!widget.enableGestures || !widget.style.crosshairStyle.show) return;
    _updateCrosshair(details.localPosition, size);
  }

  void _handleLongPressMoveUpdate(
    LongPressMoveUpdateDetails details,
    Size size,
  ) {
    if (!widget.enableGestures || !widget.style.crosshairStyle.show) return;
    _updateCrosshair(details.localPosition, size);
  }

  void _handleLongPressEnd() {
    _controller.hideCrosshair();
    setState(() {
      _crosshairPosition = null;
      _crosshairIndex = null;
    });
  }

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

  void _syncPulseState() {
    _pulseCoordinator.sync(
      style: widget.style.rippleStyle,
      enabled: widget.style.rippleStyle.show,
      hasCandles: widget.candles.isNotEmpty,
    );
  }

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
