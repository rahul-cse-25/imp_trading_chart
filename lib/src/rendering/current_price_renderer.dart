import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart'
    show Candle, ChartStyle;
import 'package:imp_trading_chart/src/math/coordinate_mapper.dart'
    show CoordinateMapper;
import 'package:imp_trading_chart/src/rendering/line_renderer.dart';
import 'package:imp_trading_chart/src/rendering/render_models.dart';

@internal
class CurrentPriceRenderer {
  const CurrentPriceRenderer();

  void draw({
    required Canvas canvas,
    required Size size,
    required List<Candle> candles,
    required CoordinateMapper mapper,
    required ChartStyle style,
    required double price,
    required LineRenderer lineRenderer,
  }) {
    final model = _buildModel(
      candles: candles,
      mapper: mapper,
      price: price,
    );
    final currentPriceStyle = style.currentPriceStyle;
    final layout = style.layout;
    final chartRight = mapper.paddingLeft + mapper.contentWidth;

    if (currentPriceStyle.showLine && model.isPriceVisible) {
      final paint = Paint()
        ..color = currentPriceStyle.lineColor
        ..strokeWidth = currentPriceStyle.lineWidth;

      double lineEndX = chartRight;
      if (style.priceLabelStyle.show) {
        final yAxisLabelPadding = style.priceLabelStyle.padding;
        final textStartX =
            chartRight + layout.yAxisGap + yAxisLabelPadding.left;
        lineEndX = textStartX - layout.gridToLabelGapY;
      }

      lineRenderer.drawStyledLine(
        canvas: canvas,
        start: Offset(mapper.paddingLeft, model.lineY),
        end:
            Offset(lineEndX.clamp(mapper.paddingLeft, size.width), model.lineY),
        paint: paint,
        lineStyle: currentPriceStyle.lineStyle,
      );
    }

    if (!currentPriceStyle.showLabel) return;

    final labelBgColor = model.isPriceUp
        ? currentPriceStyle.bullishColor
        : currentPriceStyle.bearishColor;

    final textStyle = TextStyle(
      color: currentPriceStyle.textColor,
      fontSize: currentPriceStyle.labelFontSize,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    );
    final priceText = style.priceLabelStyle.formatter.format(model.price);
    final textPainter = TextPainter(
      text: TextSpan(text: priceText, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelWidth =
        textPainter.width + (currentPriceStyle.labelPaddingH * 2);
    final labelHeight =
        textPainter.height + (currentPriceStyle.labelPaddingV * 2);
    final bgStartX = chartRight + layout.yAxisGap;
    final textX = bgStartX + currentPriceStyle.labelPaddingH;
    var labelY = model.lineY - labelHeight / 2;
    labelY = labelY.clamp(
      mapper.paddingTop,
      mapper.paddingTop + mapper.contentHeight - labelHeight,
    );

    final labelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bgStartX, labelY, labelWidth, labelHeight),
      Radius.circular(currentPriceStyle.labelBorderRadius),
    );

    final bgPaint = Paint()
      ..color = labelBgColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(labelRect, bgPaint);
    textPainter.paint(
      canvas,
      Offset(textX, labelY + currentPriceStyle.labelPaddingV),
    );
  }

  CurrentPriceRenderModel _buildModel({
    required List<Candle> candles,
    required CoordinateMapper mapper,
    required double price,
  }) {
    final y = mapper.priceToY(price);
    final scale = mapper.priceScale;

    double? previousPrice;
    if (candles.length >= 2) {
      previousPrice = candles[candles.length - 2].close;
    } else if (candles.isNotEmpty) {
      previousPrice = candles.first.open;
    }

    final isPriceUp = previousPrice != null ? price >= previousPrice : true;
    final isPriceVisible = price >= scale.min && price <= scale.max;

    double lineY;
    if (isPriceVisible) {
      lineY = y;
    } else if (price < scale.min) {
      lineY = mapper.paddingTop + mapper.contentHeight;
    } else {
      lineY = mapper.paddingTop;
    }

    return CurrentPriceRenderModel(
      price: price,
      lineY: lineY,
      isPriceUp: isPriceUp,
      isPriceVisible: isPriceVisible,
    );
  }
}
