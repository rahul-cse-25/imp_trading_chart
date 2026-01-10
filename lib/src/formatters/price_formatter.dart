/// Flexible price formatter for custom price label formatting.
/// 
/// Implement this interface to provide custom price formatting logic.
/// Default implementation provides smart formatting based on price magnitude.
abstract class PriceFormatter {
    /// Format a price value for display
    String format(double price);

    /// Default formatter that provides smart formatting
    factory PriceFormatter.smart() => _SmartPriceFormatter();

    /// Fixed decimal places formatter
    factory PriceFormatter.fixed({required int decimals}) => _FixedPriceFormatter(decimals);

    /// Percentage formatter (0.05 -> "5.00%")
    factory PriceFormatter.percentage({int decimals = 2}) => _PercentagePriceFormatter(decimals);

    /// Currency formatter with symbol (100.5 -> "$100.50")
    factory PriceFormatter.currency({String symbol = '\$', int decimals = 2}) => _CurrencyPriceFormatter(symbol, decimals);

    /// Compact formatter (1000 -> "1K", 1000000 -> "1M")
    factory PriceFormatter.compact({int decimals = 1}) => _CompactPriceFormatter(decimals);

    /// Currency with compact notation (1000 -> "$1.20K", 500 -> "$500", 500000000 -> "$500.86M")
    factory PriceFormatter.currencyCompact({String symbol = '\$', int decimals = 2}) => _CurrencyCompactPriceFormatter(symbol, decimals);

    /// Crosshair formatter with 4 decimal places for precise price display
    /// Perfect for crosshair tooltips where precision matters
    factory PriceFormatter.crosshair({String symbol = '\$', int decimals = 4}) => _CurrencyCompactPriceFormatter(symbol, decimals);
}

/// Default smart price formatter - automatically adjusts precision based on price magnitude
class _SmartPriceFormatter implements PriceFormatter {
    @override
    String format(double price) {
        // Handle very small prices with scientific notation
        if (price.abs() < 1e-6) {
            return price.toStringAsExponential(1);
        } 
        // Very small prices - 6 decimal places
        else if (price.abs() < 0.01) {
            return price.toStringAsFixed(6);
        } 
        // Small prices - 4 decimal places
        else if (price.abs() < 1) {
            return price.toStringAsFixed(4);
        } 
        // Regular prices - 2 decimal places
        else if (price.abs() < 1000) {
            return price.toStringAsFixed(2);
        } 
        // Large prices - 2 decimal places (same as regular, can add thousands separator if needed)
        else {
            return price.toStringAsFixed(2);
        }
    }
}

/// Fixed decimal places formatter
class _FixedPriceFormatter implements PriceFormatter {
    final int decimals;

    _FixedPriceFormatter(this.decimals);

    @override
    String format(double price) {
        return price.toStringAsFixed(decimals);
    }
}

/// Percentage formatter (0.05 -> "5.00%")
class _PercentagePriceFormatter implements PriceFormatter {
    final int decimals;

    _PercentagePriceFormatter(this.decimals);

    @override
    String format(double price) {
        return '${(price * 100).toStringAsFixed(decimals)}%';
    }
}

/// Currency formatter with symbol
class _CurrencyPriceFormatter implements PriceFormatter {
    final String symbol;
    final int decimals;

    _CurrencyPriceFormatter(this.symbol, this.decimals);

    @override
    String format(double price) {
        return '$symbol${price.toStringAsFixed(decimals)}';
    }
}

/// Compact formatter (1000 -> "1.0K", 1000000 -> "1.0M")
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

/// Currency with compact notation formatter ($500 -> "$500", $1200 -> "$1.20K", $500000000 -> "$500.86M")
class _CurrencyCompactPriceFormatter implements PriceFormatter {
    final String symbol;
    final int decimals;

    _CurrencyCompactPriceFormatter(this.symbol, this.decimals);

    @override
    String format(double price) {
        final absPrice = price.abs();
        final isNegative = price < 0;
        final sign = isNegative ? '-' : '';

        // For values less than 1000, use regular currency format
        if (absPrice < 1000) {
            return '$sign$symbol${absPrice.toStringAsFixed(decimals)}';
        }

        // For values >= 1000, use compact notation with currency symbol
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
