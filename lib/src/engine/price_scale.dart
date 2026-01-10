
import 'package:imp_trading_chart/imp_trading_chart.dart' show Candle;

/// Price scale that maps price values to Y coordinates.
/// 
/// This is calculated ONCE when viewport changes, then cached.
/// Never recalculated during paint().
/// 
/// ## TradingView Lightweight Charts Behavior:
/// - For line/area charts: scale based on close prices only
/// - For candlestick charts: scale based on high/low prices
/// - Auto-scale to fit content with configurable margins
/// - Single data point: center vertically with symmetric padding
class PriceScale {
    final double min;
    final double max;
    final double range;

    const PriceScale({
        required this.min,
        required this.max,
    }) : range = max - min;

    /// Creates a price scale from visible candles using HIGH/LOW prices.
    /// 
    /// Use this for candlestick charts where you need to show the full price range.
    /// For line charts, use [fromCandlesCloseOnly] instead.
    factory PriceScale.fromCandles(
        List<Candle> candles, {
            double paddingPercent = 0.05,
        }) {
        if (candles.isEmpty) {
            return const PriceScale(min: 0.0, max: 100.0);
        }

        double minPrice = candles.first.low;
        double maxPrice = candles.first.high;

        for (final candle in candles) {
            if (candle.low < minPrice) minPrice = candle.low;
            if (candle.high > maxPrice) maxPrice = candle.high;
        }

        return _createWithPadding(minPrice, maxPrice, paddingPercent);
    }

    /// Creates a price scale from visible candles using CLOSE prices only.
    /// 
    /// This is the correct method for LINE charts (like TradingView Lightweight Charts).
    /// The line chart only displays close prices, so the scale should match.
    /// This ensures the line fills the available vertical space properly.
    factory PriceScale.fromCandlesCloseOnly(
        List<Candle> candles, {
            double paddingPercent = 0.05,
        }) {
        if (candles.isEmpty) {
            return const PriceScale(min: 0.0, max: 100.0);
        }

        double minPrice = candles.first.close;
        double maxPrice = candles.first.close;

        for (final candle in candles) {
            if (candle.close < minPrice) minPrice = candle.close;
            if (candle.close > maxPrice) maxPrice = candle.close;
        }

        return _createWithPadding(minPrice, maxPrice, paddingPercent);
    }

    /// Internal helper to create a price scale with proper padding.
    /// 
    /// Handles edge cases like:
    /// - Single data point (centers it vertically)
    /// - Very small price ranges
    /// - Zero price ranges
    static PriceScale _createWithPadding(
        double minPrice,
        double maxPrice,
        double paddingPercent,
    ) {
        final priceRange = maxPrice - minPrice;

        // Handle edge case: when priceRange is 0 or very small (single data point or flat line)
        // Use a minimum padding based on the price value itself to ensure:
        // 1. Labels are visible and readable
        // 2. Single data point is centered vertically
        // 3. The chart looks good with appropriate margins
        double padding;
        if (priceRange <= 0 || (maxPrice > 0 && priceRange < (maxPrice * 0.001))) {
            // If range is 0 or very small, calculate padding to center the data point
            // and provide a visually pleasing range (similar to TradingView)
            final basePrice = maxPrice.abs() > 0 
                ? maxPrice.abs() 
                : (minPrice.abs() > 0 ? minPrice.abs() : 1.0);

            // Use 5% of price value for single data points to create a centered look
            // This ensures the data point appears in the middle, not at an edge
            // Minimum padding of 0.01 for very small prices
            padding = (basePrice * 0.05).clamp(0.01, double.infinity);
        } else {
            // Normal case: use percentage-based padding
            // TradingView uses ~5% margins by default
            padding = priceRange * paddingPercent;
        }

        return PriceScale(
            min: minPrice - padding,
            max: maxPrice + padding,
        );
    }

    /// Map price to Y coordinate (0-1 normalized, inverted)
    /// 
    /// Inverted means: price = max maps to y = 0 (top)
    ///                 price = min maps to y = 1 (bottom)
    double priceToY(double price, double chartHeight) {
        if (range == 0) return chartHeight / 2;
        final normalized = (price - min) / range;
        return chartHeight * (1.0 - normalized);
    }

    /// Map Y coordinate back to price
    double yToPrice(double y, double chartHeight) {
        if (chartHeight == 0) return min;
        final normalized = 1.0 - (y / chartHeight);
        return min + (normalized * range);
    }

    /// Format price for display
    String formatPrice(double price) {
        if (price < 1e-6) {
            return price.toStringAsExponential(1);
        } else if (price < 0.01) {
            return price.toStringAsFixed(6);
        } else if (price < 1) {
            return price.toStringAsFixed(4);
        } else if (price < 1000) {
            return price.toStringAsFixed(2);
        } else {
            return price.toStringAsFixed(2);
        }
    }

    @override
    bool operator==(Object other) =>
    identical(this, other) ||
        other is PriceScale &&
            runtimeType == other.runtimeType &&
            min == other.min &&
            max == other.max;

    @override
    int get hashCode => min.hashCode ^ max.hashCode;
}