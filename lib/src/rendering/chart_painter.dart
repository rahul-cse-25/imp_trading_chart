import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart'
    show Candle, ChartStyle;
import 'package:imp_trading_chart/src/math/coordinate_mapper.dart'
    show CoordinateMapper;
import 'package:imp_trading_chart/src/rendering/axis_label_renderer.dart';
import 'package:imp_trading_chart/src/rendering/crosshair_renderer.dart';
import 'package:imp_trading_chart/src/rendering/current_price_renderer.dart';
import 'package:imp_trading_chart/src/rendering/grid_renderer.dart';
import 'package:imp_trading_chart/src/rendering/line_renderer.dart';
import 'package:imp_trading_chart/src/rendering/ripple_renderer.dart';

/// Stateless orchestration shell for chart rendering delegates.
@internal
class ChartPainter extends CustomPainter {
  static const LineRenderer _lineRenderer = LineRenderer();
  static const GridRenderer _gridRenderer = GridRenderer();
  static const AxisLabelRenderer _axisLabelRenderer = AxisLabelRenderer();
  static const CurrentPriceRenderer _currentPriceRenderer =
      CurrentPriceRenderer();
  static const RippleRenderer _rippleRenderer = RippleRenderer();
  static const CrosshairRenderer _crosshairRenderer = CrosshairRenderer();

  final List<Candle> candles;
  final CoordinateMapper mapper;
  final ChartStyle style;
  final double? currentPrice;
  final double pulseProgress;
  final Offset? crosshairPosition;
  final int? crosshairIndex;

  const ChartPainter({
    required this.candles,
    required this.mapper,
    required this.style,
    this.currentPrice,
    this.pulseProgress = 0.0,
    this.crosshairPosition,
    this.crosshairIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        mapper.paddingLeft,
        mapper.paddingTop,
        mapper.contentWidth,
        mapper.contentHeight,
      ),
    );
    _lineRenderer.drawSeries(
      canvas: canvas,
      candles: candles,
      mapper: mapper,
      style: style,
    );
    canvas.restore();

    if (style.axisStyle.showGrid) {
      _gridRenderer.draw(
        canvas: canvas,
        size: size,
        candles: candles,
        mapper: mapper,
        style: style,
        lineRenderer: _lineRenderer,
      );
    }

    if (style.priceLabelStyle.show) {
      _axisLabelRenderer.drawPriceLabels(
        canvas: canvas,
        candles: candles,
        mapper: mapper,
        style: style,
      );
    }

    if (style.timeLabelStyle.show) {
      _axisLabelRenderer.drawTimeLabels(
        canvas: canvas,
        candles: candles,
        mapper: mapper,
        style: style,
      );
    }

    if (currentPrice != null) {
      _currentPriceRenderer.draw(
        canvas: canvas,
        size: size,
        candles: candles,
        mapper: mapper,
        style: style,
        price: currentPrice!,
        lineRenderer: _lineRenderer,
      );
    }

    if (style.rippleStyle.show) {
      _rippleRenderer.draw(
        canvas: canvas,
        candles: candles,
        mapper: mapper,
        style: style,
        pulseProgress: pulseProgress,
      );
    }

    if (crosshairPosition != null &&
        crosshairIndex != null &&
        style.crosshairStyle.show) {
      _crosshairRenderer.draw(
        canvas: canvas,
        candles: candles,
        mapper: mapper,
        style: style,
        crosshairIndex: crosshairIndex,
        lineRenderer: _lineRenderer,
      );
    }
  }

  @override
  bool shouldRepaint(ChartPainter oldDelegate) {
    if (candles.length != oldDelegate.candles.length) {
      return true;
    }

    if (candles.isNotEmpty && oldDelegate.candles.isNotEmpty) {
      final lastCandle = candles.last;
      final oldLastCandle = oldDelegate.candles.last;

      if (lastCandle.close != oldLastCandle.close ||
          lastCandle.high != oldLastCandle.high ||
          lastCandle.low != oldLastCandle.low) {
        return true;
      }
    }

    return candles != oldDelegate.candles ||
        mapper != oldDelegate.mapper ||
        style != oldDelegate.style ||
        currentPrice != oldDelegate.currentPrice ||
        (pulseProgress - oldDelegate.pulseProgress).abs() > 0.01 ||
        crosshairPosition != oldDelegate.crosshairPosition ||
        crosshairIndex != oldDelegate.crosshairIndex;
  }
}
