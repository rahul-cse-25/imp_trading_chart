import 'package:flutter/material.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart';
import 'package:imp_trading_chart/src/layout/chart_layout.dart'
    show ChartLayout;

/// ---------------------------------------------------------------------------
/// CHART STYLE – MASTER VISUAL CONFIGURATION
/// ---------------------------------------------------------------------------
///
/// `ChartStyle` is the **single source of truth** for all visual configuration
/// used by the chart rendering system.
///
/// ### Core Philosophy
/// - This class is **pure configuration**
/// - It contains **NO rendering logic**
/// - Painters and engines *consume* it but never mutate it
/// - Designed for immutability, composition, and reuse
///
/// ### Mental Model
/// Think of `ChartStyle` as a **theme object**, similar to:
/// - `ThemeData` in Flutter
/// - `TradingView chart settings panel`
///
/// Internally, it is composed of **specialized sub-style models**,
/// each responsible for one visual concern.
///
/// ```
/// ChartStyle
/// ├── LineChartStyle          (main line rendering)
/// ├── CurrentPriceIndicator  (price line + label)
/// ├── RippleAnimationStyle   (pulse on latest price)
/// ├── CrosshairStyle         (touch / hover tracking)
/// ├── PriceLabelStyle        (Y-axis labels)
/// ├── TimeLabelStyle         (X-axis labels)
/// ├── AxisStyle              (grid & axes)
/// └── ChartLayout            (spacing & padding)
/// ```
///
/// ### Why this matters
/// - Makes the chart **fully customizable**
/// - Allows safe public API exposure
/// - Enables performant repaint detection via equality
class ChartStyle {
  // ============================================================================
  // CORE VISUAL PROPERTIES
  // ============================================================================

  /// Background color of the entire chart canvas.
  ///
  /// This color is used by:
  /// - Chart container background
  /// - Label backgrounds (if not overridden)
  ///
  /// Default: `Colors.black`
  final Color backgroundColor;

  /// Default text color for all labels.
  ///
  /// Individual label styles may override this,
  /// but this acts as the base fallback.
  ///
  /// Default: `Colors.white`
  final Color textColor;

  /// Base font size for labels.
  ///
  /// Used when sub-styles do not specify a font size.
  ///
  /// Default: `10.0`
  final double labelFontSize;

  // ============================================================================
  // SUB-STYLES (COMPOSITION)
  // ============================================================================

  /// Styling for the main price line (color, width, glow, smoothing).
  final LineChartStyle lineStyle;

  /// Styling for the current price indicator:
  /// - Horizontal line
  /// - Right-side price label
  final CurrentPriceIndicatorStyle currentPriceStyle;

  /// Styling for the ripple / pulse animation on the latest data point.
  final RippleAnimationStyle rippleStyle;

  /// Styling for Y-axis price labels.
  final PriceLabelStyle priceLabelStyle;

  /// Styling for X-axis time labels.
  final TimeLabelStyle timeLabelStyle;

  /// Styling for grid lines and axes.
  final AxisStyle axisStyle;

  /// Layout configuration (padding, gaps, spacing).
  ///
  /// This controls **where things live**, not how they look.
  final ChartLayout layout;

  /// Styling for crosshair (touch / hover interaction).
  final CrosshairStyle crosshairStyle;

  /// Creates a fully configurable chart style.
  ///
  /// All sub-styles are optional and default to sensible values.
  /// This allows partial overrides without verbose configuration.
  ChartStyle({
    // Core properties
    this.backgroundColor = Colors.black,
    this.textColor = Colors.white,
    this.labelFontSize = 10.0,

    // Sub-models (nullable for convenience)
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
  // PRESET FACTORIES (OPINIONATED CONFIGURATIONS)
  // ============================================================================

  /// Minimal chart style.
  ///
  /// Designed for:
  /// - Sparkline charts
  /// - Background graphs
  /// - Minimal dashboards
  ///
  /// Features:
  /// - Line only
  /// - No grid
  /// - No labels
  /// - No ripple
  /// - No crosshair
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

  /// Simple chart style.
  ///
  /// Designed for:
  /// - Lightweight price charts
  /// - Read-only displays
  ///
  /// Features:
  /// - Line + current price
  /// - Minimal labels
  /// - No ripple
  /// - No crosshair
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
    );
  }

  /// Full-featured trading chart style.
  ///
  /// Designed to resemble professional trading platforms.
  ///
  /// Features:
  /// - Glow line
  /// - Ripple animation
  /// - Current price indicator
  /// - Crosshair interaction
  /// - Optimized spacing
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
      layout: ChartLayout(
        chartDataPadding: EdgeInsets.fromLTRB(10, 30, 10, 10),
      ),
    );
  }

  /// Compact chart style.
  ///
  /// Designed for:
  /// - Small screens
  /// - Dense dashboards
  /// - Embedded widgets
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

  // ============================================================================
  // IMMUTABILITY & PERFORMANCE
  // ============================================================================

  /// Creates a modified copy of this style.
  ///
  /// This is the primary way styles should be changed at runtime.
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

  /// Equality is critical for efficient repaint detection.
  ///
  /// If style does not change, painters can skip redraws.
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
