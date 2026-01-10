import 'package:flutter/material.dart';
import 'package:imp_trading_chart/src/formatters/price_formatter.dart' show PriceFormatter;
import 'package:imp_trading_chart/src/formatters/time_formatter.dart' show TimeFormatter, TimeFormatContext;

/// Default const price formatter for PriceLabelStyle
class _DefaultPriceFormatter implements PriceFormatter {
    const _DefaultPriceFormatter();

    @override
    String format(double price) {
        final absPrice = price.abs();
        final isNegative = price < 0;
        final sign = isNegative ? '-' : '';
        const symbol = '\$';
        const decimals = 2;

        if (absPrice < 1000) {
            return '$sign$symbol${absPrice.toStringAsFixed(decimals)}';
        }
        if (absPrice >= 1e9) {
            return '$sign$symbol${(absPrice / 1e9).toStringAsFixed(decimals)}B';
        } else if (absPrice >= 1e6) {
            return '$sign$symbol${(absPrice / 1e6).toStringAsFixed(decimals)}M';
        } else if (absPrice >= 1e3) {
            return '$sign$symbol${(absPrice / 1e3).toStringAsFixed(decimals)}K';
        } else {
            return '$sign$symbol${absPrice.toStringAsFixed(decimals)}';
        }
    }
}

/// Default const time formatter for TimeLabelStyle
/// Uses responsive formatting based on visible time span when context is provided
class _DefaultTimeFormatter implements TimeFormatter {
    const _DefaultTimeFormatter();

    /// Month name abbreviations (US format) - duplicated here for const support
    static const _monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    @override
    String format(int timestamp, {TimeFormatContext? context}) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

        // If no context provided, use default hour:minute format
        if (context == null) {
            return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        }

        // Use responsive formatting based on visible time span (TradingView-style)
        final span = context.visibleTimeSpan;
        final isFirstOrLast = context.isFirstLabel || context.isLastLabel;
        final day = date.day;
        final month = date.month;
        final year = date.year;
        final hour = date.hour.toString().padLeft(2, '0');
        final minute = date.minute.toString().padLeft(2, '0');

        // Format selection based on time span (TradingView-style logic)
        if (span.inDays >= 365) {
            // Years: Show year only (e.g., "2025", "2024")
            return year.toString();
        } else if (span.inDays >= 90) {
            // 3+ months: First/Last show "MMM YYYY", middle shows "MMM" (e.g., "Dec 2025", "Jan")
            if (isFirstOrLast) {
                return '${_monthNames[month - 1]} $year';
            } else {
                return _monthNames[month - 1];
            }
        } else if (span.inDays >= 30) {
            // 1-3 months: First/Last show "DD MMM YYYY", middle shows "DD MMM" (e.g., "15 Jan 2025", "15 Jan")
            if (isFirstOrLast) {
                // For first/last, show full date with year if span is large enough
                if (span.inDays >= 60) {
                    return '$day ${_monthNames[month - 1]} $year';
                } else {
                    return '$day ${_monthNames[month - 1]}';
                }
            } else {
                return '$day ${_monthNames[month - 1]}';
            }
        } else if (span.inDays >= 7) {
            // 1-4 weeks: Show "DD MMM" format (e.g., "15 Jan", "25 Jun")
            return '$day ${_monthNames[month - 1]}';
        } else if (span.inDays >= 1) {
            // 1-7 days: First/Last show "DD MMM HH:MM", middle shows "HH:MM" (e.g., "15 Jan 22:50", "22:50")
            if (isFirstOrLast) {
                return '$day ${_monthNames[month - 1]} $hour:$minute';
            } else {
                return '$hour:$minute';
            }
        } else if (span.inHours >= 1) {
            // 1-24 hours: First/Last show "DD MMM HH:MM", middle shows "HH:MM" (e.g., "15 Jan 22:50", "22:50")
            if (isFirstOrLast) {
                return '$day ${_monthNames[month - 1]} $hour:$minute';
            } else {
                return '$hour:$minute';
            }
        } else {
            // Less than 1 hour: First/Last show "DD MMM HH:MM:SS", middle shows "HH:MM:SS"
            final second = date.second.toString().padLeft(2, '0');
            if (isFirstOrLast) {
                return '$day ${_monthNames[month - 1]} $hour:$minute:$second';
            } else {
                return '$hour:$minute:$second';
            }
        }
    }
}

