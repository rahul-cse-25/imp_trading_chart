import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart'
    show Candle, ChartStyle;
import 'package:imp_trading_chart/src/data/enums.dart' show LineStyle;
import 'package:imp_trading_chart/src/math/coordinate_mapper.dart'
    show CoordinateMapper;

@internal
class LineRenderer {
  const LineRenderer();

  void drawSeries({
    required Canvas canvas,
    required List<Candle> candles,
    required CoordinateMapper mapper,
    required ChartStyle style,
  }) {
    if (candles.length == 1) {
      _drawSingleDataPoint(
        canvas: canvas,
        candles: candles,
        mapper: mapper,
        style: style,
      );
      return;
    }

    if (candles.length < 2) return;

    if (style.lineStyle.smooth) {
      _drawSmoothLineChart(
        canvas: canvas,
        candles: candles,
        mapper: mapper,
        style: style,
      );
      return;
    }

    _drawStraightLineChart(
      canvas: canvas,
      candles: candles,
      mapper: mapper,
      style: style,
    );
  }

  void drawStyledLine({
    required Canvas canvas,
    required Offset start,
    required Offset end,
    required Paint paint,
    required LineStyle lineStyle,
  }) {
    switch (lineStyle) {
      case LineStyle.solid:
        canvas.drawLine(start, end, paint);
        break;
      case LineStyle.dashed:
        _drawDashedLine(canvas, start, end, paint, const [8.0, 4.0]);
        break;
      case LineStyle.dotted:
        _drawDashedLine(canvas, start, end, paint, const [2.0, 3.0]);
        break;
    }
  }

  void _drawSingleDataPoint({
    required Canvas canvas,
    required List<Candle> candles,
    required CoordinateMapper mapper,
    required ChartStyle style,
  }) {
    if (candles.isEmpty) return;

    final candle = candles.first;
    if (!candle.close.isFinite) return;

    final x = mapper.paddingLeft + (mapper.contentWidth / 2);
    final y = mapper.priceToY(candle.close);

    if (!x.isFinite || !y.isFinite) return;

    final lineStyle = style.lineStyle;
    final pointRadius = lineStyle.pointRadius > 0 ? lineStyle.pointRadius : 6.0;

    if (lineStyle.showGlow) {
      final glowPaint = Paint()
        ..color = lineStyle.color.withValues(alpha: 0.3)
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, lineStyle.glowWidth * 3);
      canvas.drawCircle(Offset(x, y), pointRadius + 4, glowPaint);
    }

