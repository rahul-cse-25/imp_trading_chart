import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// CHART LAYOUT MODEL
/// ---------------------------------------------------------------------------
///
/// Centralized layout configuration for **all spacing and positioning**
/// used by the chart rendering pipeline.
///
/// This class defines **where space exists**, not **how things are drawn**.
/// Rendering logic (painter, engine, mapper) consumes this layout
/// but never mutates it.
///
/// ### Design Goals
/// - Match TradingView-style spacing and alignment
/// - Keep layout declarative and immutable
/// - Allow pixel-perfect customization without touching rendering logic
/// - Ensure consistent spacing between:
///   - Chart content
///   - Grid lines
///   - Axis labels
///   - Current price label
///   - Ripple / pulse effects
///
/// ### Mental Model
/// Think of `ChartLayout` like a **CSS box model** for the chart.
///
/// ```
/// ┌─────────────────────────────────────────────┐
/// │ Chart Container                             │
/// │                                             │
/// │  ┌─────────────────────────────────────┐   │
/// │  │ chartDataPadding (top/left/right)   │   │
/// │  │  ┌───────────────────────────────┐  │   │
/// │  │  │                               │  │   │
/// │  │  │   CHART CONTENT AREA           │  │   │
/// │  │  │   (grid, lines, ripple)        │  │   │
/// │  │  │                               │  │   │
/// │  │  └───────────────────────────────┘  │   │
/// │  │ chartDataPadding (bottom)           │   │
/// │  └─────────────────────────────────────┘   │
/// │                                             │
/// │  xAxisGap                                   │
/// │  ┌─────────────────────────────────────┐   │
/// │  │ xAxisLabelPadding                    │   │
/// │  │ Time Labels                          │   │
/// │  └─────────────────────────────────────┘   │
/// │                                             │
/// │                          yAxisGap → ┌────┐ │
/// │                                      │Price│
/// │                                      │Labels│
/// │                                      └────┘ │
/// └─────────────────────────────────────────────┘
/// ```
///
/// ### Important
/// - This class contains **NO rendering logic**
/// - It is safe to expose publicly
/// - Equality is overridden so painters can efficiently detect changes
@immutable
class ChartLayout {
  /// Padding around the **chart content area**.
  ///
  /// This padding applies to:
  /// - Grid lines
  /// - Chart lines / candles
  /// - Ripple & pulse effects
  ///
  /// It does **NOT** include axis labels.
  ///
  /// Default: `EdgeInsets.all(10)`
  final EdgeInsets chartDataPadding;

  /// Horizontal gap between the chart content area and Y-axis labels.
  ///
  /// This is the space **outside** the chart where price labels live.
  ///
  /// Used by:
  /// - Grid extension logic
  /// - Current price label positioning
  ///
  /// Default: `8.0`
  final double yAxisGap;

  /// Vertical gap between the chart content area and X-axis labels.
  ///
  /// This creates breathing room between the chart and time labels.
  ///
  /// Default: `4.0`
  final double xAxisGap;

  /// Padding **inside** the Y-axis label area.
  ///
  /// This controls spacing around individual price labels,
  /// not the gap from the chart.
  ///
  /// Used by:
  /// - Price labels
  /// - Current price label
  ///
  /// Default: `EdgeInsets.symmetric(horizontal: 6, vertical: 2)`
  final EdgeInsets yAxisLabelPadding;

  /// Padding **inside** the X-axis label area.
  ///
  /// Controls vertical spacing around time labels.
  ///
  /// Default: `EdgeInsets.symmetric(vertical: 4)`
  final EdgeInsets xAxisLabelPadding;

  /// Vertical gap between the current price label and ripple circle.
  ///
  /// Prevents overlap when:
  /// - Ripple animation is active
  /// - Current price label is visible
  ///
  /// Default: `4.0`
  final double currentPriceLabelGap;

  /// Horizontal gap between grid line end and Y-axis label start.
  ///
  /// This creates the TradingView-style visual connection where
  /// grid lines almost touch labels without overlapping.
  ///
  /// Used by:
  /// - Horizontal grid lines
  /// - Current price line
  ///
  /// Default: `4.0`
  final double gridToLabelGapY;

  /// Vertical gap between grid line end and X-axis label start.
  ///
  /// Used by:
  /// - Vertical grid lines
  /// - Time label alignment
  ///
  /// Default: `4.0`
  final double gridToLabelGapX;

  /// Creates an immutable chart layout configuration.
  ///
  /// All parameters are optional and default to
  /// TradingView-inspired values.
  const ChartLayout({
    this.chartDataPadding = const EdgeInsets.all(10.0),
    this.yAxisGap = 8.0,
    this.xAxisGap = 4.0,
    this.yAxisLabelPadding =
        const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
    this.xAxisLabelPadding = const EdgeInsets.symmetric(vertical: 4.0),
    this.currentPriceLabelGap = 4.0,
    this.gridToLabelGapY = 4.0,
    this.gridToLabelGapX = 4.0,
  });

  /// Creates a modified copy of this layout.
  ///
  /// Follows Flutter's immutable pattern:
  /// - Original instance is untouched
  /// - New instance reuses unchanged values
  ///
  /// This is typically used inside `ChartStyle.copyWith`.
  ChartLayout copyWith({
    EdgeInsets? chartDataPadding,
    double? yAxisGap,
    double? xAxisGap,
    EdgeInsets? yAxisLabelPadding,
    EdgeInsets? xAxisLabelPadding,
    double? currentPriceLabelGap,
    double? gridToLabelGapY,
    double? gridToLabelGapX,
  }) {
    return ChartLayout(
      chartDataPadding: chartDataPadding ?? this.chartDataPadding,
      yAxisGap: yAxisGap ?? this.yAxisGap,
      xAxisGap: xAxisGap ?? this.xAxisGap,
      yAxisLabelPadding: yAxisLabelPadding ?? this.yAxisLabelPadding,
      xAxisLabelPadding: xAxisLabelPadding ?? this.xAxisLabelPadding,
      currentPriceLabelGap: currentPriceLabelGap ?? this.currentPriceLabelGap,
      gridToLabelGapY: gridToLabelGapY ?? this.gridToLabelGapY,
      gridToLabelGapX: gridToLabelGapX ?? this.gridToLabelGapX,
    );
  }

  /// Equality is critical for render optimization.
  ///
  /// If layout does not change, painters can skip expensive redraws.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartLayout &&
          runtimeType == other.runtimeType &&
          chartDataPadding == other.chartDataPadding &&
          yAxisGap == other.yAxisGap &&
          xAxisGap == other.xAxisGap &&
          yAxisLabelPadding == other.yAxisLabelPadding &&
          xAxisLabelPadding == other.xAxisLabelPadding &&
          currentPriceLabelGap == other.currentPriceLabelGap &&
          gridToLabelGapY == other.gridToLabelGapY &&
          gridToLabelGapX == other.gridToLabelGapX;

  @override
  int get hashCode =>
      chartDataPadding.hashCode ^
      yAxisGap.hashCode ^
      xAxisGap.hashCode ^
      yAxisLabelPadding.hashCode ^
      xAxisLabelPadding.hashCode ^
      currentPriceLabelGap.hashCode ^
      gridToLabelGapY.hashCode ^
      gridToLabelGapX.hashCode;
}