// ============================================================================
// LINE CHART STYLE
// ============================================================================

/// Styling for the main chart line (data visualization)
/// 
/// Controls the appearance of the line connecting data points including:
/// - Line color, width, and smoothing
/// - Glow effect for emphasis
/// - Data point markers
class LineChartStyle {
    /// Color of the chart line
    final Color color;

    /// Width of the chart line
    final double width;

    /// Whether to show data point markers
    final bool showPoints;

    /// Radius of data point markers (when showPoints is true)
    final double pointRadius;

    /// Whether to show glow effect behind the line
    final bool showGlow;

    /// Width/intensity of the glow effect
    final double glowWidth;

    /// Whether to use smooth curves instead of straight line segments
    final bool smooth;

    /// Curve smoothness when smooth is enabled
    /// Uses Cardinal Spline algorithm for beautiful, flowing curves
    /// 0.0 = straight lines between points
    /// 0.5 = moderate smoothness
    /// 1.0 = maximum smoothness (Catmull-Rom spline)
    /// Higher values create smoother, more flowing curves
    final double curveTension;

    const LineChartStyle({
        this.color = Colors.blue,
        this.width = 2.0,
        this.showPoints = false,
        this.pointRadius = 3.0,
        this.showGlow = false,
        this.glowWidth = 4.0,
        this.smooth = false,
        this.curveTension = 1.0,  // Maximum smoothness by default
    });

    /// Create a minimal line style (just the line, no effects)
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

    /// Create a glowing line style
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

