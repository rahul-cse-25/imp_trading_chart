import 'package:flutter/material.dart';
import 'package:imp_trading_chart/src/data/enums.dart' show LineStyle;

/// Comprehensive styling configuration for the **crosshair**
/// (touch / hover / long-press tracking).
///
/// The crosshair is an *interactive overlay*, not part of the core chart data.
/// It is rendered **on top of everything else** and is typically driven by
/// gesture input (long press, drag, hover).
///
/// This style controls:
/// - Vertical & horizontal guide lines
/// - Intersection tracker point
/// - Price label (right side)
/// - Time label (bottom)
///
/// Design principles:
/// - Entirely **stateless configuration**
/// - Painter decides *when* to draw, this decides *how*
/// - Immutable for safe repaint comparison
class CrosshairStyle {
  /// Whether the crosshair should be rendered at all.
  ///
  /// When `false`:
  /// - Gesture detection may still occur
  /// - Painter will skip **all** crosshair drawing
  ///
  /// This is important for:
  /// - Read-only charts
  /// - Compact or preview charts
  final bool show;

  // ===========================================================================
  // LINE STYLING
  // ===========================================================================

  /// Color of the **vertical** crosshair line.
  ///
  /// This line typically tracks:
  /// - Time (X-axis)
  /// - Candle index
  final Color verticalLineColor;

  /// Color of the **horizontal** crosshair line.
  ///
  /// This line tracks:
  /// - Price (Y-axis)
  final Color horizontalLineColor;

  /// Stroke width of the vertical line.
  ///
  /// Thin lines are preferred to avoid overpowering data.
  final double verticalLineWidth;

  /// Stroke width of the horizontal line.
  final double horizontalLineWidth;

  /// Stroke style of the vertical line.
  ///
  /// Uses the same enum as grid & price lines to keep
  /// visuals consistent across the chart.
  final LineStyle verticalLineStyle;

  /// Stroke style of the horizontal line.
  final LineStyle horizontalLineStyle;

  // ===========================================================================
  // TRACKER POINT STYLING
  // ===========================================================================

  /// Fill color of the tracker point at the intersection.
  ///
  /// This point marks the **exact data value** under the crosshair.
  final Color trackerColor;

  /// Radius of the tracker point.
  ///
  /// This is usually larger than data point markers
  /// for better touch feedback.
  final double trackerRadius;

  /// Whether to draw an **outer ring** around the tracker point.
  ///
  /// Helps with visibility on busy charts.
  final bool showTrackerRing;

  /// Color of the tracker ring stroke.
  final Color trackerRingColor;

  /// Stroke width of the tracker ring.
  final double trackerRingWidth;

  // ===========================================================================
  // LABEL STYLING (PRICE & TIME)
  // ===========================================================================

  /// Background color for **both** price and time labels.
  ///
  /// Typically opaque for contrast against chart data.
  final Color labelBackgroundColor;

  /// Text color for price and time labels.
  final Color labelTextColor;

  /// Font size for crosshair labels.
  ///
  /// If `null`, the painter will inherit `ChartStyle.labelFontSize`.
  /// This allows global sizing with optional overrides.
  final double? labelFontSize;

  /// Font weight for label text.
  ///
  /// Default is bold to differentiate from axis labels.
  final FontWeight labelFontWeight;

  /// Corner radius for label backgrounds.
  ///
  /// Small radius gives TradingView-like pill labels.
  final double labelBorderRadius;

  /// Horizontal padding inside labels.
  final double labelPaddingH;

  /// Vertical padding inside labels.
  final double labelPaddingV;

  /// Whether to show the **price label** on the right Y-axis.
  final bool showPriceLabel;

  /// Whether to show the **time label** at the bottom X-axis.
  final bool showTimeLabel;

