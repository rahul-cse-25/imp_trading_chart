import 'package:flutter/material.dart';
import 'package:imp_trading_chart/src/data/enums.dart' show LineStyle;

// ============================================================================
// CURRENT PRICE INDICATOR STYLE
// ============================================================================

/// Styling for the **current / latest price indicator**.
///
/// This model controls:
/// - The horizontal price line
/// - The price label shown on the Y-axis
///
/// The painter uses this style to render a TradingView-like
/// "current price" marker that updates in real time.
///
/// Design goals:
/// - Clear price direction (bullish / bearish)
/// - Consistent alignment with Y-axis labels
/// - Optional visibility for minimal charts
class CurrentPriceIndicatorStyle {
  /// Whether to draw the horizontal price line.
  ///
  /// This line spans the visible chart width and helps
  /// visually anchor the current price.
  final bool showLine;

  /// Whether to show the price label on the Y-axis.
  ///
  /// The label is rendered in the same column as Y-axis labels
  /// to maintain visual consistency.
  final bool showLabel;

  /// Color of the price line.
  ///
  /// Independent from bullish/bearish label colors.
  final Color lineColor;

  /// Width of the price line stroke.
  final double lineWidth;

  /// Line style of the price line.
  ///
  /// Supports:
  /// - solid
  /// - dashed
  /// - dotted
  final LineStyle lineStyle;

  /// Background color for bullish (price increased) label.
  final Color bullishColor;

  /// Background color for bearish (price decreased) label.
  final Color bearishColor;

  /// Text color for the price label.
  ///
  /// Defaults to black to maintain contrast
  /// against colored backgrounds.
  final Color textColor;

  /// Font size for the price label text.
  final double labelFontSize;

  /// Horizontal padding inside the label.
  final double labelPaddingH;

  /// Vertical padding inside the label.
  final double labelPaddingV;

  /// Border radius of the label background.
  ///
  /// Rounded corners match modern trading UI aesthetics.
  final double labelBorderRadius;

  /// Default constructor with trading-friendly defaults.
  const CurrentPriceIndicatorStyle({
    this.showLine = true,
    this.showLabel = true,
    this.lineColor = Colors.blue,
    this.lineWidth = 1.5,
    this.lineStyle = LineStyle.solid,
    this.bullishColor = const Color(0xFF4CAF50),
    this.bearishColor = const Color(0xFFF44336),
    this.textColor = Colors.black,
    this.labelFontSize = 12.0,
    this.labelPaddingH = 8.0,
    this.labelPaddingV = 4.0,
    this.labelBorderRadius = 6.0,
  });

  /// Create a **line-only** current price indicator.
  ///
  /// Use cases:
  /// - Minimal charts
  /// - Background price references
  factory CurrentPriceIndicatorStyle.lineOnly({
    Color lineColor = Colors.blue,
    double lineWidth = 1.5,
    LineStyle lineStyle = LineStyle.solid,
  }) {
    return CurrentPriceIndicatorStyle(
      showLine: true,
      showLabel: false,
      lineColor: lineColor,
      lineWidth: lineWidth,
      lineStyle: lineStyle,
    );
  }

  /// Create a **dashed** current price indicator.
  ///
  /// Commonly used to visually distinguish the
  /// current price from grid lines.
  factory CurrentPriceIndicatorStyle.dashed({
    Color lineColor = Colors.blue,
    Color bullishColor = const Color(0xFF4CAF50),
    Color bearishColor = const Color(0xFFF44336),
  }) {
    return CurrentPriceIndicatorStyle(
      lineColor: lineColor,
      lineStyle: LineStyle.dashed,
      bullishColor: bullishColor,
      bearishColor: bearishColor,
    );
  }

  /// Create a **dotted** current price indicator.
  ///
  /// Often used for subtle, non-dominant price markers.
  factory CurrentPriceIndicatorStyle.dotted({
    Color lineColor = Colors.blue,
    Color bullishColor = const Color(0xFF4CAF50),
    Color bearishColor = const Color(0xFFF44336),
  }) {
    return CurrentPriceIndicatorStyle(
      lineColor: lineColor,
      lineStyle: LineStyle.dotted,
      bullishColor: bullishColor,
      bearishColor: bearishColor,
    );
  }

  /// Create a **fully hidden** current price indicator.
  ///
  /// Neither line nor label is rendered.
  factory CurrentPriceIndicatorStyle.hidden() {
    return const CurrentPriceIndicatorStyle(
      showLine: false,
      showLabel: false,
    );
  }

  /// Create a modified copy while preserving immutability.
  CurrentPriceIndicatorStyle copyWith({
    bool? showLine,
    bool? showLabel,
    Color? lineColor,
    double? lineWidth,
    LineStyle? lineStyle,
    Color? bullishColor,
    Color? bearishColor,
    Color? textColor,
    double? labelFontSize,
    double? labelPaddingH,
    double? labelPaddingV,
    double? labelBorderRadius,
  }) {
    return CurrentPriceIndicatorStyle(
      showLine: showLine ?? this.showLine,
      showLabel: showLabel ?? this.showLabel,
      lineColor: lineColor ?? this.lineColor,
      lineWidth: lineWidth ?? this.lineWidth,
      lineStyle: lineStyle ?? this.lineStyle,
      bullishColor: bullishColor ?? this.bullishColor,
      bearishColor: bearishColor ?? this.bearishColor,
      textColor: textColor ?? this.textColor,
      labelFontSize: labelFontSize ?? this.labelFontSize,
      labelPaddingH: labelPaddingH ?? this.labelPaddingH,
      labelPaddingV: labelPaddingV ?? this.labelPaddingV,
      labelBorderRadius: labelBorderRadius ?? this.labelBorderRadius,
    );
  }

  /// Equality override ensures repaint correctness.
  ///
  /// Any visual change → repaint.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrentPriceIndicatorStyle &&
          runtimeType == other.runtimeType &&
          showLine == other.showLine &&
          showLabel == other.showLabel &&
          lineColor == other.lineColor &&
          lineWidth == other.lineWidth &&
          lineStyle == other.lineStyle &&
          bullishColor == other.bullishColor &&
          bearishColor == other.bearishColor &&
          textColor == other.textColor &&
          labelFontSize == other.labelFontSize &&
          labelPaddingH == other.labelPaddingH &&
          labelPaddingV == other.labelPaddingV &&
          labelBorderRadius == other.labelBorderRadius;

  @override
  int get hashCode =>
      showLine.hashCode ^
      showLabel.hashCode ^
      lineColor.hashCode ^
      lineWidth.hashCode ^
      lineStyle.hashCode ^
      bullishColor.hashCode ^
      bearishColor.hashCode ^
      textColor.hashCode ^
      labelFontSize.hashCode ^
      labelPaddingH.hashCode ^
      labelPaddingV.hashCode ^
      labelBorderRadius.hashCode;
}
