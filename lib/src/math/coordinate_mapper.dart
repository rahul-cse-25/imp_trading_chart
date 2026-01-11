import 'package:flutter/foundation.dart' show immutable;
import 'package:imp_trading_chart/src/engine/chart_viewport.dart'
    show ChartViewport;
import 'package:imp_trading_chart/src/engine/price_scale.dart' show PriceScale;

/// ─────────────────────────────────────────────────────────────
/// 📐 CoordinateMapper
/// ─────────────────────────────────────────────────────────────
///
/// Converts **engine-space values** (indices, prices)
/// into **screen-space coordinates** (pixels).
///
/// This class is the **single source of truth** for all
/// coordinate transformations used during rendering.
///
/// PERFORMANCE & CORRECTNESS GUARANTEES:
/// - All painters must use this mapper (no ad-hoc math)
/// - Mapping is pure and deterministic
/// - No allocations during mapping calls
///
/// ---
///
/// ### Coordinate systems involved
///
/// 1. **Data space**
///    - Candle index (integer)
///    - Price (double)
///
/// 2. **Viewport space**
///    - Visible candle window
///    - Price range (min → max)
///
/// 3. **Screen space**
///    - X: left → right
///    - Y: top → bottom (inverted)
///
/// This class bridges all three safely.
@immutable
class CoordinateMapper {
  /// Current viewport describing visible candle range.
  final ChartViewport viewport;

  /// Price scale mapping prices → normalized Y.
  final PriceScale priceScale;

  /// Total width of the chart widget.
  final double chartWidth;

  /// Total height of the chart widget.
  final double chartHeight;

  /// Left padding reserved for Y-axis labels.
  final double paddingLeft;

  /// Right padding (future-proof / spacing).
  final double paddingRight;

  /// Top padding (visual breathing room).
  final double paddingTop;

  /// Bottom padding reserved for X-axis labels.
  final double paddingBottom;

  /// Effective drawable width after removing horizontal padding.
  double get contentWidth => chartWidth - paddingLeft - paddingRight;

  /// Effective drawable height after removing vertical padding.
  double get contentHeight => chartHeight - paddingTop - paddingBottom;

  const CoordinateMapper({
    required this.viewport,
    required this.priceScale,
    required this.chartWidth,
    required this.chartHeight,
    this.paddingLeft = 0.0,
    this.paddingRight = 0.0,
    this.paddingTop = 0.0,
    this.paddingBottom = 0.0,
  });

  // ─────────────────────────────────────────────────────────
  // 🔁 X-axis mapping (index ↔ pixel)
  // ─────────────────────────────────────────────────────────

  /// Convert candle index to X coordinate.
  ///
  /// Formula:
  /// ```
  /// x = ((index - startIndex) / visibleCount) * contentWidth + paddingLeft
  /// ```
  ///
  /// SPECIAL CASE:
  /// - If only one candle is visible, it is centered horizontally.
  double indexToX(int index) {
    // Single-candle case: center it
    if (viewport.visibleCount == 1) {
      return paddingLeft + (contentWidth / 2);
    }

    final relativeIndex = index - viewport.startIndex;
    final normalizedX = relativeIndex / viewport.visibleCount;

    return (normalizedX * contentWidth) + paddingLeft;
  }

  /// Convert X coordinate back to candle index.
  ///
  /// Used for:
  /// - Crosshair
  /// - Touch interactions
  ///
  /// Behavior:
  /// - Only considers drawable chart area
  /// - Snaps to nearest candle center
  int xToIndex(double x) {
    // Single-candle case: always return that candle
    if (viewport.visibleCount == 1) {
      return viewport.startIndex;
    }

    final relativeX = x - paddingLeft;

    // Outside drawable area → invalid
    if (relativeX < 0 || relativeX > contentWidth) return -1;

    // Normalize to [0, visibleCount]
    final normalizedX = relativeX / contentWidth;
    final exactRelativeIndex = normalizedX * viewport.visibleCount;

    // Round to nearest candle center
    final relativeIndex = exactRelativeIndex.round();

    final index = viewport.startIndex + relativeIndex;

    // Clamp to valid visible range
    return index.clamp(
      viewport.startIndex,
      viewport.endIndex - 1,
    );
  }

  // ─────────────────────────────────────────────────────────
  // 🔁 Y-axis mapping (price ↔ pixel)
  // ─────────────────────────────────────────────────────────

  /// Convert price to Y coordinate.
  ///
  /// - Uses inverted Y-axis (higher price → smaller Y)
  /// - Applies top padding offset
  double priceToY(double price) {
    final y = priceScale.priceToY(price, contentHeight);
    return y + paddingTop;
  }

  /// Convert Y coordinate back to price.
  double yToPrice(double y) {
    final relativeY = y - paddingTop;
    return priceScale.yToPrice(
      relativeY,
      contentHeight,
    );
  }

  // ─────────────────────────────────────────────────────────
  // 📏 Candle geometry helpers
  // ─────────────────────────────────────────────────────────

  /// Width of a single candle in pixels.
  double get candleWidth => contentWidth / viewport.visibleCount;

  /// Get X coordinate of candle CENTER.
  ///
  /// Used for:
  /// - Line charts
  /// - Crosshair alignment
  ///
  /// SPECIAL CASE:
  /// - Single candle → centered horizontally
  double getCandleCenterX(int index) {
    if (viewport.visibleCount == 1) {
      return paddingLeft + (contentWidth / 2);
    }
    return indexToX(index) + (candleWidth / 2);
  }

  /// Get X coordinate of candle LEFT edge.
  double getCandleLeftX(int index) {
    return indexToX(index);
  }

  /// Get X coordinate of candle RIGHT edge.
  double getCandleRightX(int index) {
    return indexToX(index) + candleWidth;
  }

  // ─────────────────────────────────────────────────────────
  // ⚖ Equality
  // ─────────────────────────────────────────────────────────
  //
  // CoordinateMapper is a value object.
  // Two mappers are equal if they represent
  // the same mapping configuration.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoordinateMapper &&
          runtimeType == other.runtimeType &&
          viewport == other.viewport &&
          priceScale == other.priceScale &&
          chartWidth == other.chartWidth &&
          chartHeight == other.chartHeight &&
          paddingLeft == other.paddingLeft &&
          paddingRight == other.paddingRight &&
          paddingTop == other.paddingTop &&
          paddingBottom == other.paddingBottom;

  @override
  int get hashCode =>
      viewport.hashCode ^
      priceScale.hashCode ^
      chartWidth.hashCode ^
      chartHeight.hashCode ^
      paddingLeft.hashCode ^
      paddingRight.hashCode ^
      paddingTop.hashCode ^
      paddingBottom.hashCode;
}
