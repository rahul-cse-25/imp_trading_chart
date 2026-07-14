import 'package:flutter/foundation.dart';
import 'package:imp_trading_chart/src/engine/chart_viewport.dart';

enum ChartFollowLatestState {
  followingLatest,
  detachedNearLatest,
  detachedHistorical,
}

@immutable
class ChartLiveViewPolicy {
  final int nearLatestThreshold;

  const ChartLiveViewPolicy({
    this.nearLatestThreshold = 3,
  }) : assert(nearLatestThreshold >= 0);

  bool isNearLatest(ChartViewport viewport, int totalCount) {
    if (totalCount <= 0) return true;
    return viewport.endIndex >= (totalCount - nearLatestThreshold);
  }

  bool shouldAutoFollow(ChartViewport viewport, int totalCount) {
    return isNearLatest(viewport, totalCount);
  }

  ChartFollowLatestState classify({
    required bool followLatest,
    required ChartViewport viewport,
    required int totalCount,
  }) {
    if (followLatest) {
      return ChartFollowLatestState.followingLatest;
    }

    if (isNearLatest(viewport, totalCount)) {
      return ChartFollowLatestState.detachedNearLatest;
    }

    return ChartFollowLatestState.detachedHistorical;
  }
}
