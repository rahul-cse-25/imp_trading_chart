import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart' show Candle;
import 'package:imp_trading_chart/src/api/controller/chart_command_executor.dart';
import 'package:imp_trading_chart/src/api/controller/chart_events.dart';
import 'package:imp_trading_chart/src/api/controller/chart_live_update_coordinator.dart';
import 'package:imp_trading_chart/src/api/controller/chart_snapshots.dart';
import 'package:imp_trading_chart/src/api/controller/chart_state.dart';
import 'package:imp_trading_chart/src/api/controller/chart_state_store.dart';
import 'package:imp_trading_chart/src/api/controller/chart_viewport_policy.dart';
import 'package:imp_trading_chart/src/api/controller/chart_interaction_state.dart';
import 'package:imp_trading_chart/src/engine/chart_engine.dart';
import 'package:imp_trading_chart/src/engine/chart_viewport.dart';

/// Public orchestration API for programmatic chart control.
class ImpChartController extends ChangeNotifier {
  final ChartViewportPolicy _viewportPolicy;
  final ChartStateStore _stateStore;
  final ChartCommandExecutor _commandExecutor;
  final StreamController<ChartEvent> _events =
      StreamController<ChartEvent>.broadcast();

  ImpChartController({
    int defaultVisibleCount = 100,
    int minVisibleCount = 5,
    int maxVisibleCount = 1000,
    bool followLatest = true,
    List<Candle> candles = const [],
  })  : _viewportPolicy = ChartViewportPolicy(
          defaultVisibleCount: defaultVisibleCount,
          minVisibleCount: minVisibleCount,
          maxVisibleCount: maxVisibleCount,
        ),
        _stateStore = ChartStateStore(
          ChartState(
            candles: List.unmodifiable(candles),
            viewport: candles.isEmpty
                ? ChartViewport(
                    startIndex: 0,
                    visibleCount: defaultVisibleCount,
                    totalCount: 0,
                  )
                : ChartViewport.last(
                    defaultVisibleCount.clamp(1, candles.length),
                    candles.length,
                  ),
            interaction: ChartInteractionState.empty,
            followLatest: followLatest,
            version: 0,
          ),
        ),
        _commandExecutor = ChartCommandExecutor(
          viewportPolicy: ChartViewportPolicy(
            defaultVisibleCount: defaultVisibleCount,
            minVisibleCount: minVisibleCount,
            maxVisibleCount: maxVisibleCount,
          ),
          liveUpdateCoordinator: ChartLiveUpdateCoordinator(
            ChartViewportPolicy(
              defaultVisibleCount: defaultVisibleCount,
              minVisibleCount: minVisibleCount,
              maxVisibleCount: maxVisibleCount,
            ),
          ),
        );

  Stream<ChartEvent> get events => _events.stream;

  List<Candle> get candles => _stateStore.state.candles;

  ChartViewportSnapshot get viewport {
    final current = _stateStore.state.viewport;
    return ChartViewportSnapshot(
      startIndex: current.startIndex,
      visibleCount: current.visibleCount,
      endIndex: current.endIndex,
      totalCount: current.totalCount,
    );
  }

  ChartVisibleRange get visibleRange {
    final current = _stateStore.state.viewport.visibleRange;
    return ChartVisibleRange(
      startIndex: current.start,
      endIndex: current.end,
      length: current.length,
    );
  }

  ChartSelectionSnapshot? get selection {
    final state = _stateStore.state;
    final absoluteIndex = state.interaction.selectedAbsoluteIndex;
    final candle = state.interaction.selectedCandle;
    if (absoluteIndex == null || candle == null) {
      return null;
    }

    return ChartSelectionSnapshot(
      absoluteIndex: absoluteIndex,
      visibleIndex: absoluteIndex - state.viewport.startIndex,
      candle: candle,
    );
  }

  ChartRenderSnapshot get snapshot {
    final engine = _engine;
    return ChartRenderSnapshot(
      candles: candles,
      visibleCandles: engine.getVisibleCandles(),
      viewport: viewport,
      visibleRange: visibleRange,
      selection: selection,
      followLatest: isFollowingLatest,
      latestPrice: engine.getLatestPrice(),
    );
  }

  bool get isFollowingLatest => _stateStore.state.followLatest;
  bool get hasSelection => selection != null;
  int get defaultVisibleCount => _viewportPolicy.defaultVisibleCount;
  int get minVisibleCount => _viewportPolicy.minVisibleCount;
  int get maxVisibleCount => _viewportPolicy.maxVisibleCount;

  @internal
  ChartEngine get engine => _engine;

  void bindCandles(List<Candle> candles) => setCandles(candles);

