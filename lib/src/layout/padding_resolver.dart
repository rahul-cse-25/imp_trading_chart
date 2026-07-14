import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart' show ChartStyle;
import 'package:imp_trading_chart/src/engine/chart_engine.dart';

@immutable
class ChartPadding {
  final double left;
  final double right;
  final double top;
  final double bottom;

  const ChartPadding({
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  });
}

/// Resolves the final chart padding based on visible labels and content.
class PaddingResolver {
  const PaddingResolver();

  ChartPadding resolve({
    required Size size,
    required ChartStyle style,
    required ChartEngine engine,
    double? currentPrice,
  }) {
    final layout = style.layout;
    final chartDataLeft = layout.chartDataPadding.left;
    final chartDataTop = layout.chartDataPadding.top;

    double yAxisAreaWidth = 0.0;
    final priceLabelStyle = style.priceLabelStyle;

    if (priceLabelStyle.show && engine.candles.isNotEmpty) {
      final scale = engine.getPriceScale();
      final formatter = priceLabelStyle.formatter;
      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      double maxLabelWidth = 0.0;

      for (int i = 0; i <= priceLabelStyle.labelCount; i++) {
        final price = scale.max -
            ((scale.max - scale.min) * i / priceLabelStyle.labelCount);
        textPainter.text = TextSpan(
          text: formatter.format(price),
          style: TextStyle(fontSize: priceLabelStyle.fontSize),
        );
        textPainter.layout();
        maxLabelWidth = math.max(maxLabelWidth, textPainter.width);
      }

      double currentPriceLabelWidth = 0.0;
      final currentPriceStyle = style.currentPriceStyle;
      if (currentPriceStyle.showLabel) {
        final effectiveCurrentPrice = currentPrice ?? engine.getLatestPrice();
        if (effectiveCurrentPrice != null) {
          textPainter.text = TextSpan(
            text: formatter.format(effectiveCurrentPrice),
            style: TextStyle(
              fontSize: currentPriceStyle.labelFontSize,
              fontWeight: FontWeight.bold,
            ),
          );
          textPainter.layout();
          currentPriceLabelWidth =
              textPainter.width + (currentPriceStyle.labelPaddingH * 2);
        }
      }

      yAxisAreaWidth = layout.yAxisGap +
          math.max(maxLabelWidth, currentPriceLabelWidth) +
          layout.yAxisLabelPadding.horizontal;
    }

    double xAxisAreaHeight = 0.0;
    final timeLabelStyle = style.timeLabelStyle;
    if (timeLabelStyle.show && engine.candles.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '00:00',
          style: TextStyle(fontSize: timeLabelStyle.fontSize),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      xAxisAreaHeight = layout.xAxisGap +
          textPainter.height +
          layout.xAxisLabelPadding.vertical;
    }

    return ChartPadding(
      left: chartDataLeft,
      right:
          yAxisAreaWidth > 0 ? yAxisAreaWidth : layout.chartDataPadding.right,
      top: chartDataTop,
      bottom: xAxisAreaHeight > 0
          ? xAxisAreaHeight
          : layout.chartDataPadding.bottom,
    );
  }
}
