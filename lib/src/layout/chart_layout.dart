import 'package:flutter/material.dart';

/// Comprehensive layout configuration for chart spacing and positioning.
/// 
/// This model provides fine-grained control over all spacing aspects of the chart,
/// similar to how Flutter's widget tree handles padding and spacing.
/// 
/// Layout structure:
/// ```
/// ┌─────────────────────────────────────────────┐
/// │ Chart Container                             │
/// │  ┌─────────────────────────────────────┐   │
/// │  │ Chart Data Padding (top/left)       │   │
/// │  │  ┌───────────────────────────────┐  │   │
/// │  │  │                               │  │   │
/// │  │  │      Chart Data Area          │  │   │ Y-Axis Gap → ┌──────┐
/// │  │  │      (lines, grid, ripple)    │  │   │               │Price │
/// │  │  │                               │  │   │               │Labels│
/// │  │  └───────────────────────────────┘  │   │               └──────┘
/// │  │ Chart Data Padding (bottom)         │   │
/// │  └─────────────────────────────────────┘   │
/// │  X-Axis Gap (below chart)                  │
/// │  ┌─────────────────────────────────────┐   │
/// │  │ X-Axis Label Padding                │   │
/// │  │ Time Labels                          │   │
/// │  └─────────────────────────────────────┘   │
/// └─────────────────────────────────────────────┘
/// ```
class ChartLayout {
  /// Padding around the chart data area (the actual chart drawing)
  /// This creates space around the grid/line/candle area
  final EdgeInsets chartDataPadding;
  
  /// Gap between chart data area and Y-axis labels (horizontal spacing)
  /// This is the space between the right edge of chart and Y-axis labels
  final double yAxisGap;
  
  /// Gap between chart data area and X-axis labels (vertical spacing)
  /// This is the space between the bottom edge of chart and X-axis labels
  final double xAxisGap;
  
  /// Padding around Y-axis labels (inside the Y-axis area)
  /// This is the padding around individual price labels
  final EdgeInsets yAxisLabelPadding;
  
  /// Padding around X-axis labels (inside the X-axis area)
  /// This is the padding around individual time labels
  final EdgeInsets xAxisLabelPadding;
  
  /// Gap between current price label and ripple circle (to prevent overlap)
  /// This ensures proper spacing when both are visible
  final double currentPriceLabelGap;
  
  /// Gap between grid line end and Y-axis (price) label start
  /// This creates visual connection between grid and labels (TradingView style)
  /// Default: 4.0 pixels - grid extends close to labels
  final double gridToLabelGapY;
  
  /// Gap between grid line end and X-axis (time) label start
  /// This creates visual connection between grid and labels (TradingView style)
  /// Default: 4.0 pixels - grid extends close to labels
  final double gridToLabelGapX;
  
  const ChartLayout({
    this.chartDataPadding = const EdgeInsets.all(10.0),
    this.yAxisGap = 8.0,   // Proper gap between chart data and Y-axis labels
    this.xAxisGap = 4.0,   // Gap between chart data and X-axis labels
    this.yAxisLabelPadding = const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
    this.xAxisLabelPadding = const EdgeInsets.symmetric(vertical: 4.0),
    this.currentPriceLabelGap = 4.0,
    this.gridToLabelGapY = 4.0,  // Grid ends before Y-axis labels
    this.gridToLabelGapX = 4.0,  // Grid ends before X-axis labels
  });
  
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
