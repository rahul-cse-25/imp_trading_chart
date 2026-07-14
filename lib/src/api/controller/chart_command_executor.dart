import 'package:meta/meta.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart' show Candle;
import 'package:imp_trading_chart/src/api/controller/chart_interaction_state.dart';
import 'package:imp_trading_chart/src/api/controller/chart_live_view_policy.dart';
import 'package:imp_trading_chart/src/api/controller/chart_live_update_coordinator.dart';
import 'package:imp_trading_chart/src/api/controller/chart_state.dart';
import 'package:imp_trading_chart/src/api/controller/chart_viewport_policy.dart';
import 'package:imp_trading_chart/src/engine/chart_viewport.dart';

@internal
class ChartCommandExecutor {
  final ChartViewportPolicy viewportPolicy;
  final ChartLiveUpdateCoordinator liveUpdateCoordinator;
  final ChartLiveViewPolicy liveViewPolicy;

  const ChartCommandExecutor({
    required this.viewportPolicy,
    required this.liveUpdateCoordinator,
    required this.liveViewPolicy,
  });

  ChartState setCandles(ChartState state, List<Candle> candles) {
    final List<Candle> newCandles = List<Candle>.unmodifiable(candles);
    final newTotalCount = newCandles.length;

    if (newTotalCount == 0) {
      return state.copyWith(
        candles: const <Candle>[],
        viewport: ChartViewport(
          startIndex: 0,
          visibleCount: viewportPolicy.defaultVisibleCount,
          totalCount: 0,
        ),
        interaction: ChartInteractionState.empty,
        version: state.version + 1,
      );
    }

    final firstChanged = state.candles.isEmpty ||
        state.candles.first.time != newCandles.first.time;
    final visibleCount = viewportPolicy.clampVisibleCount(
      state.viewport.visibleCount,
      newTotalCount,
    );

    final viewport = firstChanged
        ? ChartViewport.last(
            viewportPolicy.resolveDefaultVisibleCount(newTotalCount),
            newTotalCount,
          )
        : _resolveViewportForDataReplacement(
            state: state,
            newTotalCount: newTotalCount,
            visibleCount: visibleCount,
          );

    return state.copyWith(
      candles: newCandles,
      viewport: viewport,
      followLatest: liveViewPolicy.shouldAutoFollow(viewport, newTotalCount),
      interaction: _sanitizeInteraction(
        interaction: state.interaction,
        candles: newCandles,
        viewport: viewport,
      ),
      version: state.version + 1,
    );
  }

  ChartState panByCandles(ChartState state, int delta) {
    final viewport = state.viewport.pan(delta);
    return _replaceViewport(state, viewport);
  }

  ChartState zoom(ChartState state, int delta) {
    final viewport = state.viewport.zoom(
      delta,
      minVisible: viewportPolicy.minVisibleCount,
      maxVisible: viewportPolicy.maxVisibleCount,
    );
    return _replaceViewport(state, viewport);
  }

  ChartState zoomAround(ChartState state, int anchorIndex, int delta) {
    final viewport = state.viewport.zoomAround(
      anchorIndex,
      delta,
      minVisible: viewportPolicy.minVisibleCount,
      maxVisible: viewportPolicy.maxVisibleCount,
    );
    return _replaceViewport(state, viewport);
  }

  ChartState resetViewport(ChartState state) {
    final viewport = ChartViewport.last(
      viewportPolicy.resolveDefaultVisibleCount(state.candles.length),
      state.candles.length,
    );
    return _replaceViewport(state, viewport);
  }

  ChartState fitAll(ChartState state) {
    final total = state.candles.length;
    final viewport = total == 0
        ? ChartViewport(
            startIndex: 0,
            visibleCount: viewportPolicy.defaultVisibleCount,
            totalCount: 0,
          )
        : ChartViewport.fitAll(total);
    return _replaceViewport(state, viewport);
  }

