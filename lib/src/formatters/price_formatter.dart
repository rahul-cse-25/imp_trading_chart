/// ---------------------------------------------------------------------------
/// PRICE FORMATTER API
/// ---------------------------------------------------------------------------
///
/// A flexible and extensible price formatting system used throughout
/// the chart for:
/// - Y-axis price labels
/// - Current price label
/// - Crosshair price tooltip
///
/// Design principles:
/// - Stateless (pure formatting, no caching)
/// - Immutable
/// - Replaceable by users
/// - Zero dependency on chart internals
///
/// This abstraction allows:
/// - Different formatting strategies per chart
/// - Context-specific formatting (e.g. crosshair vs axis)
/// - User-defined custom formatters
///
/// Example usage:
/// ```dart
/// ChartStyle(
///   priceLabelStyle: PriceLabelStyle(
///     formatter: PriceFormatter.currency(symbol: '₹'),
///   ),
/// )
/// ```
abstract class PriceFormatter {
  /// Formats a numeric price value into a human-readable string.
  ///
  /// Implementations MUST:
  /// - Be pure (no side effects)
  /// - Always return a string
  /// - Handle negative values correctly
  /// - Never throw for valid `double` inputs
  String format(double price);

  /// -------------------------------------------------------------------------
  /// FACTORY CONSTRUCTORS (PUBLIC API)
  /// -------------------------------------------------------------------------
  ///
  /// These factories define the *official* formatter variants supported
  /// by the package. Internals remain private to allow future evolution.

  /// Smart formatter that automatically adjusts precision
  /// based on price magnitude.
  ///
  /// Behavior:
  /// - Very small values → scientific notation
  /// - Small values → high precision
  /// - Normal values → 2 decimals
  ///
  /// Best default for most trading charts.
  factory PriceFormatter.smart() => _SmartPriceFormatter();

  /// Fixed decimal formatter.
  ///
  /// Example:
  /// ```dart
  /// PriceFormatter.fixed(decimals: 3)
  /// // 12.34567 → "12.346"
  /// ```
  factory PriceFormatter.fixed({required int decimals}) =>
      _FixedPriceFormatter(decimals);

  /// Percentage formatter.
  ///
  /// Interprets input as ratio:
  /// - 0.05 → "5.00%"
  /// - 1.0 → "100.00%"
  factory PriceFormatter.percentage({int decimals = 2}) =>
      _PercentagePriceFormatter(decimals);

  /// Currency formatter with symbol.
  ///
  /// Example:
  /// - "$100.50"
  /// - "₹1200.00"
  factory PriceFormatter.currency({String symbol = '\$', int decimals = 2}) =>
      _CurrencyPriceFormatter(symbol, decimals);

  /// Compact formatter for large numbers.
  ///
  /// Example:
  /// - 1,200 → "1.2K"
  /// - 1,000,000 → "1.0M"
  /// - 1,000,000,000 → "1.0B"
  ///
  /// Useful for volume or price scales with large magnitudes.
  factory PriceFormatter.compact({int decimals = 1}) =>
      _CompactPriceFormatter(decimals);

  /// Currency formatter with compact notation.
  ///
  /// Example:
  /// - 500 → "$500.00"
  /// - 1,200 → "$1.20K"
  /// - 500,000,000 → "$500.00M"
  factory PriceFormatter.currencyCompact(
          {String symbol = '\$', int decimals = 2}) =>
      _CurrencyCompactPriceFormatter(symbol, decimals);

  /// Crosshair-specific formatter.
  ///
  /// Design intent:
  /// - Higher precision
  /// - Always readable
  /// - Suitable for tooltips and inspection
  ///
  /// Default behavior:
  /// - Currency + compact logic
  /// - 4 decimal places
  factory PriceFormatter.crosshair({String symbol = '\$', int decimals = 4}) =>
      _CurrencyCompactPriceFormatter(symbol, decimals);
}

/// ---------------------------------------------------------------------------
/// INTERNAL IMPLEMENTATIONS
/// ---------------------------------------------------------------------------
///
/// These classes are intentionally private.
/// Users are encouraged to either:
/// - Use the provided factories
/// - Or implement PriceFormatter directly
///
/// This allows breaking internal changes without breaking public API.

/// Smart formatter that adapts precision automatically.
class _SmartPriceFormatter implements PriceFormatter {
  @override
  String format(double price) {
    // Extremely small values → scientific notation
    if (price.abs() < 1e-6) {
      return price.toStringAsExponential(1);
    }
    // Very small values → high precision
    else if (price.abs() < 0.01) {
      return price.toStringAsFixed(6);
    }
    // Small values → medium precision
    else if (price.abs() < 1) {
      return price.toStringAsFixed(4);
    }
    // Normal trading prices
    else if (price.abs() < 1000) {
      return price.toStringAsFixed(2);
    }
    // Large prices (same precision, different scale handled elsewhere)
    else {
      return price.toStringAsFixed(2);
    }
  }
}

