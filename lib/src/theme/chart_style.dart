import 'package:flutter/material.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart'
    show
        LineChartStyle,
        CurrentPriceIndicatorStyle,
        RippleAnimationStyle,
        PriceLabelStyle,
        TimeLabelStyle,
        AxisStyle,
        ChartLayout,
        CrosshairStyle;
import 'package:imp_trading_chart/src/theme/trading_colors.dart'
    show TradingColors;

/// Chart styling configuration
///
/// Provides comprehensive styling for all chart elements using organized sub-models:
///
/// **Core Properties:**
/// - [backgroundColor] - Chart background color
/// - [textColor] - Default text color for labels
/// - [labelFontSize] - Base font size for labels
///
/// **Sub-Models:**
/// - [lineStyle] - Line chart appearance (color, width, glow, smooth curves)
/// - [currentPriceStyle] - Current price indicator (line, label, colors)
/// - [rippleStyle] - Pulse animation on latest point
/// - [crosshairStyle] - Touch/hover tracking crosshair
/// - [priceLabelStyle] - Y-axis price labels
/// - [timeLabelStyle] - X-axis time labels
/// - [axisStyle] - Grid lines and axis styling
/// - [layout] - Spacing and padding configuration
class ChartStyle {
  // ============================================================================
  // CORE PROPERTIES
  // ============================================================================

  /// Background color of the chart
  final Color backgroundColor;

  /// Default text color for labels
  final Color textColor;

  /// Base font size for labels
  final double labelFontSize;

  // ============================================================================
  // SUB-MODELS
  // ============================================================================

  /// Styling for the main chart line
  final LineChartStyle lineStyle;

  /// Styling for the current price indicator
  final CurrentPriceIndicatorStyle currentPriceStyle;

  /// Styling for the ripple/pulse animation
  final RippleAnimationStyle rippleStyle;

  /// Styling for Y-axis price labels
  final PriceLabelStyle priceLabelStyle;

  /// Styling for X-axis time labels
  final TimeLabelStyle timeLabelStyle;

  /// Styling for grid lines and axes
  final AxisStyle axisStyle;

  /// Layout configuration (spacing, padding)
  final ChartLayout layout;

  /// Styling for crosshair (touch tracking)
  final CrosshairStyle crosshairStyle;

  ChartStyle({
    // Core properties
    this.backgroundColor = Colors.black,
    this.textColor = Colors.white,
    this.labelFontSize = 10.0,
    // Sub-models with defaults
    LineChartStyle? lineStyle,
    CurrentPriceIndicatorStyle? currentPriceStyle,
    RippleAnimationStyle? rippleStyle,
    PriceLabelStyle? priceLabelStyle,
    TimeLabelStyle? timeLabelStyle,
    AxisStyle? axisStyle,
    ChartLayout? layout,
    CrosshairStyle? crosshairStyle,
  })  : lineStyle = lineStyle ?? const LineChartStyle(),
        currentPriceStyle =
            currentPriceStyle ?? const CurrentPriceIndicatorStyle(),
        rippleStyle = rippleStyle ?? const RippleAnimationStyle(),
        priceLabelStyle = priceLabelStyle ?? PriceLabelStyle(),
        timeLabelStyle = timeLabelStyle ?? TimeLabelStyle(),
        axisStyle = axisStyle ?? const AxisStyle(),
        layout = layout ?? const ChartLayout(),
        crosshairStyle = crosshairStyle ?? const CrosshairStyle();

  // ============================================================================
  // FACTORY CONSTRUCTORS
  // ============================================================================

  /// Create a minimal chart style (just line, no labels, grid, or animations)
  factory ChartStyle.minimal({
    Color backgroundColor = Colors.transparent,
    Color lineColor = const Color.fromRGBO(15, 173, 0, 1),
    double lineWidth = 2.0,
    bool showLineGlow = true,
  }) {
    return ChartStyle(
      backgroundColor: backgroundColor,
      lineStyle: LineChartStyle(
        color: lineColor,
        width: lineWidth,
        showGlow: showLineGlow,
        glowWidth: 1.0,
      ),
      currentPriceStyle: CurrentPriceIndicatorStyle.hidden(),
      rippleStyle: RippleAnimationStyle.hidden(),
      priceLabelStyle: const PriceLabelStyle(show: false),
      timeLabelStyle: const TimeLabelStyle(show: false),
      axisStyle: const AxisStyle(showGrid: false),
      crosshairStyle: const CrosshairStyle(show: false),
    );
  }

  /// Create a simple chart style (line with basic labels)
  factory ChartStyle.simple({
    Color backgroundColor = Colors.transparent,
    Color textColor = Colors.white,
    Color lineColor = Colors.blue,
    double lineWidth = 2.0,
    Color currentPriceLineColor = const Color.fromRGBO(15, 173, 0, 1),
  }) {
    return ChartStyle(
      backgroundColor: backgroundColor,
      textColor: textColor,
      lineStyle: LineChartStyle(
        color: lineColor,
        width: lineWidth,
      ),
      currentPriceStyle: CurrentPriceIndicatorStyle.dashed(
        lineColor: currentPriceLineColor,
      ).copyWith(labelFontSize: 10.0),
      rippleStyle: RippleAnimationStyle.hidden(),
      axisStyle: const AxisStyle(showGrid: false),
      crosshairStyle: const CrosshairStyle(show: false),
      // Uses default ChartLayout which now has sensible padding
    );
  }