  /// Default constructor with TradingView-style defaults.
  ///
  /// Tuned for:
  /// - Dark backgrounds
  /// - Subtle guides
  /// - High contrast labels
  const CrosshairStyle({
    this.show = true,

    // Line styling
    this.verticalLineColor = const Color.fromRGBO(255, 255, 255, 0.5),
    this.horizontalLineColor = const Color.fromRGBO(255, 255, 255, 0.5),
    this.verticalLineWidth = 1.0,
    this.horizontalLineWidth = 1.0,
    this.verticalLineStyle = LineStyle.solid,
    this.horizontalLineStyle = LineStyle.solid,

    // Tracker point styling
    this.trackerColor = Colors.white,
    this.trackerRadius = 5.0,
    this.showTrackerRing = true,
    this.trackerRingColor = const Color.fromRGBO(255, 255, 255, 0.3),
    this.trackerRingWidth = 2.0,

    // Label styling
    this.labelBackgroundColor = Colors.white,
    this.labelTextColor = Colors.black,
    this.labelFontSize, // null = inherit from chart
    this.labelFontWeight = FontWeight.bold,
    this.labelBorderRadius = 3.0,
    this.labelPaddingH = 4.0,
    this.labelPaddingV = 3.0,
    this.showPriceLabel = true,
    this.showTimeLabel = true,
  });

  /// Creates a **uniform crosshair** where both lines share the same style.
  ///
  /// Useful for:
  /// - Minimal UIs
  /// - Theme-driven styling
  factory CrosshairStyle.uniform({
    Color lineColor = const Color.fromRGBO(255, 255, 255, 0.5),
    double lineWidth = 1.0,
    LineStyle lineStyle = LineStyle.solid,
    Color trackerColor = Colors.white,
    double trackerRadius = 5.0,
    Color labelBackgroundColor = Colors.white,
    Color labelTextColor = Colors.black,
    double? labelFontSize,
  }) {
    return CrosshairStyle(
      verticalLineColor: lineColor,
      horizontalLineColor: lineColor,
      verticalLineWidth: lineWidth,
      horizontalLineWidth: lineWidth,
      verticalLineStyle: lineStyle,
      horizontalLineStyle: lineStyle,
      trackerColor: trackerColor,
      trackerRadius: trackerRadius,
      labelBackgroundColor: labelBackgroundColor,
      labelTextColor: labelTextColor,
      labelFontSize: labelFontSize,
    );
  }

  /// Creates a dashed crosshair.
  ///
  /// Often used to visually distinguish crosshair from grid lines.
  factory CrosshairStyle.dashed({
    Color lineColor = const Color.fromRGBO(255, 255, 255, 0.5),
    double lineWidth = 1.0,
  }) {
    return CrosshairStyle(
      verticalLineColor: lineColor,
      horizontalLineColor: lineColor,
      verticalLineWidth: lineWidth,
      horizontalLineWidth: lineWidth,
      verticalLineStyle: LineStyle.dashed,
      horizontalLineStyle: LineStyle.dashed,
    );
  }

  /// Creates a dotted crosshair.
  ///
  /// Often used for subtle hover interactions.
  factory CrosshairStyle.dotted({
    Color lineColor = const Color.fromRGBO(255, 255, 255, 0.5),
    double lineWidth = 1.0,
  }) {
    return CrosshairStyle(
      verticalLineColor: lineColor,
      horizontalLineColor: lineColor,
      verticalLineWidth: lineWidth,
      horizontalLineWidth: lineWidth,
      verticalLineStyle: LineStyle.dotted,
      horizontalLineStyle: LineStyle.dotted,
    );
  }

