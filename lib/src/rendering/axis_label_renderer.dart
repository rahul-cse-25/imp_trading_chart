import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart'
    show Candle, ChartStyle;
import 'package:imp_trading_chart/src/formatters/time_formatter.dart'
    show TimeFormatContext;
import 'package:imp_trading_chart/src/layout/chart_layout.dart';
import 'package:imp_trading_chart/src/math/coordinate_mapper.dart'
    show CoordinateMapper;
import 'package:imp_trading_chart/src/rendering/render_models.dart';

@internal
class AxisLabelRenderer {
  const AxisLabelRenderer();

  void drawPriceLabels({
    required Canvas canvas,
    required List<Candle> candles,
    required CoordinateMapper mapper,
    required ChartStyle style,
  }) {
    final priceLabelStyle = style.priceLabelStyle;
    if (!priceLabelStyle.show) return;

    final layout = style.layout;
    final textStyle = TextStyle(
      color: priceLabelStyle.color,
      fontSize: priceLabelStyle.fontSize,
      fontWeight: priceLabelStyle.fontWeight,
    );
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final bgPaint = Paint()
      ..color = (priceLabelStyle.backgroundColor ?? style.backgroundColor)
      ..style = PaintingStyle.fill;
    final scale = mapper.priceScale;
    final labelCount = priceLabelStyle.labelCount;
    final yAxisLabelPadding = priceLabelStyle.padding;

    if (labelCount <= 0 ||
        scale.range <= 0 ||
        !scale.max.isFinite ||
        !scale.min.isFinite) {
      return;
    }

    if (labelCount == 1) {
      final price = (scale.max + scale.min) / 2;
      if (!price.isFinite) return;

      _paintPriceLabel(
        canvas: canvas,
        mapper: mapper,
        layout: layout,
        backgroundPaint: bgPaint,
        textPainter: textPainter,
        textStyle: textStyle,
        padding: yAxisLabelPadding,
        priceText: priceLabelStyle.formatter.format(price),
        centerY: mapper.priceToY(price).clamp(
              mapper.paddingTop,
              mapper.paddingTop + mapper.contentHeight,
            ),
      );
      return;
    }

    for (int i = 0; i < labelCount; i++) {
      final price =
          scale.max - ((scale.max - scale.min) * i / (labelCount - 1));
      if (!price.isFinite) continue;

      _paintPriceLabel(
        canvas: canvas,
        mapper: mapper,
        layout: layout,
        backgroundPaint: bgPaint,
        textPainter: textPainter,
        textStyle: textStyle,
        padding: yAxisLabelPadding,
        priceText: priceLabelStyle.formatter.format(price),
        centerY: mapper.priceToY(price).clamp(
              mapper.paddingTop,
              mapper.paddingTop + mapper.contentHeight,
            ),
      );
    }
  }

