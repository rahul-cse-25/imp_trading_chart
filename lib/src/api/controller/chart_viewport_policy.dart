import 'package:meta/meta.dart';

@immutable
class ChartViewportPolicy {
  final int defaultVisibleCount;
  final int minVisibleCount;
  final int maxVisibleCount;

  const ChartViewportPolicy({
    required this.defaultVisibleCount,
    required this.minVisibleCount,
    required this.maxVisibleCount,
  }) : assert(defaultVisibleCount > 0),
       assert(minVisibleCount > 0),
       assert(maxVisibleCount >= minVisibleCount);

  int resolveDefaultVisibleCount(int totalCount) {
    if (totalCount <= 0) {
      return defaultVisibleCount;
    }
    return defaultVisibleCount.clamp(minVisibleCount, totalCount);
  }

  int clampVisibleCount(int requested, int totalCount) {
    if (totalCount <= 0) {
      return requested.clamp(minVisibleCount, maxVisibleCount);
    }

    final upperBound = maxVisibleCount.clamp(minVisibleCount, totalCount);
    return requested.clamp(minVisibleCount, upperBound);
  }
}
