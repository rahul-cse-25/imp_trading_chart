import 'package:flutter/foundation.dart';

enum ChartEventType {
  dataSet,
  viewportChanged,
  selectionChanged,
  followLatestChanged,
  liveTickApplied,
  liveCandleAppended,
  liveCandleUpdated,
  liveUpdatePreservedContext,
  reset,
}

/// Public event emitted by [ImpChartController] for observational integrations.
@immutable
class ChartEvent {
  final ChartEventType type;
  final String? reason;

  const ChartEvent(this.type, {this.reason});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(type, reason);
}
