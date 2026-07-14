import 'package:meta/meta.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart' show Candle;
import 'package:imp_trading_chart/src/api/controller/chart_state.dart';
import 'package:imp_trading_chart/src/api/controller/chart_viewport_policy.dart';
import 'package:imp_trading_chart/src/engine/chart_viewport.dart';

@immutable
class ChartLiveUpdateResult {
  final ChartState state;
  final bool appendedNewCandle;
  final bool updatedExistingCandle;

  const ChartLiveUpdateResult({
    required this.state,
    this.appendedNewCandle = false,
    this.updatedExistingCandle = false,
  });
}

@internal
class ChartLiveUpdateCoordinator {
  final ChartViewportPolicy viewportPolicy;

  const ChartLiveUpdateCoordinator(this.viewportPolicy);

  ChartLiveUpdateResult applyTick(
    ChartState state, {
    required int time,
    required double price,
  }) {
    if (state.candles.isEmpty) {
      final candle = Candle(
        time: time,
        open: price,
        high: price,
        low: price,
        close: price,
      );

      return ChartLiveUpdateResult(
        state: _replaceCandles(state, [candle]),
        appendedNewCandle: true,
      );
    }

    final last = state.candles.last;
    if (last.time == time) {
      return updateLastCandle(state, last.updateWithTick(price));
    }

    final newCandle = Candle(
      time: time,
      open: last.close,
      high: last.close > price ? last.close : price,
      low: last.close < price ? last.close : price,
      close: price,
    );
    return appendCandle(state, newCandle);
  }

  ChartLiveUpdateResult appendCandle(ChartState state, Candle candle) {
    return ChartLiveUpdateResult(
      state: _replaceCandles(state, [...state.candles, candle]),
      appendedNewCandle: true,
    );
  }

  ChartLiveUpdateResult updateLastCandle(ChartState state, Candle candle) {
    if (state.candles.isEmpty) {
      return ChartLiveUpdateResult(
        state: _replaceCandles(state, [candle]),
        appendedNewCandle: true,
      );
    }

    final nextCandles = [...state.candles];
    nextCandles[nextCandles.length - 1] = candle;
    return ChartLiveUpdateResult(
      state: _replaceCandles(state, nextCandles),
      updatedExistingCandle: true,
    );
  }

  ChartState _replaceCandles(ChartState state, List<Candle> candles) {
    final viewport = _resolveViewportAfterDataChange(
      state: state,
      newTotalCount: candles.length,
    );

    return state.copyWith(
      candles: List.unmodifiable(candles),
      viewport: viewport,
      version: state.version + 1,
    );
  }

  ChartViewport _resolveViewportAfterDataChange({
    required ChartState state,
    required int newTotalCount,
  }) {
    if (newTotalCount == 0) {
      return ChartViewport(
        startIndex: 0,
        visibleCount: viewportPolicy.defaultVisibleCount,
        totalCount: 0,
      );
    }

    if (state.followLatest ||
        state.viewport.endIndex >= (state.viewport.totalCount - 1)) {
      final visibleCount = viewportPolicy.clampVisibleCount(
        state.viewport.visibleCount,
        newTotalCount,
      );
      return ChartViewport.last(visibleCount, newTotalCount);
    }

    final visibleCount = viewportPolicy.clampVisibleCount(
      state.viewport.visibleCount,
      newTotalCount,
    );
    final maxStart = (newTotalCount - visibleCount).clamp(0, newTotalCount);
    final startIndex = state.viewport.startIndex.clamp(0, maxStart);

    return ChartViewport(
      startIndex: startIndex,
      visibleCount: visibleCount,
      totalCount: newTotalCount,
    );
  }
}