  ChartState scrollToLatest(ChartState state) {
    final total = state.candles.length;
    if (total == 0) return state;
    final visible = viewportPolicy.clampVisibleCount(
      state.viewport.visibleCount,
      total,
    );
    return _replaceViewport(state, ChartViewport.last(visible, total));
  }

  ChartState jumpToRange(
    ChartState state, {
    required int startIndex,
    required int visibleCount,
  }) {
    final total = state.candles.length;
    if (total == 0) return state;

    final clampedVisible = viewportPolicy.clampVisibleCount(visibleCount, total);
    final maxStart = (total - clampedVisible).clamp(0, total);
    final clampedStart = startIndex.clamp(0, maxStart);
    return _replaceViewport(
      state,
      ChartViewport(
        startIndex: clampedStart,
        visibleCount: clampedVisible,
        totalCount: total,
      ),
    );
  }

  ChartState selectAtIndex(ChartState state, int absoluteIndex) {
    if (absoluteIndex < 0 || absoluteIndex >= state.candles.length) {
      return clearSelection(state);
    }

    return state.copyWith(
      interaction: state.interaction.select(
        absoluteIndex: absoluteIndex,
        candle: state.candles[absoluteIndex],
      ),
      version: state.version + 1,
    );
  }

  ChartState clearSelection(ChartState state) {
    if (!state.interaction.hasSelection) {
      return state;
    }

    return state.copyWith(
      interaction: ChartInteractionState.empty,
      version: state.version + 1,
    );
  }

  ChartState setFollowLatest(ChartState state, bool enabled) {
    final nextState = state.copyWith(
      followLatest: enabled,
      version: state.version + 1,
    );
    return enabled ? scrollToLatest(nextState) : nextState;
  }

  ChartLiveUpdateResult applyTick(
    ChartState state, {
    required int time,
    required double price,
  }) {
    return liveUpdateCoordinator.applyTick(state, time: time, price: price);
  }

  ChartLiveUpdateResult appendCandle(ChartState state, Candle candle) {
    return liveUpdateCoordinator.appendCandle(state, candle);
  }

  ChartLiveUpdateResult updateLastCandle(ChartState state, Candle candle) {
    return liveUpdateCoordinator.updateLastCandle(state, candle);
  }

  ChartState _replaceViewport(ChartState state, ChartViewport viewport) {
    if (viewport == state.viewport) {
      return state;
    }

    return state.copyWith(
      viewport: viewport,
      followLatest:
          liveViewPolicy.shouldAutoFollow(viewport, state.candles.length),
      interaction: _sanitizeInteraction(
        interaction: state.interaction,
        candles: state.candles,
        viewport: viewport,
      ),
      version: state.version + 1,
    );
  }

  ChartViewport _resolveViewportForDataReplacement({
    required ChartState state,
    required int newTotalCount,
    required int visibleCount,
  }) {
    if (state.followLatest ||
        liveViewPolicy.shouldAutoFollow(
          state.viewport,
          state.viewport.totalCount,
        )) {
      return ChartViewport.last(visibleCount, newTotalCount);
    }

    final maxStart = (newTotalCount - visibleCount).clamp(0, newTotalCount);
    final startIndex = state.viewport.startIndex.clamp(0, maxStart);

    return ChartViewport(
      startIndex: startIndex,
      visibleCount: visibleCount,
      totalCount: newTotalCount,
    );
  }

  ChartInteractionState _sanitizeInteraction({
    required ChartInteractionState interaction,
    required List<Candle> candles,
    required ChartViewport viewport,
  }) {
    final selectedAbsoluteIndex = interaction.selectedAbsoluteIndex;
    if (selectedAbsoluteIndex == null ||
        selectedAbsoluteIndex < 0 ||
        selectedAbsoluteIndex >= candles.length ||
        !viewport.visibleRange.contains(selectedAbsoluteIndex)) {
      return ChartInteractionState.empty;
    }

    return interaction.select(
      absoluteIndex: selectedAbsoluteIndex,
      candle: candles[selectedAbsoluteIndex],
    );
  }
}
