import 'package:flutter/material.dart';
import 'package:imp_trading_chart/src/math/num_ex.dart';

import '../theme/trading_colors.dart';

/// Core data model for OHLC candle data.
///
/// The chart engine ONLY works with integer timestamps (seconds or milliseconds).
/// DateTime objects are NEVER used in the rendering pipeline.
class Candle {
  /// Unix timestamp in seconds (or milliseconds - must be consistent)
  final int time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double? volume;

  const Candle(
      {required this.time,
      required this.open,
      required this.high,
      required this.low,
      required this.close,
      this.volume});

  /// Creates a copy with updated values
  Candle copyWith(
      {int? time,
      double? open,
      double? high,
      double? low,
      double? close,
      double? volume}) {
    return Candle(
        time: time ?? this.time,
        open: open ?? this.open,
        high: high ?? this.high,
        low: low ?? this.low,
        close: close ?? this.close,
        volume: volume ?? this.volume);
  }

  /// Updates the candle with a new price tick.
  /// Used for live updates when a tick belongs to the current candle.
  Candle updateWithTick(double price) {
    return Candle(
        time: time,
        open: open,
        high: price > high ? price : high,
        low: price < low ? price : low,
        close: price,
        volume: volume);
  }

  // ==================== Direction Properties ====================

  /// Whether this candle is bullish (close >= open)
  bool get isBullish => close >= open;

  /// Whether this candle is bearish (close < open)
  bool get isBearish => close < open;

  /// Whether this candle is unchanged (close == open)
  bool get isNeutral => close == open;

  // ==================== Price Change Properties ====================

  /// Price change percentage
  double get changePercent => open != 0 ? ((close - open) / open) * 100 : 0.0;

  String get changePercentWithSign {
    final percent = changePercent;
    if (percent > 0) return "+${percent.toStringAsFixed(2)}%";
    if (percent < 0) return "${percent.toStringAsFixed(2)}%";
    return "0.00%";
  }

  double get changeValue => close - open;

  String get changeValueWithSign {
    final change = changeValue;
    if (change > 0) return "+${change.formatNumWithPos()}";
    if (change < 0) return "-${change.abs().formatNumWithPos()}";
    return "0.00";
  }

  // ==================== Color Properties ====================

  /// Primary candle color based on direction (bullish = green, bearish = red)
  /// Matches the ImpChart line color for visual consistency
  Color get color => isBullish ? TradingColors.bullish : TradingColors.bearish;

  /// Candle body fill color (semi-transparent)
  Color get fillColor =>
      isBullish ? TradingColors.bullishFill : TradingColors.bearishFill;

  /// Candle border/wick color
  Color get borderColor => color;

  // ==================== OHLC Colored Getters ====================

  /// Open price with its associated color (neutral grey - no direction)
  ({double value, Color color, String formatted}) get openColored => (
        value: open,
        color: TradingColors.openLabel,
        formatted: open.formatNumWithPos(),
      );

  /// High price with its associated color (semantic green - highest point)
  ({double value, Color color, String formatted}) get highColored => (
        value: high,
        color: TradingColors.highLabel,
        formatted: high.formatNumWithPos(),
      );

  /// Low price with its associated color (semantic orange - lowest point)
  ({double value, Color color, String formatted}) get lowColored => (
        value: low,
        color: TradingColors.lowLabel,
        formatted: low.formatNumWithPos(),
      );

  /// Close price with direction-based color (matches chart line)
  ({double value, Color color, String formatted}) get closeColored => (
        value: close,
        color: color,
        formatted: close.formatNumWithPos(),
      );

  /// Volume with neutral grey color (volume has no direction)
  ({double? value, Color color, String formatted}) get volumeColored => (
        value: volume,
        color: TradingColors.volumeLabel,
        formatted: volume?.formatNumWithPos() ?? '-',
      );

  /// Change value with direction-based color (matches chart line)
  ({double value, Color color, String formatted}) get changeValueColored => (
        value: changeValue,
        color: TradingColors.fromValue(changeValue),
        formatted: changeValueWithSign,
      );

  /// Change percent with direction-based color (matches chart line)
  ({double value, Color color, String formatted}) get changePercentColored => (
        value: changePercent,
        color: TradingColors.fromPercent(changePercent),
        formatted: changePercentWithSign,
      );

  // ==================== Convenience Color Getters ====================

  /// Color for the open label (neutral grey)
  Color get openColor => TradingColors.openLabel;

  /// Color for the high label (semantic green)
  Color get highColor => TradingColors.highLabel;

  /// Color for the low label (semantic orange)
  Color get lowColor => TradingColors.lowLabel;

  /// Color for the close label (direction-based, matches chart line)
  Color get closeColor => color;