    final pointPaint = Paint()
      ..color = lineStyle.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), pointRadius, pointPaint);
  }

  void _drawStraightLineChart({
    required Canvas canvas,
    required List<Candle> candles,
    required CoordinateMapper mapper,
    required ChartStyle style,
  }) {
    if (candles.length < 2) return;

    final path = Path();
    var isFirst = true;

    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      if (!candle.close.isFinite) continue;

      final index = mapper.viewport.startIndex + i;
      if (index < 0 || index >= mapper.viewport.totalCount) continue;

      final x = mapper.getCandleCenterX(index);
      final y = mapper.priceToY(candle.close);

      if (!x.isFinite || !y.isFinite) continue;

      if (isFirst) {
        path.moveTo(x, y);
        isFirst = false;
      } else {
        path.lineTo(x, y);
      }
    }

    if (isFirst) return;

    _drawPathWithEffects(
      canvas: canvas,
      path: path,
      candles: candles,
      mapper: mapper,
      style: style,
    );
  }

  void _drawSmoothLineChart({
    required Canvas canvas,
    required List<Candle> candles,
    required CoordinateMapper mapper,
    required ChartStyle style,
  }) {
    if (candles.length < 2) return;

    final points = <Offset>[];

    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      if (!candle.close.isFinite) continue;

      final index = mapper.viewport.startIndex + i;
      if (index < 0 || index >= mapper.viewport.totalCount) continue;

      final x = mapper.getCandleCenterX(index);
      final y = mapper.priceToY(candle.close);

      if (!x.isFinite || !y.isFinite) continue;
      points.add(Offset(x, y));
    }

    if (points.length < 2) return;

    final path = _generateCardinalSplinePath(points, style);

    final chartLeft = mapper.paddingLeft;
    final chartTop = mapper.paddingTop;
    final chartRight = mapper.paddingLeft + mapper.contentWidth;
    final chartBottom = mapper.paddingTop + mapper.contentHeight;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(chartLeft, chartTop, chartRight, chartBottom));
    _drawPathWithEffects(
      canvas: canvas,
      path: path,
      candles: candles,
      mapper: mapper,
      style: style,
    );
    canvas.restore();
  }

  Path _generateCardinalSplinePath(List<Offset> points, ChartStyle style) {
    final path = Path();
    final n = points.length;

    if (n < 2) return path;

    path.moveTo(points[0].dx, points[0].dy);

    if (n == 2) {
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }

    final userTension = style.lineStyle.curveTension.clamp(0.0, 1.0);
    final tension = 1.0 - userTension;
    final c = (1.0 - tension) / 2.0;

    for (int i = 0; i < n - 1; i++) {
      final Offset p0;
      final Offset p3;

      if (i == 0) {
        p0 = Offset(
          2 * points[0].dx - points[1].dx,
          2 * points[0].dy - points[1].dy,
        );
      } else {
        p0 = points[i - 1];
      }

      final p1 = points[i];
      final p2 = points[i + 1];

      if (i == n - 2) {
        p3 = Offset(
          2 * points[n - 1].dx - points[n - 2].dx,
          2 * points[n - 1].dy - points[n - 2].dy,
        );
      } else {
        p3 = points[i + 2];
      }

      final t1x = c * (p2.dx - p0.dx);
      final t1y = c * (p2.dy - p0.dy);
      final t2x = c * (p3.dx - p1.dx);
      final t2y = c * (p3.dy - p1.dy);

      final cp1 = Offset(p1.dx + t1x / 3.0, p1.dy + t1y / 3.0);
      final cp2 = Offset(p2.dx - t2x / 3.0, p2.dy - t2y / 3.0);

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    return path;
  }

  void _drawPathWithEffects({
    required Canvas canvas,
    required Path path,
    required List<Candle> candles,
    required CoordinateMapper mapper,
    required ChartStyle style,
  }) {
    final lineStyle = style.lineStyle;

    if (lineStyle.showGlow) {
      final glowPaint = Paint()
        ..color = lineStyle.color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineStyle.width + (lineStyle.glowWidth * 2)
        ..maskFilter =
            ui.MaskFilter.blur(ui.BlurStyle.normal, lineStyle.glowWidth);

      canvas.drawPath(path, glowPaint);
    }

    final linePaint = Paint()
      ..color = lineStyle.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineStyle.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    if (lineStyle.showPoints && lineStyle.pointRadius > 0) {
      final pointPaint = Paint()
        ..color = lineStyle.color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      for (int i = 0; i < candles.length; i++) {
        final candle = candles[i];
        final index = mapper.viewport.startIndex + i;
        final x = mapper.getCandleCenterX(index);
        final y = mapper.priceToY(candle.close);

        canvas.drawCircle(
          Offset(x, y),
          lineStyle.pointRadius,
          pointPaint,
        );
      }
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    List<double> dashArray,
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);

    if (length == 0) return;

    final unitX = dx / length;
    final unitY = dy / length;
    final dashLength = dashArray[0];
    final gapLength = dashArray.length > 1 ? dashArray[1] : dashArray[0];
    final totalPatternLength = dashLength + gapLength;

    double distance = 0.0;
    while (distance < length) {
      final dashStart = distance;
      final dashEnd = math.min(distance + dashLength, length);

      if (dashEnd > dashStart) {
        final startX = start.dx + unitX * dashStart;
        final startY = start.dy + unitY * dashStart;
        final endX = start.dx + unitX * dashEnd;
        final endY = start.dy + unitY * dashEnd;
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      }

      distance += totalPatternLength;
    }
  }
}