    /// Create a smooth curved line style
    /// Create a smooth curved line style using Cardinal Spline
    /// Produces beautiful, flowing curves like fl_chart and TradingView
    /// curveTension: 0.0 = straight, 0.5 = moderate, 1.0 = maximum smoothness
    factory LineChartStyle.smooth({
        Color color = Colors.blue,
        double width = 2.0,
        double curveTension = 1.0,  // Maximum smoothness for beautiful curves
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

    @override
    bool operator==(Object other) =>
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
// CURRENT PRICE INDICATOR STYLE
// ============================================================================

/// Styling for the current/latest price indicator
/// 
/// Controls the horizontal line and label showing the current price including:
/// - Line visibility, color, width, and style (solid, dashed, dotted)
/// - Label visibility, colors, and dimensions
/// - Bullish/bearish color differentiation
class CurrentPriceIndicatorStyle {
    /// Whether to show the horizontal price line
    final bool showLine;

    /// Whether to show the price label
    final bool showLabel;

    /// Color of the price line
    final Color lineColor;

    /// Width of the price line
    final double lineWidth;

    /// Style of the price line (solid, dashed, dotted)
    final PriceLineStyle lineStyle;

    /// Background color for bullish (price up) label
    final Color bullishColor;

    /// Background color for bearish (price down) label
    final Color bearishColor;

    /// Text color for the price label
    final Color textColor;

    /// Font size for the price label
    final double labelFontSize;

    /// Horizontal padding inside the label
    final double labelPaddingH;

    /// Vertical padding inside the label
    final double labelPaddingV;

    /// Border radius of the label background
    final double labelBorderRadius;

    const CurrentPriceIndicatorStyle({
        this.showLine = true,
        this.showLabel = true,
        this.lineColor = Colors.blue,
        this.lineWidth = 1.5,
        this.lineStyle = PriceLineStyle.solid,
        this.bullishColor = const Color(0xFF4CAF50), // Green
        this.bearishColor = const Color(0xFFF44336), // Red
        this.textColor = Colors.black,  // Default black text
        this.labelFontSize = 12.0,
        this.labelPaddingH = 8.0,
        this.labelPaddingV = 4.0,
        this.labelBorderRadius = 6.0,
    });

    /// Create a minimal current price indicator (line only, no label)
    factory CurrentPriceIndicatorStyle.lineOnly({
        Color lineColor = Colors.blue,
        double lineWidth = 1.5,
        PriceLineStyle lineStyle = PriceLineStyle.solid,
    }) {
        return CurrentPriceIndicatorStyle(
            showLine: true,
            showLabel: false,
            lineColor: lineColor,
            lineWidth: lineWidth,
            lineStyle: lineStyle,
        );
    }

    /// Create a dashed current price indicator
    factory CurrentPriceIndicatorStyle.dashed({
        Color lineColor = Colors.blue,
        Color bullishColor = const Color(0xFF4CAF50),
        Color bearishColor = const Color(0xFFF44336),
    }) {
        return CurrentPriceIndicatorStyle(
            lineColor: lineColor,
            lineStyle: PriceLineStyle.dashed,
            bullishColor: bullishColor,
            bearishColor: bearishColor,
        );
    }

    /// Create a dotted current price indicator
    factory CurrentPriceIndicatorStyle.dotted({
        Color lineColor = Colors.blue,
        Color bullishColor = const Color(0xFF4CAF50),
        Color bearishColor = const Color(0xFFF44336),
    }) {
        return CurrentPriceIndicatorStyle(
            lineColor: lineColor,
            lineStyle: PriceLineStyle.dotted,
            bullishColor: bullishColor,
            bearishColor: bearishColor,
        );
    }

    /// Create a hidden current price indicator (completely hidden)
    factory CurrentPriceIndicatorStyle.hidden() {
        return const CurrentPriceIndicatorStyle(
            showLine: false,
            showLabel: false,
        );
    }

    CurrentPriceIndicatorStyle copyWith({
        bool? showLine,
        bool? showLabel,
        Color? lineColor,
        double? lineWidth,
        PriceLineStyle? lineStyle,
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

    @override
    bool operator==(Object other) =>
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

// ============================================================================
// RIPPLE ANIMATION STYLE
// ============================================================================

/// Styling for the ripple/pulse animation on the latest data point
/// 
/// Controls the animated effect that draws attention to the most recent price
class RippleAnimationStyle {
    /// Whether to show the ripple animation
    final bool show;

    /// Color of the ripple effect
    final Color color;

    /// Maximum radius of the ripple effect
    final double maxRadius;

    /// Minimum opacity of the ripple (at full expansion)
    final double minOpacity;

    /// Maximum opacity of the ripple (at start)
    final double maxOpacity;

    /// Duration of a single ripple animation in milliseconds
    /// Default: 1500ms for smooth expansion
    final int animationDurationMs;

    /// Interval between ripple cycles in milliseconds
    /// Total cycle time = animationDurationMs + intervalMs
    /// Default: 500ms, so with 1500ms animation = 2000ms (2 second) total cycle
    final int intervalMs;

    const RippleAnimationStyle({
        this.show = true,
        this.color = Colors.white,
        this.maxRadius = 35.0,      // Large radius for obvious visibility
        this.minOpacity = 0.0,
        this.maxOpacity = 1.0,      // Full opacity for maximum visibility
        this.animationDurationMs = 2000,  // 2 seconds for ripple animation
        this.intervalMs = 2000,           // 2 seconds delay before next ripple
    });

    /// Create a hidden ripple (no animation)
    factory RippleAnimationStyle.hidden() {
        return const RippleAnimationStyle(show: false);
    }

    /// Create a subtle ripple effect
    factory RippleAnimationStyle.subtle({
        Color color = Colors.white,
    }) {
        return RippleAnimationStyle(
            color: color,
            maxRadius: 16.0,
            maxOpacity: 0.3,
        );
    }

    /// Create a prominent ripple effect
    factory RippleAnimationStyle.prominent({
        Color color = Colors.white,
    }) {
        return RippleAnimationStyle(
            color: color,
            maxRadius: 32.0,
            maxOpacity: 0.7,
        );
    }

    RippleAnimationStyle copyWith({
        bool? show,
        Color? color,
        double? maxRadius,
        double? minOpacity,
        double? maxOpacity,
        int? animationDurationMs,
        int? intervalMs,
    }) {
        return RippleAnimationStyle(
            show: show ?? this.show,
            color: color ?? this.color,
            maxRadius: maxRadius ?? this.maxRadius,
            minOpacity: minOpacity ?? this.minOpacity,
            maxOpacity: maxOpacity ?? this.maxOpacity,
            animationDurationMs: animationDurationMs ?? this.animationDurationMs,
            intervalMs: intervalMs ?? this.intervalMs,
        );
    }

    @override
    bool operator==(Object other) =>
    identical(this, other) ||
        other is RippleAnimationStyle &&
            runtimeType == other.runtimeType &&
            show == other.show &&
            color == other.color &&
            maxRadius == other.maxRadius &&
            minOpacity == other.minOpacity &&
            maxOpacity == other.maxOpacity &&
            animationDurationMs == other.animationDurationMs &&
            intervalMs == other.intervalMs;

    @override
    int get hashCode =>
    show.hashCode ^
        color.hashCode ^
        maxRadius.hashCode ^
        minOpacity.hashCode ^
        maxOpacity.hashCode ^
        animationDurationMs.hashCode ^
        intervalMs.hashCode;
}

// ============================================================================
// Y-AXIS (PRICE) LABEL STYLE
// ============================================================================

/// Comprehensive styling for price labels (Y-axis)
class PriceLabelStyle {
    final bool show;
    final double fontSize;
    final Color color;
    final Color? backgroundColor;
    final FontWeight? fontWeight;
    final double spacing; // Space between labels
    final int labelCount; // Number of labels to show
    final PriceFormatter formatter;
    final EdgeInsets padding;
    final TextAlign? textAlign;

    /// Creates a const version (uses smart formatter)
    const PriceLabelStyle({
        this.show = true,
        this.fontSize = 10.0,
        this.color = const Color(0xCCFFFFFF), // 80% opacity white
        this.backgroundColor,
        this.fontWeight,
        this.spacing = 0.0, // Auto-calculated if 0
        this.labelCount = 5,
        this.formatter = const _DefaultPriceFormatter(),
        this.padding = const EdgeInsets.only(left: 5.0, right: 5.0),
        this.textAlign,
    });

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

/// Comprehensive styling for time labels (X-axis)
class TimeLabelStyle {
    final bool show;
    final double fontSize;
    final Color color;
    final Color? backgroundColor;
    final FontWeight? fontWeight;
    final int labelCount; // Number of labels to show
    final TimeFormatter formatter;
    final EdgeInsets padding;
    final TextAlign? textAlign;

    /// Creates a const version (uses smart formatter)
    const TimeLabelStyle({
        this.show = true,
        this.fontSize = 10.0,
        this.color = const Color(0xCCFFFFFF), // 80% opacity white
        this.backgroundColor,
        this.fontWeight,
        this.labelCount = 3, // Default to 3 labels for safe spacing
        this.formatter = const _DefaultTimeFormatter(),
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

/// Comprehensive styling for chart axes
class AxisStyle {
    final bool showGrid;
    final Color gridColor;
    final double gridLineWidth;
    final PriceLineStyle gridLineStyle; // solid, dashed, dotted
    final int horizontalGridLines; // Number of horizontal grid lines
    final int verticalGridLines; // Number of vertical grid lines (0 = auto)
    final double yAxisPadding; // Padding around Y-axis labels
    final double xAxisPadding; // Padding for X-axis labels

    const AxisStyle({
        this.showGrid = true,
        this.gridColor = const Color(0x33FFFFFF), // 20% opacity white
        this.gridLineWidth = 0.5,
        this.gridLineStyle = PriceLineStyle.solid,
        this.horizontalGridLines = 5,
        this.verticalGridLines = 0, // 0 = auto-calculate
        this.yAxisPadding = 5.0,
        this.xAxisPadding = 5.0,
    });

    AxisStyle copyWith({
        bool? showGrid,
        Color? gridColor,
        double? gridLineWidth,
        PriceLineStyle? gridLineStyle,
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

/// Line style for grid lines and price lines
/// This enum is shared between chart_painter and label_styles
enum PriceLineStyle {
    solid,
    dashed,
    dotted,
}

/// Comprehensive styling for crosshair (touch/hover tracking)
/// 
/// Provides full flexibility for customizing crosshair appearance including:
/// - Line colors, widths, and styles (solid, dashed, dotted)
/// - Label background and text colors
/// - Tracker point radius and styling
/// - Font size (inherits from chart labels if not specified)
class CrosshairStyle {
    /// Whether to show the crosshair on long press
    final bool show;

    // === LINE STYLING ===

    /// Color for the vertical crosshair line
    final Color verticalLineColor;

    /// Color for the horizontal crosshair line
    final Color horizontalLineColor;

    /// Width of the vertical crosshair line
    final double verticalLineWidth;

    /// Width of the horizontal crosshair line
    final double horizontalLineWidth;

    /// Style of the vertical line (solid, dashed, dotted)
    final PriceLineStyle verticalLineStyle;

    /// Style of the horizontal line (solid, dashed, dotted)
    final PriceLineStyle horizontalLineStyle;

    // === TRACKER POINT STYLING ===

    /// Color of the tracker point at intersection
    final Color trackerColor;

    /// Radius of the tracker point circle
    final double trackerRadius;

    /// Whether to show an outer ring around the tracker point
    final bool showTrackerRing;

    /// Color of the outer ring (if shown)
    final Color trackerRingColor;

    /// Width of the outer ring stroke
    final double trackerRingWidth;

    // === LABEL STYLING ===

    /// Background color for the price and time labels
    final Color labelBackgroundColor;

    /// Text color for the price and time labels
    final Color labelTextColor;

    /// Font size for labels (null = inherit from chart labelFontSize)
    final double? labelFontSize;

    /// Font weight for labels
    final FontWeight labelFontWeight;

    /// Border radius for label backgrounds
    final double labelBorderRadius;

    /// Horizontal padding inside labels
    final double labelPaddingH;

    /// Vertical padding inside labels
    final double labelPaddingV;

    /// Whether to show price label on the right
    final bool showPriceLabel;

    /// Whether to show time label at the bottom
    final bool showTimeLabel;

    const CrosshairStyle({
        this.show = true,
        // Line styling - default to subtle white lines
        this.verticalLineColor = const Color.fromRGBO(255, 255, 255, 0.5),
        this.horizontalLineColor = const Color.fromRGBO(255, 255, 255, 0.5),
        this.verticalLineWidth = 1.0,
        this.horizontalLineWidth = 1.0,
        this.verticalLineStyle = PriceLineStyle.solid,
        this.horizontalLineStyle = PriceLineStyle.solid,
        // Tracker point styling
        this.trackerColor = Colors.white,
        this.trackerRadius = 5.0,
        this.showTrackerRing = true,
        this.trackerRingColor = const Color.fromRGBO(255, 255, 255, 0.3),
        this.trackerRingWidth = 2.0,
        // Label styling - default to white bg with black text
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

    /// Create a CrosshairStyle with all lines using the same color
    factory CrosshairStyle.uniform({
        Color lineColor = const Color.fromRGBO(255, 255, 255, 0.5),
        double lineWidth = 1.0,
        PriceLineStyle lineStyle = PriceLineStyle.solid,
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

    /// Create a dashed crosshair style
    factory CrosshairStyle.dashed({
        Color lineColor = const Color.fromRGBO(255, 255, 255, 0.5),
        double lineWidth = 1.0,
    }) {
        return CrosshairStyle(
            verticalLineColor: lineColor,
            horizontalLineColor: lineColor,
            verticalLineWidth: lineWidth,
            horizontalLineWidth: lineWidth,
            verticalLineStyle: PriceLineStyle.dashed,
            horizontalLineStyle: PriceLineStyle.dashed,
        );
    }

    /// Create a dotted crosshair style
    factory CrosshairStyle.dotted({
        Color lineColor = const Color.fromRGBO(255, 255, 255, 0.5),
        double lineWidth = 1.0,
    }) {
        return CrosshairStyle(
            verticalLineColor: lineColor,
            horizontalLineColor: lineColor,
            verticalLineWidth: lineWidth,
            horizontalLineWidth: lineWidth,
            verticalLineStyle: PriceLineStyle.dotted,
            horizontalLineStyle: PriceLineStyle.dotted,
        );
    }

    CrosshairStyle copyWith({
        bool? show,
        Color? verticalLineColor,
        Color? horizontalLineColor,
        double? verticalLineWidth,
        double? horizontalLineWidth,
        PriceLineStyle? verticalLineStyle,
        PriceLineStyle? horizontalLineStyle,
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

    @override
    bool operator==(Object other) =>
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