  /// Color for volume (neutral grey - no direction)
  Color get volumeColor => TradingColors.volumeLabel;

  /// Color for change value (direction-based, matches chart line)
  Color get changeValueColor => TradingColors.fromValue(changeValue);

  /// Color for change percent (direction-based, matches chart line)
  Color get changePercentColor => TradingColors.fromPercent(changePercent);

  // ==================== Factory & Serialization ====================

  factory Candle.fromMap(Map<String, dynamic> map) {
    return Candle(
        open: parseDoubleValue(map['open']),
        high: parseDoubleValue(map['high']),
        low: parseDoubleValue(map['low']),
        close: parseDoubleValue(map['close']),
        time: parseIntValue(map['time']),
        volume:
            map.containsKey('volume') ? parseDoubleValue(map['volume']) : null);
  }

  // ======================== Internal helper ============================
  static double parseDoubleValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    } else {
      return 0.0;
    }
  }

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

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'open': open.toString(),
      'high': high.toString(),
      'low': low.toString(),
      'close': close.toString(),
      if (volume != null) 'volume': volume!.toString()
    };
  }

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
}

extension CandleMapper on Map<String, dynamic> {
  Candle toCandle() {
    return Candle(
      time: this['time'] as int,
      open: double.parse(this['open']),
      high: double.parse(this['high']),
      low: double.parse(this['low']),
      close: double.parse(this['close']),
    );
  }
}

List<Candle> parseCandlesFromPayload(Map<String, dynamic> payload) {
  final List list = payload['data']['chart_data'];

  return list.map((e) => (e as Map<String, dynamic>).toCandle()).toList();
}

