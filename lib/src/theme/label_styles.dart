import 'package:flutter/material.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart';
import 'package:imp_trading_chart/src/data/enums.dart' show LineStyle;

// ============================================================================
// LINE CHART STYLE
// ============================================================================

/// Styling for the **main chart line** (data visualization).
///
/// This model defines how the primary price line is rendered by the
/// `ChartPainter`. It is **purely declarative** and contains **no rendering
/// logic** itself.
///
/// Responsibilities:
/// - Define visual appearance of the line
/// - Configure smoothing vs straight segments
/// - Control glow and point markers
///
/// Design principles:
/// - Immutable (safe for repaint comparisons)
/// - Cheap equality checks (used in `shouldRepaint`)
/// - Declarative configuration → imperative rendering
class LineChartStyle {
  /// Color of the chart line.
  ///
  /// Used directly by the painter for:
  /// - Main stroke
  /// - Glow effect (with reduced opacity)
  /// - Point markers (if enabled)
  final Color color;

  /// Width of the chart line stroke.
  ///
  /// This value directly maps to `Paint.strokeWidth`.
  /// Larger values increase visual prominence but may reduce clarity
  /// on dense charts.
  final double width;

  /// Whether to show circular markers at each data point.
  ///
  /// Useful for:
  /// - Sparse datasets
  /// - Debugging data alignment
  /// - Emphasizing discrete samples
  ///
  /// Typically disabled for high-density charts.
  final bool showPoints;

  /// Radius of data point markers.
  ///
  /// Only used when [showPoints] is `true`.
  /// This value is interpreted in logical pixels.
  final double pointRadius;

  /// Whether to show a glow effect behind the line.
  ///
  /// Glow is rendered as:
  /// - A wider stroke
  /// - Lower opacity
  /// - Blur mask
  ///
  /// This improves visibility on dark backgrounds
  /// but has a small GPU cost.
  final bool showGlow;

  /// Width/intensity of the glow effect.
  ///
  /// Internally used as:
  /// - Additional stroke width
  /// - Blur radius multiplier
  ///
  /// Has no effect if [showGlow] is false.
  final double glowWidth;

  /// Whether to render the line using smooth curves instead of straight segments.
  ///
  /// When enabled:
  /// - Uses Cardinal Spline interpolation
  /// - Produces visually pleasing, continuous curves
  ///
  /// When disabled:
  /// - Uses straight `lineTo` segments
  /// - More precise for exact value tracking
  final bool smooth;

  /// Curve smoothness factor when [smooth] is enabled.
  ///
  /// This value controls **tension** of the Cardinal Spline:
  /// - `0.0` → straight lines (no smoothing)
  /// - `0.5` → moderate smoothing
  /// - `1.0` → maximum smoothness (Catmull-Rom behavior)
  ///
  /// Higher values produce smoother but less precise curves.
  final double curveTension;

  /// Default constructor with sensible trading defaults.
  ///
  /// Defaults favor:
  /// - Clear visibility
  /// - Minimal visual noise
  /// - Performance safety
  const LineChartStyle({
    this.color = Colors.blue,
    this.width = 2.0,
    this.showPoints = false,
    this.pointRadius = 3.0,
    this.showGlow = false,
    this.glowWidth = 4.0,
    this.smooth = false,
    this.curveTension = 1.0, // Maximum smoothness by default
  });

  /// Create a **minimal** line style.
  ///
  /// Use cases:
  /// - Performance-critical charts
  /// - Background or sparkline charts
  /// - Charts embedded in dense UI layouts
  factory LineChartStyle.minimal({
    Color color = Colors.blue,
    double width = 2.0,
  }) {
    return LineChartStyle(
      color: color,
      width: width,
      showPoints: false,
      showGlow: false,
      smooth: false,
    );
  }

  /// Create a **glowing** line style.
  ///
  /// Use cases:
  /// - Dark backgrounds
  /// - Highlighting primary series
  /// - Live price emphasis
  factory LineChartStyle.glowing({
    Color color = Colors.blue,
    double width = 2.0,
    double glowWidth = 4.0,
  }) {
    return LineChartStyle(
      color: color,
      width: width,
      showGlow: true,
      glowWidth: glowWidth,
    );
  }

