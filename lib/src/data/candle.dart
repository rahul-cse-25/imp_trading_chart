import 'package:flutter/material.dart';
import 'package:imp_trading_chart/src/math/num_ex.dart';

import '../theme/trading_colors.dart';

/// Core immutable data model for OHLC candle data.
///
/// This is the **single source of truth** for price data in the chart engine.
///
/// ─────────────────────────────────────────────────────────
/// 🔒 DESIGN CONSTRAINTS (VERY IMPORTANT)
/// ─────────────────────────────────────────────────────────
///
/// - The chart engine **ONLY works with integer timestamps**
/// - Timestamps must be **Unix time** (seconds OR milliseconds)
/// - The unit (seconds vs milliseconds) must be **consistent**
/// - `DateTime` objects are **NEVER used** in rendering logic
///
/// Why?
/// - Avoids object allocation during paint
/// - Enables fast math-only coordinate mapping
/// - Keeps rendering deterministic and GC-friendly
///
/// This model is:
/// - Immutable
/// - Serializable
/// - Safe for hot reload & diff-based repaint checks
@immutable
class Candle {
  /// Unix timestamp (seconds OR milliseconds – must be consistent)
  final int time;

  /// Opening price of the candle
  final double open;

  /// Highest traded price during this candle
  final double high;

  /// Lowest traded price during this candle
  final double low;

  /// Closing price of the candle
  final double close;

  /// Optional traded volume
  ///
  /// Can be null for markets or data sources where volume is unavailable
  final double? volume;

