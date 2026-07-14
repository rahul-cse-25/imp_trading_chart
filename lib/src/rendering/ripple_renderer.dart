import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart'
    show Candle, ChartStyle;
import 'package:imp_trading_chart/src/math/coordinate_mapper.dart'
    show CoordinateMapper;

@internal
class RippleRenderer {
  const RippleRenderer();

  void draw({
    required Canvas canvas,
    required List<Candle> candles,
    required CoordinateMapper mapper,
    required ChartStyle style,
    required double pulseProgress,
  }) {
    if (candles.isEmpty) return;

    final lastCandle = candles.last;
    final lastIndex = mapper.viewport.startIndex + candles.length - 1;
    final x = mapper.getCandleCenterX(lastIndex);
    final y = mapper.priceToY(lastCandle.close);
    final center = Offset(x, y);

    final chartLeft = mapper.paddingLeft;
    final chartRight = mapper.paddingLeft + mapper.contentWidth;
    final chartTop = mapper.paddingTop;
    final chartBottom = mapper.paddingTop + mapper.contentHeight;

    if (center.dx < chartLeft ||
        center.dx > chartRight ||
        center.dy < chartTop ||
        center.dy > chartBottom) {
      return;
    }

    final centerPointRadius =
        style.lineStyle.pointRadius > 0 ? style.lineStyle.pointRadius : 4.0;
    final rippleStyle = style.rippleStyle;
    final pulseColor = rippleStyle.color;
    final layout = style.layout;

    final glowPaint = Paint()
      ..color = pulseColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
      ..isAntiAlias = true;
    canvas.drawCircle(center, centerPointRadius + 3.0, glowPaint);

    final centerPaint = Paint()
      ..color = pulseColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(center, centerPointRadius, centerPaint);

    final centerBorderPaint = Paint()
      ..color = pulseColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;
    canvas.drawCircle(center, centerPointRadius + 1.5, centerBorderPaint);

    if (pulseProgress <= 0.001) return;

    final easedProgress = _easeOutCubic(pulseProgress);
    final preferredRadius = rippleStyle.maxRadius;
    final distanceToTop = center.dy - chartTop;
    final distanceToBottom = chartBottom - center.dy;
    final distanceToLeft = center.dx - chartLeft;
    final distanceToRight = (chartRight + layout.yAxisGap) - center.dx;
    final minVertical = math.min(distanceToTop, distanceToBottom);
    final minHorizontal = math.min(distanceToLeft, distanceToRight);
    final maxRadius =
        math.min(preferredRadius, math.min(minVertical, minHorizontal));

    if (maxRadius < 3.0) return;

    final radius = maxRadius * easedProgress;
    final opacity = math.pow(1.0 - easedProgress, 0.7).clamp(0.0, 1.0);
    if (radius <= 1.0 || opacity <= 0.01) return;

    final baseOpacity = opacity.clamp(0.0, 1.0);
    final maxOp = rippleStyle.maxOpacity;
    final gradient = ui.Gradient.radial(
      center,
      radius,
      [
        pulseColor.withValues(alpha: baseOpacity * maxOp),
        pulseColor.withValues(alpha: baseOpacity * maxOp * 0.9),
        pulseColor.withValues(alpha: baseOpacity * maxOp * 0.7),
        pulseColor.withValues(alpha: baseOpacity * maxOp * 0.4),
        pulseColor.withValues(alpha: baseOpacity * maxOp * 0.15),
        pulseColor.withValues(alpha: rippleStyle.minOpacity),
      ],
      const [0.0, 0.2, 0.4, 0.6, 0.85, 1.0],
    );

    final paint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        chartLeft,
        chartTop,
        (chartRight + layout.yAxisGap) - chartLeft,
        chartBottom - chartTop,
      ),
    );

    canvas.drawCircle(center, radius, paint);

    final ringPaint = Paint()
      ..color = pulseColor.withValues(alpha: baseOpacity * maxOp * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius * 0.7, ringPaint);

    final outerRingPaint = Paint()
      ..color = pulseColor.withValues(alpha: baseOpacity * maxOp * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius, outerRingPaint);
    canvas.restore();
  }

  double _easeOutCubic(double t) {
    final clampedT = t.clamp(0.0, 1.0);
    final oneMinusT = 1.0 - clampedT;
    return 1.0 - (oneMinusT * oneMinusT * oneMinusT);
  }
}
