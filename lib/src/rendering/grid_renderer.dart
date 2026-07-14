import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart'
    show Candle, ChartStyle;
import 'package:imp_trading_chart/src/math/coordinate_mapper.dart'
    show CoordinateMapper;
import 'package:imp_trading_chart/src/rendering/line_renderer.dart';

@internal
class GridRenderer {
  const GridRenderer();

  void draw({
    required Canvas canvas,
    required Size size,
    required List<Candle> candles,
    required CoordinateMapper mapper,
    required ChartStyle style,
    required LineRenderer lineRenderer,
  }) {
    final axisStyle = style.axisStyle;
    if (!axisStyle.showGrid || mapper.contentHeight <= 0) return;

    final layout = style.layout;
    final paint = Paint()
      ..color = axisStyle.gridColor.withValues(alpha: 0.2)
      ..strokeWidth = axisStyle.gridLineWidth;

    final chartLeft = mapper.paddingLeft;
    final chartRight = mapper.paddingLeft + mapper.contentWidth;
    final chartTop = mapper.paddingTop;
    final chartBottom = mapper.paddingTop + mapper.contentHeight;

    double horizontalLineEndX = chartRight;
    if (style.priceLabelStyle.show) {
      final labelPadding = style.priceLabelStyle.padding;
      final textStartX = chartRight + layout.yAxisGap + labelPadding.left;
      horizontalLineEndX = textStartX - layout.gridToLabelGapY;
    }

    final clampedHorizontalEndX =
        horizontalLineEndX.clamp(chartLeft, size.width);

    double verticalLineEndY = chartBottom;
    if (style.timeLabelStyle.show) {
      final labelPadding = style.timeLabelStyle.padding;
      final textStartY = chartBottom + layout.xAxisGap + labelPadding.top;
      verticalLineEndY = textStartY - layout.gridToLabelGapX;
    }

    final clampedVerticalEndY = verticalLineEndY.clamp(chartTop, size.height);
    final horizontalLines = axisStyle.horizontalGridLines;

    if (horizontalLines > 0) {
      for (int i = 0; i <= horizontalLines; i++) {
        final y = chartTop + (mapper.contentHeight * i / horizontalLines);
        lineRenderer.drawStyledLine(
          canvas: canvas,
          start: Offset(chartLeft, y),
          end: Offset(clampedHorizontalEndX, y),
          paint: paint,
          lineStyle: axisStyle.gridLineStyle,
        );
      }
    }

    final visibleCount = candles.length;
    if (visibleCount == 0) return;

    final verticalLines = axisStyle.verticalGridLines > 0
        ? axisStyle.verticalGridLines
        : math.min(visibleCount, 6);

    for (int i = 0; i <= verticalLines; i++) {
      final relativeIndex =
          (visibleCount * i / verticalLines).round().clamp(0, visibleCount - 1);
      final index = mapper.viewport.startIndex + relativeIndex;
      final x = mapper.indexToX(index);

      if (x.isFinite && x >= chartLeft && x <= chartRight) {
        lineRenderer.drawStyledLine(
          canvas: canvas,
          start: Offset(x, chartTop),
          end: Offset(x, clampedVerticalEndY),
          paint: paint,
          lineStyle: axisStyle.gridLineStyle,
        );
      }
    }
  }
}