  /// Create a **smooth curved** line style.
  ///
  /// Uses Cardinal Spline interpolation internally.
  ///
  /// This matches visual behavior seen in:
  /// - TradingView
  /// - fl_chart
  /// - Modern financial UIs
  ///
  /// curveTension:
  /// - `0.0` → straight lines
  /// - `1.0` → maximum smoothness
  factory LineChartStyle.smooth({
    Color color = Colors.blue,
    double width = 2.0,
    double curveTension = 1.0,
    bool showGlow = false,
    bool showPoints = false,
    double pointRadius = 3.0,
  }) {
    return LineChartStyle(
      color: color,
      width: width,
      smooth: true,
      curveTension: curveTension,
      showGlow: showGlow,
      showPoints: showPoints,
      pointRadius: pointRadius,
    );
  }

  /// Create a modified copy while preserving immutability.
  ///
  /// Used extensively by:
  /// - `ChartStyle.copyWith`
  /// - Theme overrides
  /// - Animation state changes
  LineChartStyle copyWith({
    Color? color,
    double? width,
    bool? showPoints,
    double? pointRadius,
    bool? showGlow,
    double? glowWidth,
    bool? smooth,
    double? curveTension,
  }) {
    return LineChartStyle(
      color: color ?? this.color,
      width: width ?? this.width,
      showPoints: showPoints ?? this.showPoints,
      pointRadius: pointRadius ?? this.pointRadius,
      showGlow: showGlow ?? this.showGlow,
      glowWidth: glowWidth ?? this.glowWidth,
      smooth: smooth ?? this.smooth,
      curveTension: curveTension ?? this.curveTension,
    );
  }

  /// Equality override is critical for `CustomPainter.shouldRepaint`.
  ///
  /// If any visual property changes, the chart **must repaint**.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineChartStyle &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          width == other.width &&
          showPoints == other.showPoints &&
          pointRadius == other.pointRadius &&
          showGlow == other.showGlow &&
          glowWidth == other.glowWidth &&
          smooth == other.smooth &&
          curveTension == other.curveTension;

  @override
  int get hashCode =>
      color.hashCode ^
      width.hashCode ^
      showPoints.hashCode ^
      pointRadius.hashCode ^
      showGlow.hashCode ^
      glowWidth.hashCode ^
      smooth.hashCode ^
      curveTension.hashCode;
}

// ============================================================================
// Y-AXIS (PRICE) LABEL STYLE
// ============================================================================

/// Styling configuration for **price labels on the Y-axis**.
///
/// This model controls:
/// - Visibility
/// - Typography
/// - Formatting logic
/// - Spacing and layout
///
/// Rendering behavior:
/// - Labels are generated based on visible price range
/// - Positions are evenly distributed unless spacing is overridden
class PriceLabelStyle {
  /// Whether price labels should be rendered.
  final bool show;

  /// Font size of the label text.
  final double fontSize;

  /// Text color of the price labels.
  final Color color;

  /// Optional background color for labels.
  ///
  /// When null, labels are drawn without background.
  final Color? backgroundColor;

  /// Optional font weight.
  final FontWeight? fontWeight;

  /// Vertical spacing between labels.
  ///
  /// If `0.0`, spacing is auto-calculated
  /// based on chart height and labelCount.
  final double spacing;

  /// Number of price labels to show.
  ///
  /// This is a **target count** — actual count may
  /// be adjusted to avoid overlaps.
  final int labelCount;

  /// Formatter used to convert numeric prices into strings.
  ///
  /// Users can inject:
  /// - Currency formatters
  /// - Compact formatters
  /// - Custom domain-specific logic
  final PriceFormatter formatter;

  /// Padding inside each label.
  ///
  /// Affects background size and text positioning.
  final EdgeInsets padding;

  /// Optional text alignment override.
  final TextAlign? textAlign;

  /// Default constructor using smart formatting.
  ///
  /// Designed for:
  /// - Dark trading UIs
  /// - Compact but readable labels
  const PriceLabelStyle({
    this.show = true,
    this.fontSize = 10.0,
    this.color = const Color(0xCCFFFFFF),
    this.backgroundColor,
    this.fontWeight,
    this.spacing = 0.0,
    this.labelCount = 5,
    this.formatter = const DefaultPriceFormatter(),
    this.padding = const EdgeInsets.only(left: 5.0, right: 5.0),
    this.textAlign,
  });

  /// Creates a modified copy while preserving immutability.
  PriceLabelStyle copyWith({
    bool? show,
    double? fontSize,
    Color? color,
    Color? backgroundColor,
    FontWeight? fontWeight,
    double? spacing,
    int? labelCount,
    PriceFormatter? formatter,
    EdgeInsets? padding,
    TextAlign? textAlign,
  }) {
    return PriceLabelStyle(
      show: show ?? this.show,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontWeight: fontWeight ?? this.fontWeight,
      spacing: spacing ?? this.spacing,
      labelCount: labelCount ?? this.labelCount,
      formatter: formatter ?? this.formatter,
      padding: padding ?? this.padding,
      textAlign: textAlign ?? this.textAlign,
    );
  }
}