/// Fixed decimal formatter.
///
/// Always outputs exactly [decimals] digits after decimal point.
class _FixedPriceFormatter implements PriceFormatter {
  final int decimals;

  _FixedPriceFormatter(this.decimals);

  @override
  String format(double price) {
    return price.toStringAsFixed(decimals);
  }
}

/// Percentage formatter.
///
/// Converts ratio to percentage.
class _PercentagePriceFormatter implements PriceFormatter {
  final int decimals;

  _PercentagePriceFormatter(this.decimals);

  @override
  String format(double price) {
    return '${(price * 100).toStringAsFixed(decimals)}%';
  }
}

/// Currency formatter with symbol.
class _CurrencyPriceFormatter implements PriceFormatter {
  final String symbol;
  final int decimals;

  _CurrencyPriceFormatter(this.symbol, this.decimals);

  @override
  String format(double price) {
    return '$symbol${price.toStringAsFixed(decimals)}';
  }
}

/// Compact numeric formatter.
///
/// Converts large values into K / M / B notation.
class _CompactPriceFormatter implements PriceFormatter {
  final int decimals;

  _CompactPriceFormatter(this.decimals);

  @override
  String format(double price) {
    final absPrice = price.abs();
    final sign = price < 0 ? '-' : '';

    if (absPrice >= 1e9) {
      return '$sign${(absPrice / 1e9).toStringAsFixed(decimals)}B';
    } else if (absPrice >= 1e6) {
      return '$sign${(absPrice / 1e6).toStringAsFixed(decimals)}M';
    } else if (absPrice >= 1e3) {
      return '$sign${(absPrice / 1e3).toStringAsFixed(decimals)}K';
    } else {
      return price.toStringAsFixed(decimals);
    }
  }
}

/// Currency formatter with compact notation.
///
/// Combines:
/// - Currency symbol
/// - Compact suffixes
/// - Sign handling
class _CurrencyCompactPriceFormatter implements PriceFormatter {
  final String symbol;
  final int decimals;

  _CurrencyCompactPriceFormatter(this.symbol, this.decimals);

  @override
  String format(double price) {
    final absPrice = price.abs();
    final isNegative = price < 0;
    final sign = isNegative ? '-' : '';

    // Small values → normal currency
    if (absPrice < 1000) {
      return '$sign$symbol${absPrice.toStringAsFixed(decimals)}';
    }

    // Large values → compact currency
    if (absPrice >= 1e9) {
      return '$sign$symbol${(absPrice / 1e9).toStringAsFixed(decimals)}B';
    } else if (absPrice >= 1e6) {
      return '$sign$symbol${(absPrice / 1e6).toStringAsFixed(decimals)}M';
    } else if (absPrice >= 1e3) {
      return '$sign$symbol${(absPrice / 1e3).toStringAsFixed(decimals)}K';
    } else {
      return '$sign$symbol${absPrice.toStringAsFixed(decimals)}';
    }
  }
}

/// Default **const-safe** price formatter used by [PriceLabelStyle].
///
/// Why this exists:
/// - [PriceLabelStyle] has a `const` constructor
/// - Factory-based formatters (e.g. `PriceFormatter.smart()`) cannot be used in const contexts
/// - This formatter provides a predictable, lightweight default without runtime allocation
///
/// Design goals:
/// - Const-instantiable
/// - No external dependencies
/// - Trading-friendly compact notation
/// - Deterministic output (important for equality & repaint checks)
///
/// Formatting rules:
/// - < 1,000      → `$123.45`
/// - ≥ 1,000      → `$1.23K`
/// - ≥ 1,000,000  → `$1.23M`
/// - ≥ 1,000,000,000 → `$1.23B`
///
/// Notes:
/// - Always uses `$` symbol
/// - Always uses 2 decimal places
/// - Negative values preserve sign
class DefaultPriceFormatter implements PriceFormatter {
  /// Const constructor for use in const widget/style trees
  const DefaultPriceFormatter();

  @override
  String format(double price) {
    final absPrice = price.abs();
    final isNegative = price < 0;
    final sign = isNegative ? '-' : '';
    const symbol = '\$';
    const decimals = 2;

    // Small values: show full price
    if (absPrice < 1000) {
      return '$sign$symbol${absPrice.toStringAsFixed(decimals)}';
    }

    // Billion range
    if (absPrice >= 1e9) {
      return '$sign$symbol${(absPrice / 1e9).toStringAsFixed(decimals)}B';
    }
    // Million range
    else if (absPrice >= 1e6) {
      return '$sign$symbol${(absPrice / 1e6).toStringAsFixed(decimals)}M';
    }
    // Thousand range
    else if (absPrice >= 1e3) {
      return '$sign$symbol${(absPrice / 1e3).toStringAsFixed(decimals)}K';
    }
    // Fallback (theoretically unreachable, kept for safety)
    else {
      return '$sign$symbol${absPrice.toStringAsFixed(decimals)}';
    }
  }
}
