import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart' show Candle;
import 'package:imp_trading_chart/src/api/controller/chart_command_executor.dart';
import 'package:imp_trading_chart/src/api/controller/chart_events.dart';
import 'package:imp_trading_chart/src/api/controller/chart_live_view_policy.dart';
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
  final ChartLiveViewPolicy _liveViewPolicy;
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
        _liveViewPolicy = const ChartLiveViewPolicy(),
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
            viewportPolicy: ChartViewportPolicy(
              defaultVisibleCount: defaultVisibleCount,
              minVisibleCount: minVisibleCount,
              maxVisibleCount: maxVisibleCount,
            ),
            liveViewPolicy: const ChartLiveViewPolicy(),
          ),
          liveViewPolicy: const ChartLiveViewPolicy(),
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
      candles: List<Candle>.unmodifiable(candles),
      visibleCandles: List<Candle>.unmodifiable(engine.getVisibleCandles()),
      viewport: viewport,
      visibleRange: visibleRange,
      selection: selection,
      followLatest: isFollowingLatest,
      followLatestState: followLatestState,
      latestPrice: engine.getLatestPrice(),
    );
  }

  bool get isFollowingLatest => _stateStore.state.followLatest;
  ChartFollowLatestState get followLatestState => _liveViewPolicy.classify(
        followLatest: _stateStore.state.followLatest,
        viewport: _stateStore.state.viewport,
        totalCount: _stateStore.state.candles.length,
      );
  bool get hasSelection => selection != null;
  int get defaultVisibleCount => _viewportPolicy.defaultVisibleCount;
  int get minVisibleCount => _viewportPolicy.minVisibleCount;
  int get maxVisibleCount => _viewportPolicy.maxVisibleCount;
  int get nearLatestThreshold => _liveViewPolicy.nearLatestThreshold;

  @internal
  ChartEngine get engine => _engine;

  void bindCandles(List<Candle> candles) => setCandles(candles);

  void setCandles(List<Candle> candles) {
    final previousState = _stateStore.state;
    final nextState = _commandExecutor.setCandles(previousState, candles);
    _applyState(
      nextState,
      _resolveSetCandlesEvent(previousState, nextState),
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
      const ChartEvent(ChartEventType.viewportChanged,
          reason: 'scrollToLatest'),
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
      const ChartEvent(ChartEventType.selectionChanged,
          reason: 'clearSelection'),
    );
  }

  void applyTick({
    required int time,
    required double price,
  }) {
    final previousState = _stateStore.state;
    final result = _commandExecutor.applyTick(
      previousState,
      time: time,
      price: price,
    );

    _applyState(
      result.state,
      _resolveLiveUpdateEvent(
        nextState: result.state,
        reason: 'applyTick',
        appended: result.appendedNewCandle,
      ),
    );
  }

  void appendCandle(Candle candle) {
    final previousState = _stateStore.state;
    final result = _commandExecutor.appendCandle(previousState, candle);
    _applyState(
      result.state,
      _resolveLiveUpdateEvent(
        nextState: result.state,
        reason: 'appendCandle',
        appended: true,
      ),
    );
  }

  void updateLastCandle(Candle candle) {
    final previousState = _stateStore.state;
    final result = _commandExecutor.updateLastCandle(previousState, candle);
    _applyState(
      result.state,
      _resolveLiveUpdateEvent(
        nextState: result.state,
        reason: 'updateLastCandle',
        appended: false,
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
    if (identical(nextState, _stateStore.state) ||
        nextState == _stateStore.state) {
      return;
    }

    _stateStore.replace(nextState);
    _events.add(event);
    notifyListeners();
  }

  ChartEvent _resolveSetCandlesEvent(
    ChartState previousState,
    ChartState nextState,
  ) {
    final previousCandles = previousState.candles;
    final nextCandles = nextState.candles;
    final sameSeries = previousCandles.isNotEmpty &&
        nextCandles.isNotEmpty &&
        previousCandles.first.time == nextCandles.first.time;

    if (sameSeries && nextCandles.length > previousCandles.length) {
      if (nextState.followLatest) {
        return const ChartEvent(
          ChartEventType.liveCandleAppended,
          reason: 'setCandles',
        );
      }

      return const ChartEvent(
        ChartEventType.liveUpdatePreservedContext,
        reason: 'setCandles',
      );
    }

    if (sameSeries &&
        nextCandles.length == previousCandles.length &&
        nextCandles.isNotEmpty &&
        previousCandles.isNotEmpty &&
        nextCandles.last != previousCandles.last) {
      if (nextState.followLatest) {
        return const ChartEvent(
          ChartEventType.liveCandleUpdated,
          reason: 'setCandles',
        );
      }

      return const ChartEvent(
        ChartEventType.liveUpdatePreservedContext,
        reason: 'setCandles',
      );
    }

    return const ChartEvent(
      ChartEventType.dataSet,
      reason: 'setCandles',
    );
  }

  ChartEvent _resolveLiveUpdateEvent({
    required ChartState nextState,
    required String reason,
    required bool appended,
  }) {
    if (!nextState.followLatest) {
      return ChartEvent(
        ChartEventType.liveUpdatePreservedContext,
        reason: reason,
      );
    }

    return ChartEvent(
      appended
          ? ChartEventType.liveCandleAppended
          : ChartEventType.liveCandleUpdated,
      reason: reason,
    );
  }
}
