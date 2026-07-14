import 'package:flutter/foundation.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart' show Candle;

@immutable
class AxisLabelLayoutSnapshot {
  const AxisLabelLayoutSnapshot({
    required this.text,
    required this.x,
    required this.width,
    required this.index,
    required this.isFirst,
    required this.isLast,
  });

  final String text;
  final double x;
  final double width;
  final int index;
  final bool isFirst;
  final bool isLast;
}

@immutable
class CurrentPriceRenderModel {
  const CurrentPriceRenderModel({
    required this.price,
    required this.lineY,
    required this.isPriceUp,
    required this.isPriceVisible,
  });

  final double price;
  final double lineY;
  final bool isPriceUp;
  final bool isPriceVisible;
}

@immutable
class CrosshairRenderModel {
  const CrosshairRenderModel({
    required this.candle,
    required this.absoluteIndex,
    required this.x,
    required this.y,
  });

  final Candle candle;
  final int absoluteIndex;
  final double x;
  final double y;
}