// ============================================================================
// X-AXIS (TIME) LABEL STYLE
// ============================================================================

/// Styling configuration for **time labels on the X-axis**.
///
/// Time labels are:
/// - Context-aware (zoom level)
/// - Responsive to visible time span
/// - Usually fewer to avoid collisions
class TimeLabelStyle {
  final bool show;
  final double fontSize;
  final Color color;
  final Color? backgroundColor;
  final FontWeight? fontWeight;

  /// Number of time labels to show.
  ///
  /// Default is intentionally low to prevent overlap
  /// on small screens.
  final int labelCount;

  /// Formatter responsible for timestamp → string conversion.
  ///
  /// Receives `TimeFormatContext` to enable
  /// responsive formatting (TradingView-style).
  final TimeFormatter formatter;

  /// Padding inside each label.
  final EdgeInsets padding;

  final TextAlign? textAlign;

  /// Default constructor using responsive formatter.
  const TimeLabelStyle({
    this.show = true,
    this.fontSize = 10.0,
    this.color = const Color(0xCCFFFFFF),
    this.backgroundColor,
    this.fontWeight,
    this.labelCount = 3,
    this.formatter = const DefaultTimeFormatter(),
    this.padding = const EdgeInsets.only(top: 5.0, bottom: 5.0),
    this.textAlign,
  });

  TimeLabelStyle copyWith({
    bool? show,
    double? fontSize,
    Color? color,
    Color? backgroundColor,
    FontWeight? fontWeight,
    int? labelCount,
    TimeFormatter? formatter,
    EdgeInsets? padding,
    TextAlign? textAlign,
  }) {
    return TimeLabelStyle(
      show: show ?? this.show,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontWeight: fontWeight ?? this.fontWeight,
      labelCount: labelCount ?? this.labelCount,
      formatter: formatter ?? this.formatter,
      padding: padding ?? this.padding,
      textAlign: textAlign ?? this.textAlign,
    );
  }
}

// ============================================================================
// AXIS & GRID STYLE
// ============================================================================

/// Styling for chart grid lines and axis spacing.
///
/// This class defines **visual scaffolding** of the chart:
/// - Grid visibility
/// - Grid density
/// - Label offsets
class AxisStyle {
  /// Whether grid lines should be drawn.
  final bool showGrid;

  /// Color of grid lines.
  ///
  /// Typically low opacity to avoid overpowering data.
  final Color gridColor;

  /// Stroke width of grid lines.
  final double gridLineWidth;

  /// Style of grid lines (solid / dashed / dotted).
  final LineStyle gridLineStyle;

  /// Number of horizontal grid lines.
  ///
  /// Typically matches price label count.
  final int horizontalGridLines;

  /// Number of vertical grid lines.
  ///
  /// `0` means auto-calculate based on visible candles.
  final int verticalGridLines;

  /// Padding between chart content and Y-axis labels.
  final double yAxisPadding;

  /// Padding between chart content and X-axis labels.
  final double xAxisPadding;

  const AxisStyle({
    this.showGrid = true,
    this.gridColor = const Color(0x33FFFFFF),
    this.gridLineWidth = 0.5,
    this.gridLineStyle = LineStyle.solid,
    this.horizontalGridLines = 5,
    this.verticalGridLines = 0,
    this.yAxisPadding = 5.0,
    this.xAxisPadding = 5.0,
  });

  AxisStyle copyWith({
    bool? showGrid,
    Color? gridColor,
    double? gridLineWidth,
    LineStyle? gridLineStyle,
    int? horizontalGridLines,
    int? verticalGridLines,
    double? yAxisPadding,
    double? xAxisPadding,
  }) {
    return AxisStyle(
      showGrid: showGrid ?? this.showGrid,
      gridColor: gridColor ?? this.gridColor,
      gridLineWidth: gridLineWidth ?? this.gridLineWidth,
      gridLineStyle: gridLineStyle ?? this.gridLineStyle,
      horizontalGridLines: horizontalGridLines ?? this.horizontalGridLines,
      verticalGridLines: verticalGridLines ?? this.verticalGridLines,
      yAxisPadding: yAxisPadding ?? this.yAxisPadding,
      xAxisPadding: xAxisPadding ?? this.xAxisPadding,
    );
  }
}