  /// Create a trading chart style (full featured with all bells and whistles)
  factory ChartStyle.trading({
    Color backgroundColor = Colors.transparent,
    Color lineColor = TradingColors.bullish,
    Color pulseColor = TradingColors.bullish,
    bool showCrosshair = true,
  }) {
    return ChartStyle(
        backgroundColor: backgroundColor,
        lineStyle: LineChartStyle(
          color: lineColor,
          width: 2.5,
          showGlow: true,
          glowWidth: 1.5,
        ),
        currentPriceStyle: CurrentPriceIndicatorStyle.dotted(
          lineColor: lineColor,
          bullishColor: TradingColors.bullish,
          bearishColor: TradingColors.bearish,
        ).copyWith(labelFontSize: 10.0),
        rippleStyle: RippleAnimationStyle(color: pulseColor),
        axisStyle: const AxisStyle(showGrid: false),
        crosshairStyle: CrosshairStyle.dotted(),
        layout:
            ChartLayout(chartDataPadding: EdgeInsets.fromLTRB(10, 30, 10, 10)));
  }

  /// Create a compact chart style (optimized for small spaces)
  factory ChartStyle.compact({
    Color backgroundColor = Colors.transparent,
    Color lineColor = Colors.blue,
    bool showGrid = true,
    bool showPriceLabels = true,
    bool showTimeLabels = true,
  }) {
    return ChartStyle(
      backgroundColor: backgroundColor,
      textColor: Colors.white70,
      labelFontSize: 8.0,
      lineStyle: LineChartStyle(
        color: lineColor,
        width: 1.0,
      ),
      currentPriceStyle: CurrentPriceIndicatorStyle.dotted(
        lineColor: const Color.fromRGBO(15, 173, 0, 1),
      ).copyWith(labelFontSize: 8.0),
      rippleStyle: RippleAnimationStyle(color: lineColor),
      priceLabelStyle: PriceLabelStyle(show: showPriceLabels, fontSize: 8.0),
      timeLabelStyle: TimeLabelStyle(show: showTimeLabels, fontSize: 8.0),
      axisStyle: AxisStyle(
        showGrid: showGrid,
        yAxisPadding: 3.0,
        xAxisPadding: 3.0,
      ),
      crosshairStyle: const CrosshairStyle(show: false),
      layout: const ChartLayout(
        currentPriceLabelGap: 6,
        yAxisLabelPadding: EdgeInsets.only(left: 6),
        xAxisLabelPadding: EdgeInsets.symmetric(vertical: 3.0),
      ),
    );
  }

  ChartStyle copyWith({
    Color? backgroundColor,
    Color? textColor,
    double? labelFontSize,
    LineChartStyle? lineStyle,
    CurrentPriceIndicatorStyle? currentPriceStyle,
    RippleAnimationStyle? rippleStyle,
    PriceLabelStyle? priceLabelStyle,
    TimeLabelStyle? timeLabelStyle,
    AxisStyle? axisStyle,
    ChartLayout? layout,
    CrosshairStyle? crosshairStyle,
  }) {
    return ChartStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      labelFontSize: labelFontSize ?? this.labelFontSize,
      lineStyle: lineStyle ?? this.lineStyle,
      currentPriceStyle: currentPriceStyle ?? this.currentPriceStyle,
      rippleStyle: rippleStyle ?? this.rippleStyle,
      priceLabelStyle: priceLabelStyle ?? this.priceLabelStyle,
      timeLabelStyle: timeLabelStyle ?? this.timeLabelStyle,
      axisStyle: axisStyle ?? this.axisStyle,
      layout: layout ?? this.layout,
      crosshairStyle: crosshairStyle ?? this.crosshairStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          textColor == other.textColor &&
          labelFontSize == other.labelFontSize &&
          lineStyle == other.lineStyle &&
          currentPriceStyle == other.currentPriceStyle &&
          rippleStyle == other.rippleStyle &&
          priceLabelStyle == other.priceLabelStyle &&
          timeLabelStyle == other.timeLabelStyle &&
          axisStyle == other.axisStyle &&
          layout == other.layout &&
          crosshairStyle == other.crosshairStyle;

  @override
  int get hashCode =>
      backgroundColor.hashCode ^
      textColor.hashCode ^
      labelFontSize.hashCode ^
      lineStyle.hashCode ^
      currentPriceStyle.hashCode ^
      rippleStyle.hashCode ^
      priceLabelStyle.hashCode ^
      timeLabelStyle.hashCode ^
      axisStyle.hashCode ^
      layout.hashCode ^
      crosshairStyle.hashCode;
}