  void drawTimeLabels({
    required Canvas canvas,
    required List<Candle> candles,
    required CoordinateMapper mapper,
    required ChartStyle style,
  }) {
    if (candles.isEmpty) return;

    final timeLabelStyle = style.timeLabelStyle;
    if (!timeLabelStyle.show) return;

    final layout = style.layout;
    final textStyle = TextStyle(
      color: timeLabelStyle.color,
      fontSize: timeLabelStyle.fontSize,
      fontWeight: timeLabelStyle.fontWeight,
    );
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final bgPaint = Paint()
      ..color = (timeLabelStyle.backgroundColor ?? style.backgroundColor)
      ..style = PaintingStyle.fill;
    final xAxisLabelPadding = timeLabelStyle.padding;
    final labelCount = timeLabelStyle.labelCount;

    if (labelCount <= 0) return;

    final visibleCount = candles.length;
    final labelCountToShow = math.min(visibleCount, labelCount);
    if (labelCountToShow <= 0) return;

    final firstCandle = candles.first;
    final lastCandle = candles.last;
    final visibleTimeSpan = Duration(
      seconds: (lastCandle.time - firstCandle.time).abs(),
    );

    final chartLeft = mapper.paddingLeft;
    final chartRight = mapper.paddingLeft + mapper.contentWidth;
    final labelInfos = <AxisLabelLayoutSnapshot>[];

    for (int i = 0; i < labelCountToShow; i++) {
      final relativeIndex = (visibleCount > 1)
          ? ((visibleCount - 1) * i / (labelCountToShow - 1)).round()
          : 0;

      if (relativeIndex < 0 || relativeIndex >= candles.length) {
        continue;
      }

      final candle = candles[relativeIndex];
      final dataIndex = mapper.viewport.startIndex + relativeIndex;
      final x = mapper.indexToX(dataIndex);
      if (!x.isFinite) continue;

      final isFirstLabel = i == 0;
      final isLastLabel = i == labelCountToShow - 1;
      final context = TimeFormatContext(
        visibleTimeSpan: visibleTimeSpan,
        isFirstLabel: isFirstLabel,
        isLastLabel: isLastLabel,
        labelIndex: i,
        totalLabels: labelCountToShow,
      );
      final timeText = timeLabelStyle.formatter.format(
        candle.time,
        context: context,
      );

      textPainter.text = TextSpan(text: timeText, style: textStyle);
      textPainter.layout();
      if (textPainter.width <= 0 || textPainter.height <= 0) continue;

      double labelX;
      if (visibleCount == 1 && labelCountToShow == 1) {
        labelX = x - (textPainter.width / 2);
      } else if (isFirstLabel) {
        labelX = chartLeft;
      } else {
        labelX = x;
      }

      labelX = labelX.clamp(chartLeft, chartRight - textPainter.width);
      labelInfos.add(
        AxisLabelLayoutSnapshot(
          text: timeText,
          x: labelX,
          width: textPainter.width,
          index: i,
          isFirst: isFirstLabel,
          isLast: isLastLabel,
        ),
      );
    }

    const minSpacing = 8.0;
    final visibleLabels = <AxisLabelLayoutSnapshot>[];

    for (final label in labelInfos) {
      if (candles.length == 1 && labelInfos.length == 1) {
        final centerX = mapper.paddingLeft + (mapper.contentWidth / 2);
        visibleLabels.add(
          AxisLabelLayoutSnapshot(
            text: label.text,
            x: (centerX - label.width / 2).clamp(
              chartLeft,
              chartRight - label.width,
            ),
            width: label.width,
            index: label.index,
            isFirst: true,
            isLast: true,
          ),
        );
        continue;
      }

      if (label.isFirst || label.isLast) {
        visibleLabels.add(label);
        continue;
      }

      var overlaps = false;
      for (final visible in visibleLabels) {
        if ((label.x < visible.x + visible.width + minSpacing) &&
            (label.x + label.width + minSpacing > visible.x)) {
          overlaps = true;
          break;
        }
      }

      if (!overlaps) {
        visibleLabels.add(label);
      }
    }

    visibleLabels.sort((a, b) => a.index.compareTo(b.index));

    final chartBottom = mapper.paddingTop + mapper.contentHeight;
    final labelY = chartBottom + layout.xAxisGap + xAxisLabelPadding.top;

    for (final labelInfo in visibleLabels) {
      textPainter.text = TextSpan(text: labelInfo.text, style: textStyle);
      textPainter.layout();

      final bgColor = timeLabelStyle.backgroundColor ?? style.backgroundColor;
      if (bgColor.a > 0.0) {
        final labelRect = Rect.fromLTWH(
          labelInfo.x - xAxisLabelPadding.horizontal,
          labelY - xAxisLabelPadding.top,
          labelInfo.width + xAxisLabelPadding.horizontal * 2,
          textPainter.height + xAxisLabelPadding.vertical,
        );
        canvas.drawRect(labelRect, bgPaint);
      }

      textPainter.paint(canvas, Offset(labelInfo.x, labelY));
    }
  }

  void _paintPriceLabel({
    required Canvas canvas,
    required CoordinateMapper mapper,
    required ChartLayout layout,
    required Paint backgroundPaint,
    required TextPainter textPainter,
    required TextStyle textStyle,
    required EdgeInsets padding,
    required String priceText,
    required double centerY,
  }) {
    textPainter.text = TextSpan(text: priceText, style: textStyle);
    textPainter.layout();

    if (textPainter.width <= 0 || textPainter.height <= 0) {
      return;
    }

    final chartRight = mapper.paddingLeft + mapper.contentWidth;
    final labelX = chartRight + layout.yAxisGap + padding.left;

    if (backgroundPaint.color.a > 0.0) {
      final rect = Rect.fromLTWH(
        labelX - padding.left,
        centerY - textPainter.height / 2 - padding.vertical,
        textPainter.width + padding.horizontal,
        textPainter.height + (padding.vertical * 2),
      );
      canvas.drawRect(rect, backgroundPaint);
    }

    textPainter.paint(
      canvas,
      Offset(labelX, centerY - textPainter.height / 2),
    );
  }
}
