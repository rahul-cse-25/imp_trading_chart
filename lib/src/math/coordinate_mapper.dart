
import 'package:imp_trading_chart/src/engine/chart_viewport.dart' show ChartViewport;
import 'package:imp_trading_chart/src/engine/price_scale.dart' show PriceScale;

/// Coordinate mapping utilities.
/// 
/// All rendering uses these transforms for consistency.
class CoordinateMapper {
    final ChartViewport viewport;
    final PriceScale priceScale;
    final double chartWidth;
    final double chartHeight;
    final double paddingLeft;
    final double paddingRight;
    final double paddingTop;
    final double paddingBottom;

    /// Effective chart area dimensions
    double get contentWidth => chartWidth - paddingLeft - paddingRight;
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

    /// Map candle index to X coordinate
    /// 
    /// x = ((index - startIndex) / visibleCount) * contentWidth + paddingLeft
    /// For single data point, centers it in the content area
    double indexToX(int index) {
        // Special case: if only one candle visible, center it
        if (viewport.visibleCount == 1) {
            return paddingLeft + (contentWidth / 2);
        }

        final relativeIndex = index - viewport.startIndex;
        final normalizedX = relativeIndex / viewport.visibleCount;
        return (normalizedX * contentWidth) + paddingLeft;
    }

    /// Map X coordinate back to candle index
    /// Only considers chart content area (between paddingLeft and paddingLeft + contentWidth)
    /// Snaps to the candle whose center is closest to the touch point
    int xToIndex(double x) {
        // Special case: single visible candle - always return its index
        if (viewport.visibleCount == 1) {
            return viewport.startIndex;
        }

        final relativeX = x - paddingLeft;
        if (relativeX < 0 || relativeX > contentWidth) return -1;

        // Calculate the exact relative position as a fraction of visible candles
        // Each candle occupies candleWidth pixels
        final normalizedX = relativeX / contentWidth;
        final exactRelativeIndex = normalizedX * viewport.visibleCount;

        // Round to snap to nearest candle center
        // This ensures crosshair aligns perfectly with data points
        final relativeIndex = exactRelativeIndex.round();

        final index = viewport.startIndex + relativeIndex;
        return index.clamp(viewport.startIndex, viewport.endIndex - 1);
    }

    /// Map price to Y coordinate (inverted)
    /// 
    /// Includes padding offset
    double priceToY(double price) {
        final y = priceScale.priceToY(price, contentHeight);
        return y + paddingTop;
    }

    /// Map Y coordinate back to price
    double yToPrice(double y) {
        final relativeY = y - paddingTop;
        return priceScale.yToPrice(relativeY, contentHeight);
    }

    /// Get candle width based on visible count
    double get candleWidth => contentWidth / viewport.visibleCount;

    /// Get X position for candle center
    /// 
    /// For single data point, this returns the horizontal center of the content area
    /// (same as indexToX since the single candle is already centered).
    double getCandleCenterX(int index) {
        // Special case: if only one candle visible, it's already centered
        // Don't add half candle width (which would be contentWidth/2 and offset it to the right edge)
        if (viewport.visibleCount == 1) {
            return paddingLeft + (contentWidth / 2);
        }
        return indexToX(index) + (candleWidth / 2);
    }

    /// Get X position for candle left edge
    double getCandleLeftX(int index) {
        return indexToX(index);
    }

    /// Get X position for candle right edge
    double getCandleRightX(int index) {
        return indexToX(index) + candleWidth;
    }

    @override
    bool operator==(Object other) =>
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