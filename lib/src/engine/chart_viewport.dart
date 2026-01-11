import 'package:flutter/foundation.dart' show immutable;

/// ─────────────────────────────────────────────────────────────
/// 🪟 ChartViewport
/// ─────────────────────────────────────────────────────────────
///
/// Defines which subset of candles is currently visible on screen.
///
/// This is the **most critical performance component** of the chart engine.
///
/// PERFORMANCE GUARANTEE:
/// - The chart NEVER renders more candles than required
/// - All rendering, scaling, and mapping operate ONLY on visible candles
///
/// This ensures:
/// - O(visibleCount) rendering cost
/// - Smooth performance even with very large datasets (100k+ candles)
///
/// ---
///
/// ### Mental model
///
/// Think of the full candle list as a long horizontal strip.
/// The viewport is a sliding window over that strip:
///
/// ```
/// |-----------------------------------------------|  (all candles)
///                  |-----------|                   (viewport)
///                startIndex   endIndex
/// ```
///
/// All chart operations (pan, zoom, scale) operate by
/// modifying this window — never the underlying data.
@immutable
class ChartViewport {
  /// Index of the FIRST visible candle (inclusive).
  ///
  /// Must satisfy:
  /// - startIndex >= 0
  /// - startIndex <= totalCount
  final int startIndex;

  /// Number of candles visible in the viewport.
  ///
  /// Must satisfy:
  /// - visibleCount >= 1
  /// - startIndex + visibleCount <= totalCount (after clamping)
  final int visibleCount;

  /// Total number of candles in the dataset.
  ///
  /// This allows viewport math without needing the full data list.
  final int totalCount;

  const ChartViewport({
    required this.startIndex,
    required this.visibleCount,
    required this.totalCount,
  });

  // ─────────────────────────────────────────────────────────
  // 🏭 Factory constructors
  // ─────────────────────────────────────────────────────────

  /// Create a viewport showing the **last N candles** (right-aligned).
  ///
  /// Commonly used for:
  /// - Initial chart load
  /// - Resetting viewport
  /// - Auto-scroll on live updates
  factory ChartViewport.last(int visibleCount, int totalCount) {
    // Start index is clamped to avoid underflow
    final start = (totalCount - visibleCount).clamp(0, totalCount);

    return ChartViewport(
      startIndex: start,
      // Visible count is clamped to remaining candles
      visibleCount: visibleCount.clamp(1, totalCount - start),
      totalCount: totalCount,
    );
  }

  /// Create a viewport that shows ALL candles.
  ///
  /// Equivalent to zooming out to fit entire dataset.
  factory ChartViewport.fitAll(int totalCount) {
    return ChartViewport(
      startIndex: 0,
      visibleCount: totalCount,
      totalCount: totalCount,
    );
  }

  /// Create a modified copy of this viewport.
  ///
  /// Used to preserve immutability when panning or zooming.
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

  // ─────────────────────────────────────────────────────────
  // 👉 Viewport operations
  // ─────────────────────────────────────────────────────────

  /// Pan the viewport horizontally by a number of candles.
  ///
  /// - Positive delta → pan right (older candles)
  /// - Negative delta → pan left (newer candles)
  ///
  /// Clamping ensures viewport never exceeds dataset bounds.
  ChartViewport pan(int delta) {
    final newStart = (startIndex + delta).clamp(
      0,
      (totalCount - visibleCount).clamp(0, totalCount),
    );

    return copyWith(startIndex: newStart);
  }

  /// Zoom viewport by adjusting visible candle count.
  ///
  /// - Positive delta → zoom IN (fewer candles)
  /// - Negative delta → zoom OUT (more candles)
  ///
  /// Zoom is CENTER-BASED.
  ChartViewport zoom(
    int delta, {
    int minVisible = 5,
    int maxVisible = 1000,
  }) {
    final newVisible = (visibleCount + delta).clamp(
      minVisible,
      maxVisible.clamp(minVisible, totalCount),
    );

    // Clamp start index so viewport remains valid
    final maxStart = (totalCount - newVisible).clamp(0, totalCount);
    final newStart = startIndex.clamp(0, maxStart);

    return copyWith(
      visibleCount: newVisible,
      startIndex: newStart,
    );
  }

  /// Zoom viewport around a specific anchor candle index.
  ///
  /// This ensures the candle under the user's finger
  /// stays at the same relative screen position.
  ///
  /// Used for pinch-to-zoom interactions.
  ChartViewport zoomAround(
    int anchorIndex,
    int delta, {
    int minVisible = 5,
    int maxVisible = 1000,
  }) {
    final newVisible = (visibleCount + delta).clamp(
      minVisible,
      maxVisible.clamp(minVisible, totalCount),
    );

    // Ratio of anchor within current viewport
    final ratio = (anchorIndex - startIndex) / visibleCount;

    // Compute new start index to preserve anchor position
    final newStart = (anchorIndex - (newVisible * ratio).round()).clamp(
      0,
      (totalCount - newVisible).clamp(0, totalCount),
    );

    return copyWith(
      visibleCount: newVisible,
      startIndex: newStart,
    );
  }

  // ─────────────────────────────────────────────────────────
  // 📐 Derived properties
  // ─────────────────────────────────────────────────────────

  /// End index of visible candles (exclusive).
  ///
  /// Equivalent to: startIndex + visibleCount
  int get endIndex => (startIndex + visibleCount).clamp(0, totalCount);

  /// Whether viewport can pan left (towards older candles).
  bool get canPanLeft => startIndex > 0;

  /// Whether viewport can pan right (towards newer candles).
  bool get canPanRight => endIndex < totalCount;

  /// Range representing visible candle indices.
  ///
  /// Used for iteration and slicing.
  Range get visibleRange => Range(startIndex, endIndex);

  // ─────────────────────────────────────────────────────────
  // ⚖ Equality
  // ─────────────────────────────────────────────────────────
  //
  // Viewports are value objects.
  // Equality is structural, not referential.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartViewport &&
          runtimeType == other.runtimeType &&
          startIndex == other.startIndex &&
          visibleCount == other.visibleCount &&
          totalCount == other.totalCount;

  @override
  int get hashCode =>
      startIndex.hashCode ^ visibleCount.hashCode ^ totalCount.hashCode;
}

/// ─────────────────────────────────────────────────────────────
/// 📏 Range
/// ─────────────────────────────────────────────────────────────
///
/// Lightweight helper representing an integer index range.
///
/// Used to:
/// - Describe visible candle bounds
/// - Iterate efficiently without allocations
@immutable
class Range {
  final int start;
  final int end;

  const Range(this.start, this.end);

  /// Whether index lies within the range [start, end).
  bool contains(int index) => index >= start && index < end;

  /// Length of the range.
  int get length => end - start;

  /// Lazy iterator over indices.
  ///
  /// Avoids creating intermediate lists.
  Iterable<int> get indices sync* {
    for (int i = start; i < end; i++) {
      yield i;
    }
  }
}