  const Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume,
  });

  // ===========================================================================
  // IMMUTABILITY HELPERS
  // ===========================================================================

  /// Creates a copy of this candle with selectively overridden values.
  ///
  /// Used when:
  /// - Updating candle data immutably
  /// - Modifying parsed or transformed data
  Candle copyWith({
    int? time,
    double? open,
    double? high,
    double? low,
    double? close,
    double? volume,
  }) {
    return Candle(
      time: time ?? this.time,
      open: open ?? this.open,
      high: high ?? this.high,
      low: low ?? this.low,
      close: close ?? this.close,
      volume: volume ?? this.volume,
    );
  }

  /// Updates this candle with a new price tick.
  ///
  /// This is used for **live market updates** when an incoming tick
  /// belongs to the currently forming candle.
  ///
  /// Rules:
  /// - `open` remains unchanged
  /// - `high` expands upward if needed
  /// - `low` expands downward if needed
  /// - `close` always updates
  Candle updateWithTick(double price) {
    return Candle(
      time: time,
      open: open,
      high: price > high ? price : high,
      low: price < low ? price : low,
      close: price,
      volume: volume,
    );
  }

  // ===========================================================================
  // DIRECTION / STATE
  // ===========================================================================

  /// True if candle closed higher than (or equal to) open
  bool get isBullish => close >= open;

  /// True if candle closed lower than open
  bool get isBearish => close < open;

  /// True if candle closed exactly at open price
  bool get isNeutral => close == open;

  // ===========================================================================
  // PRICE CHANGE METRICS
  // ===========================================================================

  /// Percentage price change relative to open
  ///
  /// Returns 0 if open is 0 to avoid division errors
  double get changePercent => open != 0 ? ((close - open) / open) * 100 : 0.0;

  /// Percentage change formatted with sign
  ///
  /// Examples:
  /// - "+2.45%"
  /// - "-1.12%"
  /// - "0.00%"
  String get changePercentWithSign {
    final percent = changePercent;
    if (percent > 0) return "+${percent.toStringAsFixed(2)}%";
    if (percent < 0) return "${percent.toStringAsFixed(2)}%";
    return "0.00%";
  }

  /// Absolute price change (close - open)
  double get changeValue => close - open;

  /// Absolute price change formatted with sign
  String get changeValueWithSign {
    final change = changeValue;
    if (change > 0) return "+${change.formatNumWithPos()}";
    if (change < 0) return "-${change.abs().formatNumWithPos()}";
    return "0.00";
  }

  // ===========================================================================
  // COLOR SEMANTICS (USED BY UI)
  // ===========================================================================

  /// Primary candle color based on direction
  ///
  /// - Bullish → green
  /// - Bearish → red
  ///
  /// Matches the ImpChart line color for visual consistency
  Color get color => isBullish ? TradingColors.bullish : TradingColors.bearish;

  /// Semi-transparent body fill color
  Color get fillColor =>
      isBullish ? TradingColors.bullishFill : TradingColors.bearishFill;

  /// Border / wick color
  Color get borderColor => color;

  // ===========================================================================
  // COLORED + FORMATTED VALUE BUNDLES (UI-READY)
  // ===========================================================================

  /// Open price (neutral color)
  ({double value, Color color, String formatted}) get openColored => (
        value: open,
        color: TradingColors.openLabel,
        formatted: open.formatNumWithPos(),
      );

  /// High price (semantic green)
  ({double value, Color color, String formatted}) get highColored => (
        value: high,
        color: TradingColors.highLabel,
        formatted: high.formatNumWithPos(),
      );

  /// Low price (semantic warning color)
  ({double value, Color color, String formatted}) get lowColored => (
        value: low,
        color: TradingColors.lowLabel,
        formatted: low.formatNumWithPos(),
      );

  /// Close price (direction-based color)
  ({double value, Color color, String formatted}) get closeColored => (
        value: close,
        color: color,
        formatted: close.formatNumWithPos(),
      );

  /// Volume (neutral color, optional)
  ({double? value, Color color, String formatted}) get volumeColored => (
        value: volume,
        color: TradingColors.volumeLabel,
        formatted: volume?.formatNumWithPos() ?? '-',
      );

  /// Absolute change value with semantic color
  ({double value, Color color, String formatted}) get changeValueColored => (
        value: changeValue,
        color: TradingColors.fromValue(changeValue),
        formatted: changeValueWithSign,
      );

  /// Percentage change with semantic color
  ({double value, Color color, String formatted}) get changePercentColored => (
        value: changePercent,
        color: TradingColors.fromPercent(changePercent),
        formatted: changePercentWithSign,
      );

  // ===========================================================================
  // RAW COLOR CONVENIENCE GETTERS
  // ===========================================================================

  Color get openColor => TradingColors.openLabel;
  Color get highColor => TradingColors.highLabel;
  Color get lowColor => TradingColors.lowLabel;
  Color get closeColor => color;
  Color get volumeColor => TradingColors.volumeLabel;
  Color get changeValueColor => TradingColors.fromValue(changeValue);
  Color get changePercentColor => TradingColors.fromPercent(changePercent);

  // ===========================================================================
  // SERIALIZATION / DESERIALIZATION
  // ===========================================================================

  /// Create candle from loosely typed map (API-safe)
  ///
  /// Accepts:
  /// - num
  /// - String
  /// - mixed payloads
  ///
  /// Invalid or missing values safely fall back to 0
  factory Candle.fromMap(Map<String, dynamic> map) {
    return Candle(
      open: parseDoubleValue(map['open']),
      high: parseDoubleValue(map['high']),
      low: parseDoubleValue(map['low']),
      close: parseDoubleValue(map['close']),
      time: parseIntValue(map['time']),
      volume:
          map.containsKey('volume') ? parseDoubleValue(map['volume']) : null,
    );
  }

  /// Internal helper: parse dynamic numeric input into double
  static double parseDoubleValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    } else {
      return 0.0;
    }
  }

  /// Internal helper: parse dynamic numeric input into int
  static int parseIntValue(dynamic value) {
    if (value is int) {
      return value;
    } else if (value is num) {
      return value.toInt();
    } else if (value is String) {
      return int.tryParse(value) ?? 0;
    } else {
      return 0;
    }
  }

  /// Raw JSON output (numeric values as strings)
  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'open': open.toString(),
      'high': high.toString(),
      'low': low.toString(),
      'close': close.toString(),
      if (volume != null) 'volume': volume!.toString(),
    };
  }

  /// Pre-formatted JSON output (UI-ready values)
  ///
  /// Useful for:
  /// - Debug panels
  /// - Tooltips
  /// - Inspector widgets
  Map<String, dynamic> formattedJson() {
    return {
      'time': time,
      'open': open.formatNumWithPos(),
      'high': high.formatNumWithPos(),
      'low': low.formatNumWithPos(),
      'close': close.formatNumWithPos(),
      if (volume != null) 'volume': volume!.formatNumWithPos(),
      'changePercent': changePercent.formatNumWithPos(),
    };
  }

  // ===========================================================================
  // EQUALITY & HASHING
  // ===========================================================================

  /// Value equality comparison for candles.
  ///
  /// Two candles are equal if all their OHLC data and timestamp match.
  /// This enables:
  /// - Reliable change detection in widget updates
  /// - Proper list comparisons
  /// - Efficient rebuild optimization
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Candle &&
          runtimeType == other.runtimeType &&
          time == other.time &&
          open == other.open &&
          high == other.high &&
          low == other.low &&
          close == other.close &&
          volume == other.volume;

  @override
  int get hashCode => Object.hash(time, open, high, low, close, volume);
}
