import 'package:flutter/foundation.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart' show Candle;
import 'package:imp_trading_chart/src/api/controller/chart_live_view_policy.dart';

/// Public immutable description of the current viewport.
@immutable
class ChartViewportSnapshot {
  final int startIndex;
  final int visibleCount;
  final int endIndex;
  final int totalCount;

  const ChartViewportSnapshot({
    required this.startIndex,
    required this.visibleCount,
    required this.endIndex,
    required this.totalCount,
  });

  bool get isEmpty => totalCount == 0 || visibleCount == 0;
  bool get isAtStart => startIndex <= 0;
  bool get isAtEnd => endIndex >= totalCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartViewportSnapshot &&
          runtimeType == other.runtimeType &&
          startIndex == other.startIndex &&
          visibleCount == other.visibleCount &&
          endIndex == other.endIndex &&
          totalCount == other.totalCount;

  @override
  int get hashCode => Object.hash(
        startIndex,
        visibleCount,
        endIndex,
        totalCount,
      );
}

/// Public immutable description of the visible candle range.
@immutable
class ChartVisibleRange {
  final int startIndex;
  final int endIndex;
  final int length;

  const ChartVisibleRange({
    required this.startIndex,
    required this.endIndex,
    required this.length,
  });

  bool contains(int index) => index >= startIndex && index < endIndex;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartVisibleRange &&
          runtimeType == other.runtimeType &&
          startIndex == other.startIndex &&
          endIndex == other.endIndex &&
          length == other.length;

  @override
  int get hashCode => Object.hash(startIndex, endIndex, length);
}

/// Public immutable description of a selected candle / crosshair target.
@immutable
class ChartSelectionSnapshot {
  final int absoluteIndex;
  final int visibleIndex;
  final Candle candle;

  const ChartSelectionSnapshot({
    required this.absoluteIndex,
    required this.visibleIndex,
    required this.candle,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartSelectionSnapshot &&
          runtimeType == other.runtimeType &&
          absoluteIndex == other.absoluteIndex &&
          visibleIndex == other.visibleIndex &&
          candle == other.candle;

  @override
  int get hashCode => Object.hash(absoluteIndex, visibleIndex, candle);
}

/// Public immutable snapshot of the current controller-visible chart state.
@immutable
class ChartRenderSnapshot {
  final List<Candle> candles;
  final List<Candle> visibleCandles;
  final ChartViewportSnapshot viewport;
  final ChartVisibleRange visibleRange;
  final ChartSelectionSnapshot? selection;
  final bool followLatest;
  final ChartFollowLatestState followLatestState;
  final double? latestPrice;

  const ChartRenderSnapshot({
    required this.candles,
    required this.visibleCandles,
    required this.viewport,
    required this.visibleRange,
    required this.selection,
    required this.followLatest,
    required this.followLatestState,
    required this.latestPrice,
  });

  bool get hasSelection => selection != null;
}
