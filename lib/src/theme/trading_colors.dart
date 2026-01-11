import 'dart:ui';

/// Centralized trading color palette for the charting engine.
///
/// This class defines **semantic colors**, not just visual colors.
/// Every color represents a *financial meaning*:
///
/// - Bullish  → price moved up
/// - Bearish  → price moved down
/// - Neutral  → no change / informational
///
/// Design goals:
/// - Consistent visual language across all chart components
/// - Easy theme switching (TradingView / Crypto / Custom)
/// - No magic colors scattered across painters
///
/// ⚠️ IMPORTANT:
/// These colors are **stateless constants**.
/// Business logic must never depend on the actual color values.
class TradingColors {
  // ===========================================================================
  // PRIMARY TRADING COLORS (Default Theme)
  // ===========================================================================

  /// Primary bullish (price up) color.
  ///
  /// Used for:
  /// - Line charts
  /// - Bullish candles
  /// - Current price indicator (when price ↑)
  ///
  /// Soft mint green chosen to:
  /// - Reduce eye fatigue
  /// - Match professional trading platforms
  static const Color bullish = Color(0xFF78D99B);

  /// Primary bearish (price down) color.
  ///
  /// Used for:
  /// - Bearish candles
  /// - Price-down indicators
  /// - Loss states
  ///
  /// Vibrant red ensures immediate visual recognition.
  static const Color bearish = Color(0xFFFF2B3A);

  /// Neutral color for unchanged or non-directional values.
  ///
  /// Used when:
  /// - open == close
  /// - value = 0
  /// - informational labels
  static const Color neutral = Color(0xFF787B86);

  // ===========================================================================
  // ALTERNATIVE COLOR SCHEMES
  // ===========================================================================

  /// TradingView-style bullish teal green.
  ///
  /// Useful when matching TradingView UI exactly.
  static const Color bullishTradingView = Color(0xFF26A69A);

  /// TradingView-style bearish red.
  static const Color bearishTradingView = Color(0xFFEF5350);

  /// Crypto-market bullish green (CoinMarketCap style).
  ///
  /// Often used in crypto-focused UIs.
  static const Color bullishCrypto = Color(0xFF16C784);

  /// Crypto-market bearish red (CoinMarketCap style).
  static const Color bearishCrypto = Color(0xFFEA3943);

  /// High-contrast bullish green.
  ///
  /// Useful for:
  /// - Accessibility modes
  /// - Small charts
  /// - Dark backgrounds
  static const Color bullishBright = Color(0xFF00E676);

  /// High-contrast bearish red.
  static const Color bearishBright = Color(0xFFFF5252);

  // ===========================================================================
  // OHLC LABEL COLORS
  // ===========================================================================

  /// Open price label color.
  ///
  /// Neutral because opening price has no direction.
  static const Color openLabel = Color(0xFFD1D4E3);

  /// High price label color.
  ///
  /// Green tint indicates the maximum achieved price.
  static const Color highLabel = Color(0xFF4CAF50);

  /// Low price label color.
  ///
  /// Red/orange tint signals caution or downside.
  static const Color lowLabel = Color(0xFFFF7043);

  /// Close price label color.
  ///
  /// White because:
  /// - Direction is already shown by candle color
  /// - Close is the most important value
  static const Color closeLabel = Color(0xFFFFFFFF);

  // ===========================================================================
  // VOLUME COLORS
  // ===========================================================================

  /// Volume label color.
  ///
  /// Kept white for clarity across all backgrounds.
  static const Color volumeLabel = Color(0xFFFFFFFF);

  /// Bullish volume bar color (semi-transparent).
  ///
  /// Transparency allows volume bars to sit behind price data.
  static const Color volumeBullish = Color(0x6678D99B);

  /// Bearish volume bar color (semi-transparent).
  static const Color volumeBearish = Color(0x66F23645);

  // ===========================================================================
  // BACKGROUND / FILL COLORS
  // ===========================================================================

  /// Bullish candle body fill color.
  ///
  /// Semi-transparent so:
  /// - Grid lines remain visible
  /// - Overlapping elements don’t feel heavy
  static const Color bullishFill = Color(0x3378D99B);

  /// Bearish candle body fill color.
  static const Color bearishFill = Color(0x33F23645);

  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================

  /// Returns bullish or bearish color based on direction.
  ///
  /// `true`  → bullish
  /// `false` → bearish
  static Color fromDirection(bool isBullish) => isBullish ? bullish : bearish;

  /// Returns color based on numeric value.
  ///
  /// - value > 0 → bullish
  /// - value < 0 → bearish
  /// - value = 0 → neutral
  static Color fromValue(double value) {
    if (value > 0) return bullish;
    if (value < 0) return bearish;
    return neutral;
  }

  /// Returns color based on percent change.
  ///
  /// This is intentionally mapped to `fromValue`
  /// to keep behavior consistent across metrics.
  static Color fromPercent(double percent) => fromValue(percent);
}
