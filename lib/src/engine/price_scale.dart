import 'package:flutter/foundation.dart' show immutable;
import 'package:imp_trading_chart/imp_trading_chart.dart' show Candle;

/// ─────────────────────────────────────────────────────────────
/// 📈 PriceScale
/// ─────────────────────────────────────────────────────────────
///
/// Maps price values to vertical (Y-axis) coordinates.
///
/// This class is a **pure mathematical utility**:
/// - It contains NO rendering logic
/// - It contains NO Flutter dependencies
///
/// PERFORMANCE GUARANTEE:
/// - PriceScale is calculated ONCE when viewport or data changes
/// - It is cached inside [ChartEngine]
/// - It is NEVER recalculated during paint()
///
/// ---
///
/// ### TradingView Lightweight Charts behavior (matched intentionally)
///
/// - **Line / Area charts**
///   → Scale based on CLOSE prices only
///   → Ensures the line uses full vertical space
///
/// - **Candlestick charts**
///   → Scale based on HIGH / LOW prices
///   → Ensures wicks are fully visible
///
///- **Auto-scale**
///   → Adds symmetric padding above and below
///
/// - **Single data point**
///   → Centers vertically with visually pleasing margins
@immutable
class PriceScale {
  /// Minimum visible price (after padding).
  final double min;

  /// Maximum visible price (after padding).
  final double max;

  /// Cached price range (`max - min`).
  ///
  /// Stored to avoid recomputation.
  final double range;

  const PriceScale({
    required this.min,
    required this.max,
  }) : range = max - min;

  // ─────────────────────────────────────────────────────────
  // 🏭 Factory constructors
  // ─────────────────────────────────────────────────────────

  /// Create a price scale using HIGH / LOW prices.
  ///
  /// Use this for:
  /// - Candlestick charts
  /// - OHLC charts
  ///
  /// This ensures the full price movement (including wicks)
  /// is visible on screen.
  factory PriceScale.fromCandles(
    List<Candle> candles, {
    double paddingPercent = 0.05,
  }) {
    if (candles.isEmpty) {
      // Safe default when no data is available
      return const PriceScale(min: 0.0, max: 100.0);
    }

    double minPrice = candles.first.low;
    double maxPrice = candles.first.high;

    for (final candle in candles) {
      if (candle.low < minPrice) minPrice = candle.low;
      if (candle.high > maxPrice) maxPrice = candle.high;
    }

    return _createWithPadding(
      minPrice,
      maxPrice,
      paddingPercent,
    );
  }

  /// Create a price scale using CLOSE prices only.
  ///
  /// This is the **correct and intentional behavior** for:
  /// - Line charts
  /// - Area charts
  ///
  /// WHY:
  /// - The chart only displays close prices
  /// - Including highs/lows would waste vertical space
  /// - This matches TradingView Lightweight Charts behavior
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

    return _createWithPadding(
      minPrice,
      maxPrice,
      paddingPercent,
    );
  }

  // ─────────────────────────────────────────────────────────
  // 🔧 Internal helpers
  // ─────────────────────────────────────────────────────────

  /// Create a price scale with symmetric vertical padding.
  ///
  /// Handles ALL edge cases:
  /// - Single data point
  /// - Flat price movement
  /// - Very small price ranges
  ///
  /// This method is intentionally isolated so that
  /// padding behavior remains consistent everywhere.
  static PriceScale _createWithPadding(
    double minPrice,
    double maxPrice,
    double paddingPercent,
  ) {
    final priceRange = maxPrice - minPrice;

    double padding;

    // ─────────────────────────────────────────────
    // Edge case: flat or nearly-flat price range
    // ─────────────────────────────────────────────
    //
    // When:
    // - Only one data point exists
    // - Or price barely moves
    //
    // We must artificially expand the range so:
    // - The data point is centered vertically
    // - Labels are readable
    // - The chart does not look "collapsed"
    if (priceRange <= 0 || (maxPrice > 0 && priceRange < (maxPrice * 0.001))) {
      final basePrice = maxPrice.abs() > 0
          ? maxPrice.abs()
          : (minPrice.abs() > 0 ? minPrice.abs() : 1.0);

      // TradingView-style padding:
      // ~5% of price value, with a small minimum
      padding = (basePrice * 0.05).clamp(0.01, double.infinity);
    } else {
      // ─────────────────────────────────────────────
      // Normal case: percentage-based padding
      // ─────────────────────────────────────────────
      //
      // TradingView uses ~5% vertical margins by default
      padding = priceRange * paddingPercent;
    }

    return PriceScale(
      min: minPrice - padding,
      max: maxPrice + padding,
    );
  }

  // ─────────────────────────────────────────────────────────
  // 🔄 Coordinate mapping
  // ─────────────────────────────────────────────────────────

  /// Convert a price value to a Y coordinate.
  ///
  /// Mapping is:
  /// - price == max → y = 0   (top of chart)
  /// - price == min → y = H   (bottom of chart)
  ///
  /// This inversion matches screen coordinate systems.
  double priceToY(double price, double chartHeight) {
    if (range == 0) {
      // Single data point → center vertically
      return chartHeight / 2;
    }

    final normalized = (price - min) / range;
    return chartHeight * (1.0 - normalized);
  }

  /// Convert a Y coordinate back to a price value.
  double yToPrice(double y, double chartHeight) {
    if (chartHeight == 0) return min;

    final normalized = 1.0 - (y / chartHeight);
    return min + (normalized * range);
  }

  // ─────────────────────────────────────────────────────────
  // 🔤 Formatting (fallback / legacy)
  // ─────────────────────────────────────────────────────────
  //
  // NOTE:
  // Formatting is now generally handled via PriceFormatter.
  // This method remains for internal or legacy usage.
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

  // ─────────────────────────────────────────────────────────
  // ⚖ Equality
  // ─────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceScale &&
          runtimeType == other.runtimeType &&
          min == other.min &&
          max == other.max;

  @override
  int get hashCode => min.hashCode ^ max.hashCode;
}
