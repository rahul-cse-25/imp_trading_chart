import 'dart:ui';

/// Trading color configuration for charts
///
/// Standard trading colors used across financial applications:
/// - Green/Bullish: Price went up (close > open)
/// - Red/Bearish: Price went down (close < open)
/// - Neutral: No change or special states
///
/// Colors are matched with the ImpChart line colors for visual consistency.
class TradingColors {
  // ==================== Primary Trading Colors (Match ImpChart) ====================

  /// Bullish/Up color - Matches ImpChart line color
  static const Color bullish = Color(0xFF78D99B); // Soft mint green

  /// Bearish/Down color - Matches ImpChart bearish color
  static const Color bearish = Color(0xFFFF2B3A); // Vibrant red

  /// Neutral color - Grey for unchanged
  static const Color neutral = Color(0xFF787B86);

  // ==================== Alternative Color Schemes ====================

  /// TradingView teal green
  static const Color bullishTradingView = Color(0xFF26A69A);

  /// TradingView red
  static const Color bearishTradingView = Color(0xFFEF5350);

  /// Crypto green (CoinMarketCap style)
  static const Color bullishCrypto = Color(0xFF16C784);

  /// Crypto red (CoinMarketCap style)
  static const Color bearishCrypto = Color(0xFFEA3943);

  /// Bright green (more vibrant)
  static const Color bullishBright = Color(0xFF00E676);

  /// Bright red (more vibrant)
  static const Color bearishBright = Color(0xFFFF5252);

  // ==================== OHLC Label Colors ====================

  /// Open price color - Neutral white/grey (no direction)
  static const Color openLabel = Color(0xFFD1D4E3);

  /// High price color - Light green tint (highest = good)
  static const Color highLabel = Color(0xFF4CAF50);

  /// Low price color - Light red tint (lowest = caution)
  static const Color lowLabel = Color(0xFFFF7043);

  /// Close price - White (direction shown by candle color)
  static const Color closeLabel = Color(0xFFFFFFFF);

  // ==================== Volume Colors ====================

  /// Volume label - Light blue for clear visibility
  // static const Color volumeLabel = Color(0xFF5DADE2);
  static const Color volumeLabel = Color(0xFFFFFFFF);

  /// Volume bar bullish - Semi-transparent green
  static const Color volumeBullish = Color(0x6678D99B);

  /// Volume bar bearish - Semi-transparent red
  static const Color volumeBearish = Color(0x66F23645);

  // ==================== Background/Fill Colors ====================

  /// Bullish candle fill (semi-transparent)
  static const Color bullishFill = Color(0x3378D99B);

  /// Bearish candle fill (semi-transparent)
  static const Color bearishFill = Color(0x33F23645);

  // ==================== Helper Methods ====================

  /// Get color based on price direction
  static Color fromDirection(bool isBullish) => isBullish ? bullish : bearish;

  /// Get color based on value (positive = green, negative = red)
  static Color fromValue(double value) {
    if (value > 0) return bullish;
    if (value < 0) return bearish;
    return neutral;
  }

  /// Get color based on percent change
  static Color fromPercent(double percent) => fromValue(percent);
}
