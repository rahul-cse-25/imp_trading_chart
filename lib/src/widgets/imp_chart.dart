import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart';
import 'package:imp_trading_chart/src/engine/chart_engine.dart' show ChartEngine;
import 'package:imp_trading_chart/src/layout/padding_resolver.dart';
import 'package:imp_trading_chart/src/rendering/chart_painter.dart'
    show ChartPainter;

/// High-performance Flutter widget that renders a trading chart
/// using a CustomPainter-driven rendering engine.
class ImpChart extends StatefulWidget {
  final List<Candle> candles;
  final ChartStyle style;
  final double? currentPrice;
  final bool enableGestures;
  final void Function(ChartEngine)? onViewportChanged;
  final void Function(ChartViewportSnapshot viewport)? onViewportSnapshotChanged;
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
  static const double _zoomThreshold = 0.05;

  late AnimationController _pulseController;
  final PaddingResolver _paddingResolver = const PaddingResolver();

  ImpChartController? _internalController;
  StreamSubscription<ChartEvent>? _eventSubscription;
  Timer? _rippleTimer;

  double _pulseProgress = 0.0;
  double _baseScale = 1.0;
  double _accumulatedPanDelta = 0.0;
  Offset? _lastPanPosition;
  Offset? _crosshairPosition;
  int? _crosshairIndex;
  Candle? _lastCrosshairCandle;

  ImpChartController get _controller => widget.controller ?? _internalController!;
  ChartEngine get _engine => _controller.engine;

  @override
  void initState() {
    super.initState();
    _ensureController();

    final rippleStyle = widget.style.rippleStyle;
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: rippleStyle.animationDurationMs),
    )..addListener(_handlePulseTick);

    if (widget.candles.isNotEmpty && widget.style.rippleStyle.show) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startContinuousRipple();
        }
      });
    }
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
      _handleIncomingDataChange(oldWidget);
    }

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

  @override
  void dispose() {
    _unbindController(widget.controller ?? _internalController);
    _internalController?.dispose();
    _rippleTimer?.cancel();
    _pulseController
      ..removeListener(_handlePulseTick)
      ..dispose();
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
      _pulseProgress = _pulseController.value;
    });
  }

  void _handleControllerChanged() {
    if (!mounted) return;

    final selection = _controller.selection;
    final candle = selection?.candle;
    final visibleIndex = selection?.visibleIndex;
    final candleChanged = candle != _lastCrosshairCandle;

    if (candleChanged) {
      widget.onCrosshairChanged?.call(candle);
      if (candle != null && widget.crosshairChangeFeedback) {
        HapticFeedback.lightImpact();
      }
    }

    setState(() {
      _lastCrosshairCandle = candle;
      _crosshairIndex = visibleIndex;
      if (selection == null) {
        _crosshairPosition = null;
      }
    });

    widget.onViewportChanged?.call(_engine);
    widget.onViewportSnapshotChanged?.call(_controller.viewport);
    widget.onChartStateChanged?.call(_controller.snapshot);
  }

  void _handleIncomingDataChange(ImpChart oldWidget) {
    final oldLength = oldWidget.candles.length;
    final newLength = widget.candles.length;
    final countChanged = oldLength != newLength;

    final lastChanged = !countChanged &&
        oldLength > 0 &&
        widget.candles.isNotEmpty &&
        oldWidget.candles.last != widget.candles.last;

    if ((countChanged || lastChanged) && widget.style.rippleStyle.show) {
      _triggerPulse();
    }

    if ((countChanged || lastChanged) && widget.plotFeedback) {
      HapticFeedback.lightImpact();
    }
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
    _rippleTimer = Timer.periodic(Duration(milliseconds: totalCycleMs), (timer) {
      if (!mounted || widget.candles.isEmpty || !widget.style.rippleStyle.show) {
        timer.cancel();
        return;
      }
      _playRippleAnimation();
    });
  }

  void _stopContinuousRipple() {
    _rippleTimer?.cancel();
    _rippleTimer = null;
    _pulseController.stop();
    if (mounted) {
      setState(() {
        _pulseProgress = 0.0;
      });
    }
  }

  void _playRippleAnimation() {
    if (!mounted || widget.candles.isEmpty || !widget.style.rippleStyle.show) {
      return;
    }
    _pulseController
      ..reset()
      ..forward();
  }

  void _triggerPulse() {
    if (_rippleTimer == null || !_rippleTimer!.isActive) {
      _startContinuousRipple();
    }
  }

  void _handleScaleStart(ScaleStartDetails details, Size size) {
    _baseScale = 1.0;
    _lastPanPosition = details.focalPoint;
    _accumulatedPanDelta = 0.0;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details, Size size) {
    if (!widget.enableGestures || widget.style.crosshairStyle.show) return;

    final scaleChange = (details.scale - _baseScale).abs();
    final isZoom = scaleChange > _zoomThreshold;

    if (isZoom) {
      final padding = _resolvePadding(size);
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
        _controller.zoomAround(
          anchorIndex,
          step: (details.scale - _baseScale) > 0 ? -1 : 1,
        );
      } else if ((details.scale - _baseScale) > 0) {
        _controller.zoomIn();
      } else {
        _controller.zoomOut();
      }

      _baseScale = details.scale;
      _lastPanPosition = details.focalPoint;
      _accumulatedPanDelta = 0.0;
      return;
    }

    if (_lastPanPosition != null) {
      final delta = _lastPanPosition!.dx - details.focalPoint.dx;
      _accumulatedPanDelta += delta;
      final candleWidth = _getCandleWidth(size);
      if (candleWidth > 0) {
        final candleDelta = (_accumulatedPanDelta / candleWidth).round();
        if (candleDelta.abs() >= 1) {
          _controller.panByCandles(candleDelta);
          _accumulatedPanDelta -= candleDelta * candleWidth;
        }
      }
      _lastPanPosition = details.focalPoint;
    }
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
    final padding = _resolvePadding(size);
    final mapper = _engine.createMapper(
      chartWidth: size.width,
      chartHeight: size.height,
      paddingLeft: padding.left,
      paddingRight: padding.right,
      paddingTop: padding.top,
      paddingBottom: padding.bottom,
    );

    final absoluteIndex = mapper.xToIndex(localPosition.dx);
    if (absoluteIndex >= 0 && absoluteIndex < _engine.candles.length) {
      _controller.showCrosshairAtIndex(absoluteIndex);
      setState(() {
        _crosshairPosition = localPosition;
      });
    }
  }

  double _getCandleWidth(Size size) {
    final padding = _resolvePadding(size);
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
          final padding = _resolvePadding(size);

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