  void setCandles(List<Candle> candles) {
    _applyState(
      _commandExecutor.setCandles(_stateStore.state, candles),
      const ChartEvent(
        ChartEventType.dataSet,
        reason: 'setCandles',
      ),
    );
  }

  void panByCandles(int delta) {
    _applyState(
      _commandExecutor.panByCandles(_stateStore.state, delta),
      const ChartEvent(ChartEventType.viewportChanged, reason: 'pan'),
    );
  }

  void zoomIn({int step = 1}) {
    _applyState(
      _commandExecutor.zoom(_stateStore.state, -step.abs()),
      const ChartEvent(ChartEventType.viewportChanged, reason: 'zoomIn'),
    );
  }

  void zoomOut({int step = 1}) {
    _applyState(
      _commandExecutor.zoom(_stateStore.state, step.abs()),
      const ChartEvent(ChartEventType.viewportChanged, reason: 'zoomOut'),
    );
  }

  void zoomAround(int anchorIndex, {int step = 1}) {
    _applyState(
      _commandExecutor.zoomAround(
        _stateStore.state,
        anchorIndex,
        step,
      ),
      const ChartEvent(ChartEventType.viewportChanged, reason: 'zoomAround'),
    );
  }

  void resetViewport() {
    _applyState(
      _commandExecutor.resetViewport(_stateStore.state),
      const ChartEvent(ChartEventType.reset, reason: 'resetViewport'),
    );
  }

  void fitAll() {
    _applyState(
      _commandExecutor.fitAll(_stateStore.state),
      const ChartEvent(ChartEventType.viewportChanged, reason: 'fitAll'),
    );
  }

  void scrollToLatest() {
    _applyState(
      _commandExecutor.scrollToLatest(_stateStore.state),
      const ChartEvent(ChartEventType.viewportChanged, reason: 'scrollToLatest'),
    );
  }

  void jumpToRange({
    required int startIndex,
    required int visibleCount,
  }) {
    _applyState(
      _commandExecutor.jumpToRange(
        _stateStore.state,
        startIndex: startIndex,
        visibleCount: visibleCount,
      ),
      const ChartEvent(ChartEventType.viewportChanged, reason: 'jumpToRange'),
    );
  }

  void showCrosshairAtIndex(int absoluteIndex) {
    _applyState(
      _commandExecutor.selectAtIndex(_stateStore.state, absoluteIndex),
      const ChartEvent(
        ChartEventType.selectionChanged,
        reason: 'showCrosshairAtIndex',
      ),
    );
  }

  void hideCrosshair() => clearSelection();

  void clearSelection() {
    _applyState(
      _commandExecutor.clearSelection(_stateStore.state),
      const ChartEvent(ChartEventType.selectionChanged, reason: 'clearSelection'),
    );
  }

  void applyTick({
    required int time,
    required double price,
  }) {
    final result = _commandExecutor.applyTick(
      _stateStore.state,
      time: time,
      price: price,
    );

    _applyState(
      result.state,
      ChartEvent(
        result.appendedNewCandle
            ? ChartEventType.liveCandleAppended
            : ChartEventType.liveCandleUpdated,
        reason: 'applyTick',
      ),
    );
  }

  void appendCandle(Candle candle) {
    final result = _commandExecutor.appendCandle(_stateStore.state, candle);
    _applyState(
      result.state,
      const ChartEvent(
        ChartEventType.liveCandleAppended,
        reason: 'appendCandle',
      ),
    );
  }

  void updateLastCandle(Candle candle) {
    final result = _commandExecutor.updateLastCandle(_stateStore.state, candle);
    _applyState(
      result.state,
      const ChartEvent(
        ChartEventType.liveCandleUpdated,
        reason: 'updateLastCandle',
      ),
    );
  }

  void setFollowLatest(bool enabled) {
    _applyState(
      _commandExecutor.setFollowLatest(_stateStore.state, enabled),
      const ChartEvent(
        ChartEventType.followLatestChanged,
        reason: 'setFollowLatest',
      ),
    );
  }

  @override
  void dispose() {
    _events.close();
    super.dispose();
  }

  ChartEngine get _engine {
    final state = _stateStore.state;
    return ChartEngine(
      candles: state.candles,
      initialViewport: state.viewport,
      defaultVisibleCount: _viewportPolicy.defaultVisibleCount,
    );
  }

  void _applyState(ChartState nextState, ChartEvent event) {
    if (identical(nextState, _stateStore.state) || nextState == _stateStore.state) {
      return;
    }

    _stateStore.replace(nextState);
    _events.add(event);
    notifyListeners();
  }
}
