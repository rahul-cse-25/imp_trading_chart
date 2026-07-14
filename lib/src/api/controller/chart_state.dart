import 'package:meta/meta.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart' show Candle;
import 'package:imp_trading_chart/src/api/controller/chart_interaction_state.dart';
import 'package:imp_trading_chart/src/engine/chart_viewport.dart';

@immutable
class ChartState {
  final List<Candle> candles;
  final ChartViewport viewport;
  final ChartInteractionState interaction;
  final bool followLatest;
  final int version;

  const ChartState({
    required this.candles,
    required this.viewport,
    required this.interaction,
    required this.followLatest,
    required this.version,
  });

  ChartState copyWith({
    List<Candle>? candles,
    ChartViewport? viewport,
    ChartInteractionState? interaction,
    bool? followLatest,
    int? version,
  }) {
    return ChartState(
      candles: candles ?? this.candles,
      viewport: viewport ?? this.viewport,
      interaction: interaction ?? this.interaction,
      followLatest: followLatest ?? this.followLatest,
      version: version ?? this.version,
    );
  }
}
