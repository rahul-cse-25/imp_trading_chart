import 'package:meta/meta.dart';
import 'package:imp_trading_chart/src/api/controller/chart_state.dart';

@internal
class ChartStateStore {
  ChartState _state;

  ChartStateStore(this._state);

  ChartState get state => _state;

  void replace(ChartState nextState) {
    _state = nextState;
  }
}
