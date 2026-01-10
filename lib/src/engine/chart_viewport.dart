/// Viewport system that controls which candles are visible on screen.
/// 
/// This is the CRITICAL component for performance - the chart only renders
/// candles within the viewport, never more than screen pixels.
class ChartViewport {
  /// Index of the first visible candle in the data array
  final int startIndex;

  /// Number of candles visible on screen
  final int visibleCount;

  /// Total number of candles in the dataset
  final int totalCount;

  const ChartViewport({
    required this.startIndex,
    required this.visibleCount,
    required this.totalCount,
  });

  /// Creates a viewport showing the last N candles (right-aligned)
  factory ChartViewport.last(int visibleCount, int totalCount) {
    final start = (totalCount - visibleCount).clamp(0, totalCount);
    return ChartViewport(
      startIndex: start,
      visibleCount: visibleCount.clamp(1, totalCount - start),
      totalCount: totalCount,
    );
  }

  /// Creates a viewport showing all candles (zoom out to fit)
  factory ChartViewport.fitAll(int totalCount) {
    return ChartViewport(
      startIndex: 0,
      visibleCount: totalCount,
      totalCount: totalCount,
    );
  }

  /// Creates a copy with updated values
  ChartViewport copyWith({
    int? startIndex,
    int? visibleCount,
    int? totalCount,
  }) {
    return ChartViewport(
      startIndex: startIndex ?? this.startIndex,
      visibleCount: visibleCount ?? this.visibleCount,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  /// Pan viewport by a number of candles (positive = right, negative = left)
  ChartViewport pan(int delta) {
    final newStart = (startIndex + delta).clamp(0, (totalCount - visibleCount).clamp(0, totalCount));
    return copyWith(startIndex: newStart);
  }

  /// Zoom by changing visible count (positive = zoom in, negative = zoom out)
  ChartViewport zoom(int delta, {int minVisible = 5, int maxVisible = 1000}) {
    final newVisible = (visibleCount + delta).clamp(minVisible, maxVisible.clamp(minVisible, totalCount));
    // Keep the same start index if possible, but clamp if needed
    final maxStart = (totalCount - newVisible).clamp(0, totalCount);
    final newStart = startIndex.clamp(0, maxStart);
    return copyWith(
      visibleCount: newVisible,
      startIndex: newStart,
    );
  }

  /// Zoom around a specific index (anchor point)
  ChartViewport zoomAround(int anchorIndex, int delta, {int minVisible = 5, int maxVisible = 1000}) {
    final newVisible = (visibleCount + delta).clamp(minVisible, maxVisible.clamp(minVisible, totalCount));
    // Calculate new start to keep anchor index at same screen position
    final ratio = (anchorIndex - startIndex) / visibleCount;
    final newStart = (anchorIndex - (newVisible * ratio).round()).clamp(0, (totalCount - newVisible).clamp(0, totalCount));
    return copyWith(
      visibleCount: newVisible,
      startIndex: newStart,
    );
  }

  /// Get the index range of visible candles [start, end)
  int get endIndex => (startIndex + visibleCount).clamp(0, totalCount);
  
  /// Whether we can pan left
  bool get canPanLeft => startIndex > 0;
  
  /// Whether we can pan right
  bool get canPanRight => endIndex < totalCount;
  
  /// Get visible index range for iteration
  Range get visibleRange => Range(startIndex, endIndex);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartViewport &&
          runtimeType == other.runtimeType &&
          startIndex == other.startIndex &&
          visibleCount == other.visibleCount &&
          totalCount == other.totalCount;

  @override
  int get hashCode => startIndex.hashCode ^ visibleCount.hashCode ^ totalCount.hashCode;
}

/// Simple range helper
class Range {
  final int start;
  final int end;
  
  const Range(this.start, this.end);
  
  bool contains(int index) => index >= start && index < end;
  
  int get length => end - start;
  
  Iterable<int> get indices sync* {
    for (int i = start; i < end; i++) {
      yield i;
    }
  }
}