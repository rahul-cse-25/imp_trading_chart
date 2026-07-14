import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart'
    show Candle, ChartStyle;
import 'package:imp_trading_chart/src/formatters/price_formatter.dart'
    show PriceFormatter;
import 'package:imp_trading_chart/src/formatters/time_formatter.dart'
    show CrosshairTimeFormatter;
import 'package:imp_trading_chart/src/math/coordinate_mapper.dart'
    show CoordinateMapper;
import 'package:imp_trading_chart/src/rendering/line_renderer.dart';
import 'package:imp_trading_chart/src/rendering/render_models.dart';

@internal
class CrosshairRenderer {
  const CrosshairRenderer();

  void draw({
    required Canvas canvas,
    required List<Candle> candles,
    required CoordinateMapper mapper,
    required ChartStyle style,
    required int? crosshairIndex,
    required LineRenderer lineRenderer,
  }) {
    final model = _buildModel(
      candles: candles,
      mapper: mapper,
      crosshairIndex: crosshairIndex,
    );
    if (model == null) return;

    final cs = style.crosshairStyle;

    final vLinePaint = Paint()
      ..color = cs.verticalLineColor
      ..strokeWidth = cs.verticalLineWidth;
    lineRenderer.drawStyledLine(
      canvas: canvas,
      start: Offset(model.x, mapper.paddingTop),
      end: Offset(model.x, mapper.paddingTop + mapper.contentHeight),
      paint: vLinePaint,
      lineStyle: cs.verticalLineStyle,
    );

    final hLinePaint = Paint()
      ..color = cs.horizontalLineColor
      ..strokeWidth = cs.horizontalLineWidth;
    lineRenderer.drawStyledLine(
      canvas: canvas,
      start: Offset(mapper.paddingLeft, model.y),
      end: Offset(mapper.paddingLeft + mapper.contentWidth, model.y),
      paint: hLinePaint,
      lineStyle: cs.horizontalLineStyle,
    );

    final pointPaint = Paint()
      ..color = cs.trackerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(model.x, model.y), cs.trackerRadius, pointPaint);

    if (cs.showTrackerRing) {
      final ringPaint = Paint()
        ..color = cs.trackerRingColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = cs.trackerRingWidth;
      canvas.drawCircle(
        Offset(model.x, model.y),
        cs.trackerRadius + 2.0,
        ringPaint,
      );
    }

    final labelFontSize = cs.labelFontSize ?? style.labelFontSize;
    if (cs.showPriceLabel) {
      _drawPriceLabel(
        canvas: canvas,
        mapper: mapper,
        style: style,
        model: model,
        labelFontSize: labelFontSize,
      );
    }

    if (cs.showTimeLabel) {
      _drawTimeLabel(
        canvas: canvas,
        mapper: mapper,
        style: style,
        model: model,
        labelFontSize: labelFontSize,
      );
    }
  }

  CrosshairRenderModel? _buildModel({
    required List<Candle> candles,
    required CoordinateMapper mapper,
    required int? crosshairIndex,
  }) {
    if (crosshairIndex == null ||
        crosshairIndex < 0 ||
        crosshairIndex >= candles.length) {
      return null;
    }

    final candle = candles[crosshairIndex];
    final absoluteIndex = mapper.viewport.startIndex + crosshairIndex;
    final x = mapper.getCandleCenterX(absoluteIndex);
    final y = mapper.priceToY(candle.close);
    if (!x.isFinite || !y.isFinite) return null;

    return CrosshairRenderModel(
      candle: candle,
      absoluteIndex: absoluteIndex,
      x: x,
      y: y,
    );
  }

  void _drawPriceLabel({
    required Canvas canvas,
    required CoordinateMapper mapper,
    required ChartStyle style,
    required CrosshairRenderModel model,
    required double labelFontSize,
  }) {
    final cs = style.crosshairStyle;
    final priceText = PriceFormatter.crosshair().format(model.candle.close);
    final priceTextStyle = TextStyle(
      color: cs.labelTextColor,
      fontSize: labelFontSize,
      fontWeight: cs.labelFontWeight,
    );
    final pricePainter = TextPainter(
      text: TextSpan(text: priceText, style: priceTextStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final priceLabelX = mapper.paddingLeft +
        mapper.contentWidth +
        style.axisStyle.yAxisPadding +
        3;
    var priceLabelY = model.y - pricePainter.height / 2;
    priceLabelY = priceLabelY.clamp(
      mapper.paddingTop,
      mapper.paddingTop + mapper.contentHeight - pricePainter.height,
    );

    final priceBgRect = Rect.fromLTWH(
      priceLabelX - cs.labelPaddingH,
      priceLabelY - cs.labelPaddingV,
      pricePainter.width + (cs.labelPaddingH * 2),
      pricePainter.height + (cs.labelPaddingV * 2),
    );

    final priceBgPaint = Paint()
      ..color = cs.labelBackgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        priceBgRect,
        Radius.circular(cs.labelBorderRadius),
      ),
      priceBgPaint,
    );
    pricePainter.paint(canvas, Offset(priceLabelX, priceLabelY));
  }

  void _drawTimeLabel({
    required Canvas canvas,
    required CoordinateMapper mapper,
    required ChartStyle style,
    required CrosshairRenderModel model,
    required double labelFontSize,
  }) {
    final cs = style.crosshairStyle;
    final timeText = const CrosshairTimeFormatter().format(model.candle.time);
    final timeTextStyle = TextStyle(
      color: cs.labelTextColor,
      fontSize: labelFontSize,
      fontWeight: cs.labelFontWeight,
    );
    final timePainter = TextPainter(
      text: TextSpan(text: timeText, style: timeTextStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    var timeLabelX = model.x - timePainter.width / 2;
    timeLabelX = timeLabelX.clamp(
      mapper.paddingLeft,
      mapper.paddingLeft + mapper.contentWidth - timePainter.width,
    );

    final timeLabelY = mapper.paddingTop +
        mapper.contentHeight +
        style.axisStyle.xAxisPadding +
        2;
    final timeBgRect = Rect.fromLTWH(
      timeLabelX - cs.labelPaddingH,
      timeLabelY - cs.labelPaddingV,
      timePainter.width + (cs.labelPaddingH * 2),
      timePainter.height + (cs.labelPaddingV * 2),
    );

    final timeBgPaint = Paint()
      ..color = cs.labelBackgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        timeBgRect,
        Radius.circular(cs.labelBorderRadius),
      ),
      timeBgPaint,
    );
    timePainter.paint(canvas, Offset(timeLabelX, timeLabelY));
  }
}
