import 'package:meta/meta.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart' show Candle;

@immutable
class ChartInteractionState {
  final int? selectedAbsoluteIndex;
  final Candle? selectedCandle;

  const ChartInteractionState({
    this.selectedAbsoluteIndex,
    this.selectedCandle,
  });

  static const empty = ChartInteractionState();

  bool get hasSelection =>
      selectedAbsoluteIndex != null && selectedCandle != null;

  ChartInteractionState clear() => empty;

  ChartInteractionState select({
    required int absoluteIndex,
    required Candle candle,
  }) {
    return ChartInteractionState(
      selectedAbsoluteIndex: absoluteIndex,
      selectedCandle: candle,
    );
  }
}