const dummy = {
  "type": "charts",
  "event": "initial_payload",
  "data": {
    "chart_data": [
      {
        "open": "4776.00",
        "high": "4776.00",
        "low": "4776.00",
        "close": "4776.00",
        "time": 1764011640,
        "volume": "52736.00"
      },
      {
        "open": "4776.00",
        "high": "5125.00",
        "low": "4776.00",
        "close": "5125.00",
        "time": 1764143160,
        "volume": "200000000.00"
      },
      {
        "open": "5125.00",
        "high": "5162.00",
        "low": "5125.00",
        "close": "5162.00",
        "time": 1764148500,
        "volume": "80000000.00"
      },
      {
        "open": "5162.00",
        "high": "5169.00",
        "low": "5162.00",
        "close": "5169.00",
        "time": 1764149100,
        "volume": "16000000.00"
      },
      {
        "open": "5169.00",
        "high": "5173.00",
        "low": "5169.00",
        "close": "5173.00",
        "time": 1764149160,
        "volume": "8000000.00"
      },
      {
        "open": "5173.00",
        "high": "5176.00",
        "low": "5173.00",
        "close": "5176.00",
        "time": 1764149220,
        "volume": "8000000.00"
      },
      {
        "open": "5176.00",
        "high": "5180.00",
        "low": "5176.00",
        "close": "5180.00",
        "time": 1764153660,
        "volume": "2000000.00"
      },
      {
        "open": "5180.00",
        "high": "5182.00",
        "low": "5180.00",
        "close": "5182.00",
        "time": 1764153720,
        "volume": "1000000.00"
      },
      {
        "open": "5182.00",
        "high": "5185.00",
        "low": "5182.00",
        "close": "5185.00",
        "time": 1764172620,
        "volume": "8000000.00"
      },
      {
        "open": "5185.00",
        "high": "5189.00",
        "low": "5185.00",
        "close": "5189.00",
        "time": 1764172800,
        "volume": "2000000.00"
      },
      {
        "open": "5189.00",
        "high": "5193.00",
        "low": "5189.00",
        "close": "5193.00",
        "time": 1764172860,
        "volume": "2000000.00"
      },
      {
        "open": "5193.00",
        "high": "5196.00",
        "low": "5193.00",
        "close": "5196.00",
        "time": 1764173100,
        "volume": "4000000.00"
      },
      {
        "open": "5196.00",
        "high": "5200.00",
        "low": "5196.00",
        "close": "5200.00",
        "time": 1764174360,
        "volume": "2000000.00"
      },
      {
        "open": "5200.00",
        "high": "5204.00",
        "low": "5200.00",
        "close": "5204.00",
        "time": 1764175140,
        "volume": "2000000.00"
      },
      {
        "open": "5204.00",
        "high": "5263.00",
        "low": "5204.00",
        "close": "5263.00",
        "time": 1764263160,
        "volume": "20800000.00"
      },
      {
        "open": "5263.00",
        "high": "5320.00",
        "low": "5263.00",
        "close": "5320.00",
        "time": 1764263220,
        "volume": "46664800.00"
      },
      {
        "open": "5320.00",
        "high": "5470.00",
        "low": "5320.00",
        "close": "5470.00",
        "time": 1764263400,
        "volume": "120000000.00"
      },
      {
        "open": "5470.00",
        "high": "5496.00",
        "low": "5470.00",
        "close": "5496.00",
        "time": 1764263460,
        "volume": "20000000.00"
      },
      {
        "open": "5496.00",
        "high": "5521.00",
        "low": "5496.00",
        "close": "5521.00",
        "time": 1764263640,
        "volume": "20000000.00"
      },
      {
        "open": "5521.00",
        "high": "5534.00",
        "low": "5521.00",
        "close": "5534.00",
        "time": 1764263820,
        "volume": "10000000.00"
      },
      {
        "open": "5534.00",
        "high": "6223.00",
        "low": "5534.00",
        "close": "6223.00",
        "time": 1764264180,
        "volume": "484000000.00"
      },
      {
        "open": "6223.00",
        "high": "186683.00",
        "low": "6223.00",
        "close": "186683.00",
        "time": 1764264240,
        "volume": "6553299943.89"
      },
      {
        "open": "186683.00",
        "high": "4714639.00",
        "low": "186683.00",
        "close": "4714639.00",
        "time": 1764264960,
        "volume": "1172505814.15"
      },
      {
        "open": "4714639.00",
        "high": "12693003.00",
        "low": "4714639.00",
        "close": "12693003.00",
        "time": 1764265020,
        "volume": "113756501.08"
      },
      {
        "open": "12693003.00",
        "high": "12693116.00",
        "low": "12693003.00",
        "close": "12693116.00",
        "time": 1764308160,
        "volume": "787.83"
      },
      {
        "open": "12693116.00",
        "high": "12693229.00",
        "low": "2177762.00",
        "close": "2177762.00",
        "time": 1764315000,
        "volume": "251055099.48"
      },
      {
        "open": "2177762.00",
        "high": "2177809.00",
        "low": "2177762.00",
        "close": "2177809.00",
        "time": 1764315120,
        "volume": "4591.82"
      },
      {
        "open": "2177809.00",
        "high": "2179979.00",
        "low": "2177809.00",
        "close": "2179979.00",
        "time": 1764315240,
        "volume": "213411.02"
      },
      {
        "open": "2179979.00",
        "high": "2203387.00",
        "low": "2179979.00",
        "close": "2203387.00",
        "time": 1764318660,
        "volume": "2281383.89"
      },
      {
        "open": "2203387.00",
        "high": "2204091.00",
        "low": "2203387.00",
        "close": "2204091.00",
        "time": 1764321420,
        "volume": "68066.13"
      },
      {
        "open": "2204091.00",
        "high": "2253614.00",
        "low": "2204091.00",
        "close": "2253614.00",
        "time": 1764322740,
        "volume": "4706746.97"
      },
      {
        "open": "2253614.00",
        "high": "2253994.00",
        "low": "2253614.00",
        "close": "2253994.00",
        "time": 1764411300,
        "volume": "35495.53"
      },
      {
        "open": "2253994.00",
        "high": "2254944.00",
        "low": "2253994.00",
        "close": "2254944.00",
        "time": 1764411360,
        "volume": "88712.68"
      },
      {
        "open": "2254944.00",
        "high": "2255001.00",
        "low": "2254944.00",
        "close": "2255001.00",
        "time": 1764470400,
        "volume": "5321.57"
      },
      {
        "open": "2255001.00",
        "high": "2260780.00",
        "low": "2255001.00",
        "close": "2260780.00",
        "time": 1764470520,
        "volume": "538641.30"
      },
      {
        "open": "2260780.00",
        "high": "2262430.00",
        "low": "2260780.00",
        "close": "2262430.00",
        "time": 1764470580,
        "volume": "153409.99"
      },
      {
        "open": "2262430.00",
        "high": "2262549.00",
        "low": "2262430.00",
        "close": "2262549.00",
        "time": 1764473220,
        "volume": "11049.77"
      },
      {
        "open": "2262549.00",
        "high": "2262905.00",
        "low": "2262549.00",
        "close": "2262905.00",
        "time": 1764473340,
        "volume": "33145.84"
      },
      {
        "open": "2262905.00",
        "high": "2263470.00",
        "low": "2262905.00",
        "close": "2263470.00",
        "time": 1764476460,
        "volume": "52470.23"
      },
      {
        "open": "2263470.00",
        "high": "2263589.00",
        "low": "2263470.00",
        "close": "2263589.00",
        "time": 1764479400,
        "volume": "11044.69"
      },
      {
        "open": "2263589.00",
        "high": "2263589.00",
        "low": "893627.00",
        "close": "893627.00",
        "time": 1764480840,
        "volume": "248669883.40"
      },
      {
        "open": "893627.00",
        "high": "985590.00",
        "low": "893627.00",
        "close": "985590.00",
        "time": 1764481020,
        "volume": "31977130.77"
      },
      {
        "open": "985590.00",
        "high": "986720.00",
        "low": "985590.00",
        "close": "986720.00",
        "time": 1764482520,
        "volume": "365054.12"
      },
      {
        "open": "986720.00",
        "high": "986783.00",
        "low": "986720.00",
        "close": "986783.00",
        "time": 1764483300,
        "volume": "20268.52"
      },
      {
        "open": "986783.00",
        "high": "988228.00",
        "low": "986783.00",
        "close": "988228.00",
        "time": 1764487320,
        "volume": "465820.00"
      },
      {
        "open": "988228.00",
        "high": "989801.00",
        "low": "988228.00",
        "close": "989801.00",
        "time": 1764522540,
        "volume": "505553.59"
      },
      {
        "open": "989801.00",
        "high": "991213.00",
        "low": "989801.00",
        "close": "991213.00",
        "time": 1764522600,
        "volume": "453050.68"
      },
      {
        "open": "991213.00",
        "high": "991916.00",
        "low": "991213.00",
        "close": "991916.00",
        "time": 1764532200,
        "volume": "225119.60"
      },
      {
        "open": "991916.00",
        "high": "992231.00",
        "low": "991916.00",
        "close": "992231.00",
        "time": 1764569280,
        "volume": "100798.93"
      },
      {
        "open": "992231.00",
        "high": "995699.00",
        "low": "992231.00",
        "close": "995699.00",
        "time": 1764569340,
        "volume": "1106679.88"
      },
      {
        "open": "995699.00",
        "high": "1011539.00",
        "low": "995699.00",
        "close": "1011539.00",
        "time": 1764572460,
        "volume": "4982123.02"
      },
      {
        "open": "1011539.00",
        "high": "1401333.00",
        "low": "1011539.00",
        "close": "1401333.00",
        "time": 1764604980,
        "volume": "94569644.92"
      },
      {
        "open": "1401333.00",
        "high": "1402082.00",
        "low": "1401333.00",
        "close": "1402082.00",
        "time": 1764607380,
        "volume": "142683.08"
      },
      {
        "open": "1402082.00",
        "high": "1502005.00",
        "low": "1402082.00",
        "close": "1502005.00",
        "time": 1764608040,
        "volume": "18072445.34"
      },
      {
        "open": "1502005.00",
        "high": "1502547.00",
        "low": "1502005.00",
        "close": "1502547.00",
        "time": 1764608460,
        "volume": "93191.90"
      },
      {
        "open": "1502547.00",
        "high": "1506426.00",
        "low": "1502547.00",
        "close": "1506426.00",
        "time": 1764608940,
        "volume": "664678.84"
      },
      {
        "open": "1506426.00",
        "high": "1715122.00",
        "low": "1506426.00",
        "close": "1715122.00",
        "time": 1764645600,
        "volume": "32367025.12"
      },
      {
        "open": "1715122.00",
        "high": "8356525.00",
        "low": "1715122.00",
        "close": "8356525.00",
        "time": 1764645960,
        "volume": "264143280.34"
      },
      {
        "open": "8356525.00",
        "high": "8707509.00",
        "low": "8356525.00",
        "close": "8707509.00",
        "time": 1764646020,
        "volume": "4454754.17"
      },
      {
        "open": "8707509.00",
        "high": "8716843.00",
        "low": "8707509.00",
        "close": "8716843.00",
        "time": 1764646680,
        "volume": "114781.90"
      },
      {
        "open": "8716843.00",
        "high": "8721044.00",
        "low": "8716843.00",
        "close": "8721044.00",
        "time": 1764646860,
        "volume": "51611.76"
      },
      {
        "open": "8721044.00",
        "high": "8721044.00",
        "low": "8721044.00",
        "close": "8721044.00",
        "time": 1764646920,
        "volume": "0.00"
      },
      {
        "open": "8721044.00",
        "high": "8721044.00",
        "low": "8721044.00",
        "close": "8721044.00",
        "time": 1764647040,
        "volume": "0.00"
      },
      {
        "open": "8721044.00",
        "high": "8721511.00",
        "low": "8721044.00",
        "close": "8721511.00",
        "time": 1764647100,
        "volume": "5733.10"
      },
      {
        "open": "8721511.00",
        "high": "38184733.00",
        "low": "8721511.00",
        "close": "38184733.00",
        "time": 1764649140,
        "volume": "111808546.95"
      },
      {
        "open": "38184733.00",
        "high": "39066435.00",
        "low": "38184733.00",
        "close": "39066435.00",
        "time": 1764649200,
        "volume": "1161568.89"
      },
      {
        "open": "39066435.00",
        "high": "39066435.00",
        "low": "12590479.00",
        "close": "12590479.00",
        "time": 1764649680,
        "volume": "77053723.10"
      },
      {
        "open": "12590479.00",
        "high": "12590479.00",
        "low": "9928830.00",
        "close": "9928830.00",
        "time": 1764693480,
        "volume": "22474002.57"
      },
      {
        "open": "9928830.00",
        "high": "9929827.00",
        "low": "9928830.00",
        "close": "9929827.00",
        "time": 1764917640,
        "volume": "10071.17"
      },
      {
        "open": "9929827.00",
        "high": "9929827.00",
        "low": "8473779.00",
        "close": "8473779.00",
        "time": 1764918660,
        "volume": "16560384.77"
      },
      {
        "open": "8473779.00",
        "high": "8473779.00",
        "low": "20624.00",
        "close": "20624.00",
        "time": 1764918720,
        "volume": "4186621706.72"
      },
      {
        "open": "20624.00",
        "high": "20856.00",
        "low": "20624.00",
        "close": "20856.00",
        "time": 1764919080,
        "volume": "24589568.03"
      },
      {
        "open": "20856.00",
        "high": "20856.00",
        "low": "20856.00",
        "close": "20856.00",
        "time": 1765039440,
        "volume": "431.51"
      },
      {
        "open": "20856.00",
        "high": "22014.00",
        "low": "20856.00",
        "close": "22014.00",
        "time": 1765101300,
        "volume": "116670694.95"
      },
      {
        "open": "22014.00",
        "high": "23202.00",
        "low": "22014.00",
        "close": "23202.00",
        "time": 1765101420,
        "volume": "110615469.28"
      },
      {
        "open": "23202.00",
        "high": "24282.00",
        "low": "23202.00",
        "close": "24282.00",
        "time": 1765101780,
        "volume": "93310732.10"
      },
      {
        "open": "24282.00",
        "high": "24284.00",
        "low": "24282.00",
        "close": "24284.00",
        "time": 1765122540,
        "volume": "205902.69"
      },
      {
        "open": "24284.00",
        "high": "34302.00",
        "low": "24284.00",
        "close": "34302.00",
        "time": 1765122600,
        "volume": "643669237.80"
      },
      {
        "open": "34302.00",
        "high": "34305.00",
        "low": "34302.00",
        "close": "34305.00",
        "time": 1765123200,
        "volume": "145756.69"
      },
      {
        "open": "34305.00",
        "high": "34308.00",
        "low": "34305.00",
        "close": "34308.00",
        "time": 1765123320,
        "volume": "174891.61"
      },
      {
        "open": "34308.00",
        "high": "34367.00",
        "low": "34308.00",
        "close": "34367.00",
        "time": 1765123380,
        "volume": "2912224.88"
      },
      {
        "open": "34367.00",
        "high": "34370.00",
        "low": "34367.00",
        "close": "34370.00",
        "time": 1765127040,
        "volume": "145480.85"
      },
      {
        "open": "34370.00",
        "high": "34398.00",
        "low": "34370.00",
        "close": "34398.00",
        "time": 1765129140,
        "volume": "1425055.98"
      },
      {
        "open": "34398.00",
        "high": "40514.00",
        "low": "34398.00",
        "close": "40514.00",
        "time": 1765181580,
        "volume": "267870183.68"
      },
      {
        "open": "40514.00",
        "high": "69278.00",
        "low": "40514.00",
        "close": "69278.00",
        "time": 1765188660,
        "volume": "739280268.74"
      },
      {
        "open": "69278.00",
        "high": "69341.00",
        "low": "69278.00",
        "close": "69341.00",
        "time": 1765201320,
        "volume": "1085584.01"
      },
      {
        "open": "69341.00",
        "high": "69341.00",
        "low": "69206.00",
        "close": "69206.00",
        "time": 1765201500,
        "volume": "2335425.82"
      },
      {
        "open": "69206.00",
        "high": "69414.00",
        "low": "69206.00",
        "close": "69414.00",
        "time": 1765293960,
        "volume": "3606955.30"
      },
      {
        "open": "69414.00",
        "high": "69581.00",
        "low": "69414.00",
        "close": "69581.00",
        "time": 1765294740,
        "volume": "2877780.89"
      },
      {
        "open": "69581.00",
        "high": "69999.00",
        "low": "69581.00",
        "close": "69999.00",
        "time": 1765294800,
        "volume": "7164355.47"
      },
      {
        "open": "69999.00",
        "high": "71259.00",
        "low": "69999.00",
        "close": "71259.00",
        "time": 1765359480,
        "volume": "21238455.91"
      },
      {
        "open": "71259.00",
        "high": "71344.00",
        "low": "71259.00",
        "close": "71344.00",
        "time": 1765359540,
        "volume": "1402486.64"
      },
      {
        "open": "71344.00",
        "high": "73471.00",
        "low": "71344.00",
        "close": "73471.00",
        "time": 1765481340,
        "volume": "34530397.13"
      },
      {
        "open": "73471.00",
        "high": "86891.00",
        "low": "73471.00",
        "close": "86891.00",
        "time": 1765659900,
        "volume": "187734475.57"
      },
      {
        "open": "86891.00",
        "high": "101436.00",
        "low": "86891.00",
        "close": "101436.00",
        "time": 1765659960,
        "volume": "159774351.12"
      },
      {
        "open": "101436.00",
        "high": "371338.00",
        "low": "101436.00",
        "close": "371338.00",
        "time": 1765723440,
        "volume": "947916897.98"
      },
      {
        "open": "371338.00",
        "high": "600299.00",
        "low": "371338.00",
        "close": "600299.00",
        "time": 1765723500,
        "volume": "221582367.03"
      },
      {
        "open": "600299.00",
        "high": "667827.00",
        "low": "600299.00",
        "close": "667827.00",
        "time": 1765723620,
        "volume": "42369601.09"
      },
      {
        "open": "667827.00",
        "high": "670413.00",
        "low": "667827.00",
        "close": "670413.00",
        "time": 1765793400,
        "volume": "1494501.78"
      },
      {
        "open": "670413.00",
        "high": "670470.00",
        "low": "670413.00",
        "close": "670470.00",
        "time": 1765817040,
        "volume": "32814.15"
      },
      {
        "open": "670470.00",
        "high": "728738.00",
        "low": "670470.00",
        "close": "728738.00",
        "time": 1765817220,
        "volume": "31522644.61"
      },
      {
        "open": "728738.00",
        "high": "728765.00",
        "low": "728738.00",
        "close": "728765.00",
        "time": 1765869180,
        "volume": "13722.08"
      },
      {
        "open": "728765.00",
        "high": "728778.00",
        "low": "728765.00",
        "close": "728778.00",
        "time": 1765869840,
        "volume": "6174.77"
      },
      {
        "open": "728778.00",
        "high": "728805.00",
        "low": "728778.00",
        "close": "728805.00",
        "time": 1765952520,
        "volume": "13721.34"
      },
      {
        "open": "728805.00",
        "high": "728832.00",
        "low": "728805.00",
        "close": "728832.00",
        "time": 1765958460,
        "volume": "13720.83"
      },
      {
        "open": "728832.00",
        "high": "729260.00",
        "low": "728832.00",
        "close": "729260.00",
        "time": 1766030640,
        "volume": "217544.51"
      },
      {
        "open": "729260.00",
        "high": "731963.00",
        "low": "729260.00",
        "close": "731963.00",
        "time": 1766037780,
        "volume": "1368718.16"
      },
      {
        "open": "731963.00",
        "high": "789880.00",
        "low": "731963.00",
        "close": "789880.00",
        "time": 1766037840,
        "volume": "27618100.43"
      },
      {
        "open": "789880.00",
        "high": "790446.00",
        "low": "789880.00",
        "close": "790446.00",
        "time": 1766087520,
        "volume": "254580.18"
      },
      {
        "open": "790446.00",
        "high": "790924.00",
        "low": "790446.00",
        "close": "790924.00",
        "time": 1766087580,
        "volume": "215003.34"
      },
      {
        "open": "790924.00",
        "high": "790990.00",
        "low": "790924.00",
        "close": "790990.00",
        "time": 1766146680,
        "volume": "29710.83"
      },
      {
        "open": "790990.00",
        "high": "791738.00",
        "low": "790990.00",
        "close": "791738.00",
        "time": 1766208360,
        "volume": "335941.29"
      },
      {
        "open": "791738.00",
        "high": "793393.00",
        "low": "791738.00",
        "close": "793393.00",
        "time": 1766211660,
        "volume": "741894.36"
      },
      {
        "open": "793393.00",
        "high": "796212.00",
        "low": "793393.00",
        "close": "796212.00",
        "time": 1766211720,
        "volume": "1258174.76"
      },
      {
        "open": "796212.00",
        "high": "796243.00",
        "low": "796212.00",
        "close": "796243.00",
        "time": 1766220420,
        "volume": "13397.53"
      },
      {
        "open": "796243.00",
        "high": "796271.00",
        "low": "796243.00",
        "close": "796271.00",
        "time": 1766317260,
        "volume": "12558.76"
      },
      {
        "open": "796271.00",
        "high": "796299.00",
        "low": "796271.00",
        "close": "796299.00",
        "time": 1766317440,
        "volume": "12558.31"
      },
      {
        "open": "796299.00",
        "high": "796511.00",
        "low": "796299.00",
        "close": "796511.00",
        "time": 1766328120,
        "volume": "94173.15"
      },
      {
        "open": "796511.00",
        "high": "833622.00",
        "low": "796511.00",
        "close": "833622.00",
        "time": 1766386440,
        "volume": "15953742.08"
      },
      {
        "open": "833622.00",
        "high": "922490.00",
        "low": "833622.00",
        "close": "922490.00",
        "time": 1766386500,
        "volume": "34210186.58"
      },
      {
        "open": "922490.00",
        "high": "922520.00",
        "low": "922490.00",
        "close": "922520.00",
        "time": 1766403780,
        "volume": "10840.04"
      },
      {
        "open": "922520.00",
        "high": "922551.00",
        "low": "922520.00",
        "close": "922551.00",
        "time": 1766403900,
        "volume": "10839.68"
      },
      {
        "open": "922551.00",
        "high": "922581.00",
        "low": "922551.00",
        "close": "922581.00",
        "time": 1766485140,
        "volume": "10839.33"
      },
      {
        "open": "922581.00",
        "high": "922885.00",
        "low": "922581.00",
        "close": "922885.00",
        "time": 1766556840,
        "volume": "108373.64"
      },
      {
        "open": "922885.00",
        "high": "923189.00",
        "low": "922885.00",
        "close": "923189.00",
        "time": 1766557140,
        "volume": "108337.98"
      },
      {
        "open": "923189.00",
        "high": "923493.00",
        "low": "923189.00",
        "close": "923493.00",
        "time": 1766558880,
        "volume": "108302.33"
      },
      {
        "open": "923493.00",
        "high": "924101.00",
        "low": "923493.00",
        "close": "924101.00",
        "time": 1766558940,
        "volume": "216497.77"
      },
      {
        "open": "924101.00",
        "high": "1132019.00",
        "low": "924101.00",
        "close": "1132019.00",
        "time": 1766562060,
        "volume": "63482498.90"
      },
      {
        "open": "1132019.00",
        "high": "1134038.00",
        "low": "1132019.00",
        "close": "1134038.00",
        "time": 1766593020,
        "volume": "529554.12"
      },
      {
        "open": "1134038.00",
        "high": "1137746.00",
        "low": "1134038.00",
        "close": "1137746.00",
        "time": 1766642820,
        "volume": "968402.70"
      },
      {
        "open": "1137746.00",
        "high": "1137914.00",
        "low": "1137746.00",
        "close": "1137914.00",
        "time": 1766644980,
        "volume": "43943.27"
      },
      {
        "open": "1137914.00",
        "high": "1138285.00",
        "low": "1137914.00",
        "close": "1138285.00",
        "time": 1766645520,
        "volume": "96652.28"
      },
      {
        "open": "1138285.00",
        "high": "1138285.00",
        "low": "1138285.00",
        "close": "1138285.00",
        "time": 1766645940,
        "volume": "0.00"
      },
      {
        "open": "1138285.00",
        "high": "1141662.00",
        "low": "1138285.00",
        "close": "1141662.00",
        "time": 1766646720,
        "volume": "877213.80"
      },
      {
        "open": "1141662.00",
        "high": "1145043.00",
        "low": "1141662.00",
        "close": "1145043.00",
        "time": 1766646780,
        "volume": "874621.45"
      },
      {
        "open": "1145043.00",
        "high": "1148430.00",
        "low": "1145043.00",
        "close": "1148430.00",
        "time": 1766646840,
        "volume": "872040.57"
      },
      {
        "open": "1148430.00",
        "high": "1149311.00",
        "low": "1148430.00",
        "close": "1149311.00",
        "time": 1766659320,
        "volume": "226309.21"
      },
      {
        "open": "1149311.00",
        "high": "1151957.00",
        "low": "1149311.00",
        "close": "1151957.00",
        "time": 1766659380,
        "volume": "677887.45"
      },
      {
        "open": "1151957.00",
        "high": "1152839.00",
        "low": "1151957.00",
        "close": "1152839.00",
        "time": 1766659440,
        "volume": "225616.42"
      },
      {
        "open": "1152839.00",
        "high": "1153009.00",
        "low": "1152839.00",
        "close": "1153009.00",
        "time": 1766734740,
        "volume": "43367.97"
      },
      {
        "open": "1153009.00",
        "high": "1153349.00",
        "low": "1153009.00",
        "close": "1153349.00",
        "time": 1766734800,
        "volume": "86716.78"
      },
      {
        "open": "1153349.00",
        "high": "1156747.00",
        "low": "1153349.00",
        "close": "1156747.00",
        "time": 1766739060,
        "volume": "865765.48"
      },
      {
        "open": "1156747.00",
        "high": "1157734.00",
        "low": "1156747.00",
        "close": "1157734.00",
        "time": 1766742780,
        "volume": "250596.05"
      },
      {
        "open": "1157734.00",
        "high": "1158074.00",
        "low": "1157734.00",
        "close": "1158074.00",
        "time": 1766742840,
        "volume": "86362.92"
      },
      {
        "open": "1158074.00",
        "high": "1158414.00",
        "low": "1158074.00",
        "close": "1158414.00",
        "time": 1766743020,
        "volume": "86337.54"
      },
      {
        "open": "1158414.00",
        "high": "1162161.00",
        "low": "1158414.00",
        "close": "1162161.00",
        "time": 1766744340,
        "volume": "948041.43"
      },
      {
        "open": "1162161.00",
        "high": "1162502.00",
        "low": "1162161.00",
        "close": "1162502.00",
        "time": 1766744700,
        "volume": "86033.92"
      },
      {
        "open": "1162502.00",
        "high": "1162843.00",
        "low": "1162502.00",
        "close": "1162843.00",
        "time": 1766744820,
        "volume": "86008.69"
      },
      {
        "open": "1162843.00",
        "high": "1163184.00",
        "low": "1162843.00",
        "close": "1163184.00",
        "time": 1766748840,
        "volume": "85983.47"
      },
      {
        "open": "1163184.00",
        "high": "1163355.00",
        "low": "1163184.00",
        "close": "1163355.00",
        "time": 1766748960,
        "volume": "42982.28"
      },
      {
        "open": "1163355.00",
        "high": "1163525.00",
        "low": "1163355.00",
        "close": "1163525.00",
        "time": 1766749020,
        "volume": "42975.98"
      },
      {
        "open": "1163525.00",
        "high": "1163866.00",
        "low": "1163525.00",
        "close": "1163866.00",
        "time": 1766749200,
        "volume": "85933.07"
      },
      {
        "open": "1163866.00",
        "high": "1164208.00",
        "low": "1163866.00",
        "close": "1164208.00",
        "time": 1766749320,
        "volume": "85907.88"
      },
      {
        "open": "1164208.00",
        "high": "1164378.00",
        "low": "1164208.00",
        "close": "1164378.00",
        "time": 1766749380,
        "volume": "42944.50"
      },
      {
        "open": "1164378.00",
        "high": "1164549.00",
        "low": "1164378.00",
        "close": "1164549.00",
        "time": 1766750100,
        "volume": "42938.21"
      },
      {
        "open": "1164549.00",
        "high": "1164685.00",
        "low": "1164549.00",
        "close": "1164685.00",
        "time": 1766750160,
        "volume": "34346.04"
      },
      {
        "open": "1164685.00",
        "high": "1164719.00",
        "low": "1164685.00",
        "close": "1164719.00",
        "time": 1766756880,
        "volume": "8585.88"
      },
      {
        "open": "1164719.00",
        "high": "1164754.00",
        "low": "1164719.00",
        "close": "1164754.00",
        "time": 1766759340,
        "volume": "8585.63"
      },
      {
        "open": "1164754.00",
        "high": "1165095.00",
        "low": "1164754.00",
        "close": "1165095.00",
        "time": 1766760600,
        "volume": "85842.45"
      },
      {
        "open": "1165095.00",
        "high": "1165778.00",
        "low": "1165095.00",
        "close": "1165778.00",
        "time": 1766760660,
        "volume": "171609.48"
      },
      {
        "open": "1165778.00",
        "high": "1166631.00",
        "low": "1165778.00",
        "close": "1166631.00",
        "time": 1766760720,
        "volume": "214370.54"
      },
      {
        "open": "1166631.00",
        "high": "1166631.00",
        "low": "881818.00",
        "close": "881818.00",
        "time": 1766763540,
        "volume": "87955626.55"
      },
      {
        "open": "881818.00",
        "high": "1089374.00",
        "low": "881818.00",
        "close": "1089374.00",
        "time": 1766768280,
        "volume": "67547910.16"
      },
      {
        "open": "1089374.00",
        "high": "1122629.00",
        "low": "1089374.00",
        "close": "1122629.00",
        "time": 1766809380,
        "volume": "9042595.56"
      },
      {
        "open": "1122629.00",
        "high": "1122629.00",
        "low": "854211.00",
        "close": "854211.00",
        "time": 1766809440,
        "volume": "87387370.50"
      },
      {
        "open": "854211.00",
        "high": "854503.00",
        "low": "854211.00",
        "close": "854503.00",
        "time": 1766816640,
        "volume": "117047.02"
      }
    ],
    "range": "1",
    "start_time": 1764002069,
    "token_mint": "CX9FtSrBLZ4XofHy4gwGNHyFvUxwxhD1c6Ycwx9Sc7Vt"
  }
};