  /// Creates a modified copy while preserving immutability.
  ///
  /// This is critical for:
  /// - Theme overrides
  /// - Gesture-driven updates
  /// - Correct repaint detection
  CrosshairStyle copyWith({
    bool? show,
    Color? verticalLineColor,
    Color? horizontalLineColor,
    double? verticalLineWidth,
    double? horizontalLineWidth,
    LineStyle? verticalLineStyle,
    LineStyle? horizontalLineStyle,
    Color? trackerColor,
    double? trackerRadius,
    bool? showTrackerRing,
    Color? trackerRingColor,
    double? trackerRingWidth,
    Color? labelBackgroundColor,
    Color? labelTextColor,
    double? labelFontSize,
    FontWeight? labelFontWeight,
    double? labelBorderRadius,
    double? labelPaddingH,
    double? labelPaddingV,
    bool? showPriceLabel,
    bool? showTimeLabel,
  }) {
    return CrosshairStyle(
      show: show ?? this.show,
      verticalLineColor: verticalLineColor ?? this.verticalLineColor,
      horizontalLineColor: horizontalLineColor ?? this.horizontalLineColor,
      verticalLineWidth: verticalLineWidth ?? this.verticalLineWidth,
      horizontalLineWidth: horizontalLineWidth ?? this.horizontalLineWidth,
      verticalLineStyle: verticalLineStyle ?? this.verticalLineStyle,
      horizontalLineStyle: horizontalLineStyle ?? this.horizontalLineStyle,
      trackerColor: trackerColor ?? this.trackerColor,
      trackerRadius: trackerRadius ?? this.trackerRadius,
      showTrackerRing: showTrackerRing ?? this.showTrackerRing,
      trackerRingColor: trackerRingColor ?? this.trackerRingColor,
      trackerRingWidth: trackerRingWidth ?? this.trackerRingWidth,
      labelBackgroundColor: labelBackgroundColor ?? this.labelBackgroundColor,
      labelTextColor: labelTextColor ?? this.labelTextColor,
      labelFontSize: labelFontSize ?? this.labelFontSize,
      labelFontWeight: labelFontWeight ?? this.labelFontWeight,
      labelBorderRadius: labelBorderRadius ?? this.labelBorderRadius,
      labelPaddingH: labelPaddingH ?? this.labelPaddingH,
      labelPaddingV: labelPaddingV ?? this.labelPaddingV,
      showPriceLabel: showPriceLabel ?? this.showPriceLabel,
      showTimeLabel: showTimeLabel ?? this.showTimeLabel,
    );
  }

  /// Strict equality ensures:
  /// - Correct repaint decisions
  /// - No unnecessary frame redraws
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrosshairStyle &&
          runtimeType == other.runtimeType &&
          show == other.show &&
          verticalLineColor == other.verticalLineColor &&
          horizontalLineColor == other.horizontalLineColor &&
          verticalLineWidth == other.verticalLineWidth &&
          horizontalLineWidth == other.horizontalLineWidth &&
          verticalLineStyle == other.verticalLineStyle &&
          horizontalLineStyle == other.horizontalLineStyle &&
          trackerColor == other.trackerColor &&
          trackerRadius == other.trackerRadius &&
          showTrackerRing == other.showTrackerRing &&
          trackerRingColor == other.trackerRingColor &&
          trackerRingWidth == other.trackerRingWidth &&
          labelBackgroundColor == other.labelBackgroundColor &&
          labelTextColor == other.labelTextColor &&
          labelFontSize == other.labelFontSize &&
          labelFontWeight == other.labelFontWeight &&
          labelBorderRadius == other.labelBorderRadius &&
          labelPaddingH == other.labelPaddingH &&
          labelPaddingV == other.labelPaddingV &&
          showPriceLabel == other.showPriceLabel &&
          showTimeLabel == other.showTimeLabel;

  @override
  int get hashCode =>
      show.hashCode ^
      verticalLineColor.hashCode ^
      horizontalLineColor.hashCode ^
      verticalLineWidth.hashCode ^
      horizontalLineWidth.hashCode ^
      verticalLineStyle.hashCode ^
      horizontalLineStyle.hashCode ^
      trackerColor.hashCode ^
      trackerRadius.hashCode ^
      showTrackerRing.hashCode ^
      trackerRingColor.hashCode ^
      trackerRingWidth.hashCode ^
      labelBackgroundColor.hashCode ^
      labelTextColor.hashCode ^
      (labelFontSize?.hashCode ?? 0) ^
      labelFontWeight.hashCode ^
      labelBorderRadius.hashCode ^
      labelPaddingH.hashCode ^
      labelPaddingV.hashCode ^
      showPriceLabel.hashCode ^
      showTimeLabel.hashCode;
}
