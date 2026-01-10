import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart' show Candle, ChartStyle, PriceLineStyle;
import 'package:imp_trading_chart/src/formatters/price_formatter.dart' show PriceFormatter;
import 'package:imp_trading_chart/src/formatters/time_formatter.dart' show TimeFormatContext, CrosshairTimeFormatter;
import 'package:imp_trading_chart/src/math/coordinate_mapper.dart' show CoordinateMapper;

// PriceLineStyle is now in label_styles.dart
// Keeping this for backward compatibility - it will be removed in a future version
// Import from label_styles.dart instead

/// Helper class to store label information for overlap detection
class _LabelInfo {
    final String text;
    final double x;
    final double width;
    final int index;
    final bool isFirst;
    final bool isLast;

    _LabelInfo({
        required this.text,
        required this.x,
        required this.width,
        required this.index,
        required this.isFirst,
        required this.isLast,
    });
}

/// High-performance stateless CustomPainter for line chart rendering.
///
/// This painter:
/// - Only draws visible candles (from viewport)
/// - Uses precomputed coordinate mapper
/// - Has NO logic, NO calculations, NO data mutations
/// - Only maps coordinates and draws primitives
class ChartPainter extends CustomPainter {
    final List<Candle> candles;
    final CoordinateMapper mapper;
    final ChartStyle style;
    final double? currentPrice;
    final double pulseProgress; // 0.0 to 1.0 for pulse animation
    final Offset? crosshairPosition; // For touch tracking
    final int? crosshairIndex; // Candle index at crosshair

    const ChartPainter({
        required this.candles,
        required this.mapper,
        required this.style,
        this.currentPrice,
        this.pulseProgress = 0.0,
        this.crosshairPosition,
        this.crosshairIndex,
    });

    @override
    void paint(Canvas canvas, Size size) {
        if (candles.isEmpty) return;

        // Save canvas state for clipping
        canvas.save();

        // Clip to chart content area (excluding padding)
        final chartRect = Rect.fromLTWH(
            mapper.paddingLeft,
            mapper.paddingTop,
            mapper.contentWidth,
            mapper.contentHeight,
        );
        canvas.clipRect(chartRect);

        // Draw line chart with optional glow effect (inside clipped area)
        _drawLineChart(canvas);

        // Restore canvas (remove clip for grid and labels)
        canvas.restore();

        // Draw grid OUTSIDE clip (extends to labels for TradingView-style visual connection)
        if (style.axisStyle.showGrid) {
            _drawGrid(canvas, size);
        }

        // Draw Y-axis price labels (outside clipped area, on right)
        if (style.priceLabelStyle.show) {
            _drawPriceLabels(canvas, size);
        }

        // Draw X-axis time labels (outside clipped area, at bottom)
        if (style.timeLabelStyle.show) {
            _drawTimeLabels(canvas, size);
        }

        // Draw current price line and label (if provided)
        // Label is always shown if currentPrice is provided, line is optional
        if (currentPrice != null) {
            _drawCurrentPriceLine(canvas, size, currentPrice!);
        }

        // Draw ripple/pulse on last point (single burst animation with radial gradient)
        // Always draw if ripple animation is enabled (center point should always be visible)
        if (candles.isNotEmpty && style.rippleStyle.show) {
            _drawRippleOnLastPoint(canvas, size);
        }

        // TOPMOST LAYER: Draw crosshair LAST so it appears above all other elements
        // This ensures crosshair lines, point, and labels are never hidden behind other elements
        if (crosshairPosition != null && crosshairIndex != null && style.crosshairStyle.show) {
            _drawCrosshair(canvas, size);
        }
    }

    void _drawGrid(Canvas canvas, Size size) {
        final axisStyle = style.axisStyle;
        if (!axisStyle.showGrid) return;

        // Get layout configuration
        final layout = style.layout;

        final gridColor = axisStyle.gridColor;
        final gridLineWidth = axisStyle.gridLineWidth;
        final gridLineStyle = axisStyle.gridLineStyle;

        final paint = Paint()
            ..color = gridColor.withValues(alpha: 0.2)
            ..strokeWidth = gridLineWidth;

        // Fix: Prevent division by zero
        if (mapper.contentHeight <= 0) return;

        // Calculate chart boundaries
        final chartLeft = mapper.paddingLeft;
        final chartRight = mapper.paddingLeft + mapper.contentWidth;
        final chartTop = mapper.paddingTop;
        final chartBottom = mapper.paddingTop + mapper.contentHeight;

        // Calculate where label TEXT actually starts (not label area, but actual text painting position)
        // Y-axis text starts at: chartRight + yAxisGap + yAxisLabelPadding.left
        // X-axis text starts at: chartBottom + xAxisGap + xAxisLabelPadding.top
        // Calculate ONCE and reuse for all lines to ensure perfect alignment and symmetry

        // Calculate horizontal line end position (same for ALL horizontal lines)
        double horizontalLineEndX = chartRight;
        if (style.priceLabelStyle.show) {
            // Get Y-axis label padding
            final priceLabelStyle = style.priceLabelStyle;
            final yAxisLabelPadding = priceLabelStyle.padding;

            // Text painting position: chartRight + yAxisGap + labelPadding.left
            final textStartX = chartRight + layout.yAxisGap + yAxisLabelPadding.left;

            // Grid extends to just before text (gap controlled by gridToLabelGapY)
            // This ensures ALL horizontal lines end at the same X position for perfect alignment
            horizontalLineEndX = textStartX - layout.gridToLabelGapY;
        }

        // Clamp horizontal line end to screen bounds
        final clampedHorizontalEndX = horizontalLineEndX.clamp(chartLeft, size.width);

        // Calculate vertical line end position (same for ALL vertical lines)
        double verticalLineEndY = chartBottom;
        if (style.timeLabelStyle.show) {
            // Get X-axis label padding
            final timeLabelStyle = style.timeLabelStyle;
            final xAxisLabelPadding = timeLabelStyle.padding;

            // Text painting position: chartBottom + xAxisGap + labelPadding.top
            final textStartY = chartBottom + layout.xAxisGap + xAxisLabelPadding.top;

            // Grid extends to just before text (gap controlled by gridToLabelGapX)
            // This ensures ALL vertical lines end at the same Y position for perfect alignment
            verticalLineEndY = textStartY - layout.gridToLabelGapX;
        }

        // Clamp vertical line end to screen bounds
        final clampedVerticalEndY = verticalLineEndY.clamp(chartTop, size.height);

        // Draw horizontal grid lines (price levels) - ALL extend to same X position
        // Each line maintains constant Y coordinate for perfect horizontal alignment
        final horizontalLines = axisStyle.horizontalGridLines;
        if (horizontalLines > 0) {
            for (int i = 0; i <= horizontalLines; i++) {
                // Calculate Y position for this grid line (constant across the line)
                final y = chartTop + (mapper.contentHeight * i / horizontalLines);

                // Draw perfectly horizontal line: same Y coordinate from start to end
                _drawStyledLine(
                    canvas,
                    Offset(chartLeft, y),                    // Start: left edge, constant Y
                    Offset(clampedHorizontalEndX, y),        // End: same Y, extends toward labels
                    paint,
                    gridLineStyle,
                );
            }
        }

        // Draw vertical grid lines (time levels) - ALL extend to same Y position
        // Each line maintains constant X coordinate for perfect vertical alignment
        final visibleCount = candles.length;
        if (visibleCount == 0) return; // Early return if no visible candles

        int verticalLines;
        if (axisStyle.verticalGridLines > 0) {
            verticalLines = axisStyle.verticalGridLines;
        } else {
            verticalLines = math.min(visibleCount, 6);
        }

        if (verticalLines > 0) {
            for (int i = 0; i <= verticalLines; i++) {
                final relativeIndex = (visibleCount * i / verticalLines).round();
                // Clamp relativeIndex to valid range for visible candles
                final clampedIndex = relativeIndex.clamp(0, visibleCount - 1);

                // Calculate absolute index for coordinate mapping
                final index = mapper.viewport.startIndex + clampedIndex;
                final x = mapper.indexToX(index);

                // Only validate that x is finite and within chart bounds
                if (x.isFinite && x >= chartLeft && x <= chartRight) {
                    // Draw perfectly vertical line: same X coordinate from start to end
                    _drawStyledLine(
                        canvas,
                        Offset(x, chartTop),                    // Start: top edge, constant X
                        Offset(x, clampedVerticalEndY),         // End: same X, extends toward labels
                        paint,
                        gridLineStyle,
                    );
                }
            }
        }
    }

    void _drawLineChart(Canvas canvas) {
        // Handle single data point case - draw a point instead of a line
        if (candles.length == 1) {
            _drawSingleDataPoint(canvas);
            return;
        }

        if (candles.length < 2) return;

        if (style.lineStyle.smooth) {
            _drawSmoothLineChart(canvas);
        } else {
            _drawStraightLineChart(canvas);
        }
    }

    /// Draws a single data point when there's only one candle
    /// 
    /// The point is positioned using the price scale:
    /// - X: Centered horizontally in the chart area
    /// - Y: Positioned according to the price scale (which centers single points with proper padding)
    /// 
    /// This ensures the current price line, ripple effect, and data point all align perfectly.
    void _drawSingleDataPoint(Canvas canvas) {
        if (candles.isEmpty) return;

        final candle = candles.first;
        if (!candle.close.isFinite) return;

        // For single point:
        // - X: Center horizontally in the content area
        // - Y: Use price scale (which handles single point centering with proper padding)
        // This ensures alignment with current price line and ripple effect
        final x = mapper.paddingLeft + (mapper.contentWidth / 2);
        final y = mapper.priceToY(candle.close); // Use price scale for Y positioning

        if (!x.isFinite || !y.isFinite) return;

        final lineStyle = style.lineStyle;
        final pointRadius = lineStyle.pointRadius > 0 ? lineStyle.pointRadius : 6.0;

        // Draw the point with glow effect if enabled
        if (lineStyle.showGlow) {
            final glowPaint = Paint()
                ..color = lineStyle.color.withValues(alpha: 0.3)
                ..maskFilter = MaskFilter.blur(BlurStyle.normal, lineStyle.glowWidth * 3);
            canvas.drawCircle(Offset(x, y), pointRadius + 4, glowPaint);
        }

        // Draw the main point (larger for single data point visibility)
        final pointPaint = Paint()
            ..color = lineStyle.color
            ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), pointRadius, pointPaint);
    }

    void _drawStraightLineChart(Canvas canvas) {
        if (candles.length < 2) return;

        final path = Path();
        bool isFirst = true;

        for (int i = 0; i < candles.length; i++) {
            final candle = candles[i];
            if (!candle.close.isFinite) continue;

            final index = mapper.viewport.startIndex + i;
            if (index < 0 || index >= mapper.viewport.totalCount) continue;

            final x = mapper.getCandleCenterX(index);
            final y = mapper.priceToY(candle.close);

            if (!x.isFinite || !y.isFinite) continue;

            if (isFirst) {
                path.moveTo(x, y);
                isFirst = false;
            } else {
                path.lineTo(x, y);
            }
        }

        if (isFirst) return;

        _drawPathWithEffects(canvas, path);
    }

    void _drawSmoothLineChart(Canvas canvas) {
        if (candles.length < 2) return;

        final List<Offset> points = [];

        // Collect all valid points first
        for (int i = 0; i < candles.length; i++) {
            final candle = candles[i];
            if (!candle.close.isFinite) continue;

            final index = mapper.viewport.startIndex + i;
            if (index < 0 || index >= mapper.viewport.totalCount) continue;

            final x = mapper.getCandleCenterX(index);
            final y = mapper.priceToY(candle.close);

            if (!x.isFinite || !y.isFinite) continue;

            points.add(Offset(x, y));
        }

        if (points.length < 2) return;

        // Generate smooth path using Cardinal Spline
        final path = _generateCardinalSplinePath(points);

        // Clip to chart content area to prevent curves from going outside
        final chartLeft = mapper.paddingLeft;
        final chartTop = mapper.paddingTop;
        final chartRight = mapper.paddingLeft + mapper.contentWidth;
        final chartBottom = mapper.paddingTop + mapper.contentHeight;

        canvas.save();
        canvas.clipRect(Rect.fromLTRB(chartLeft, chartTop, chartRight, chartBottom));
        _drawPathWithEffects(canvas, path);
        canvas.restore();
    }

    /// Generates a beautiful smooth curve using Cardinal Spline algorithm
    /// This creates natural-looking curves like fl_chart and TradingView
    /// 
    /// Cardinal spline produces smooth, flowing curves that:
    /// - Pass through all data points exactly
    /// - Have continuous first derivatives (no corners)
    /// - Look natural and visually pleasing
    Path _generateCardinalSplinePath(List<Offset> points) {
        final path = Path();
        final n = points.length;

        if (n < 2) return path;

        path.moveTo(points[0].dx, points[0].dy);

        if (n == 2) {
            // Two points - straight line
            path.lineTo(points[1].dx, points[1].dy);
            return path;
        }

        // Tension parameter: 0 = Catmull-Rom (smooth), 1 = straight lines
        // We invert the user's curveTension so higher value = more curve
        final userTension = style.lineStyle.curveTension.clamp(0.0, 1.0);
        final tension = 1.0 - userTension;  // Invert: high curveTension = low cardinal tension

        // Cardinal spline coefficient
        final c = (1.0 - tension) / 2.0;

        for (int i = 0; i < n - 1; i++) {
            // For first point: extrapolate a virtual point before it
            // For last point: extrapolate a virtual point after it
            // This ensures uniform smoothness across ALL points
            final Offset p0;
            final Offset p3;

            if (i == 0) {
                // Extrapolate virtual point before first point
                // p0 = p1 - (p2 - p1) = 2*p1 - p2
                p0 = Offset(
                    2 * points[0].dx - points[1].dx,
                    2 * points[0].dy - points[1].dy,
                );
            } else {
                p0 = points[i - 1];
            }

            final p1 = points[i];
            final p2 = points[i + 1];

            if (i == n - 2) {
                // Extrapolate virtual point after last point
                // p3 = p2 + (p2 - p1) = 2*p2 - p1
                p3 = Offset(
                    2 * points[n - 1].dx - points[n - 2].dx,
                    2 * points[n - 1].dy - points[n - 2].dy,
                );
            } else {
                p3 = points[i + 2];
            }

            // Calculate tangent vectors using Cardinal spline formula
            // Tangent at p1: c * (p2 - p0)
            // Tangent at p2: c * (p3 - p1)
            final t1x = c * (p2.dx - p0.dx);
            final t1y = c * (p2.dy - p0.dy);
            final t2x = c * (p3.dx - p1.dx);
            final t2y = c * (p3.dy - p1.dy);

            // Convert Hermite spline to Bezier control points
            // cp1 = p1 + tangent1 / 3
            // cp2 = p2 - tangent2 / 3
            final cp1 = Offset(
                p1.dx + t1x / 3.0,
                p1.dy + t1y / 3.0,
            );

            final cp2 = Offset(
                p2.dx - t2x / 3.0,
                p2.dy - t2y / 3.0,
            );

            path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
        }

        return path;
    }

    void _drawPathWithEffects(Canvas canvas, Path path) {
        // Draw glow effect if enabled (draw first, behind main line)
        final lineStyle = style.lineStyle;

        if (lineStyle.showGlow) {
            final glowPaint = Paint()
                ..color = lineStyle.color.withValues(alpha: 0.3)
                ..style = PaintingStyle.stroke
                ..strokeWidth = lineStyle.width + (lineStyle.glowWidth * 2)
                ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, lineStyle.glowWidth);

            canvas.drawPath(path, glowPaint);
        }

        // Draw the main line
        final linePaint = Paint()
            ..color = lineStyle.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = lineStyle.width
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;

        canvas.drawPath(path, linePaint);

        // Draw points if enabled
        if (lineStyle.showPoints && lineStyle.pointRadius > 0) {
            final pointPaint = Paint()
                ..color = lineStyle.color
                ..style = PaintingStyle.fill
                ..isAntiAlias = true;

            for (int i = 0; i < candles.length; i++) {
                final candle = candles[i];
                final index = mapper.viewport.startIndex + i;
                final x = mapper.getCandleCenterX(index);
                final y = mapper.priceToY(candle.close);

                canvas.drawCircle(Offset(x, y), lineStyle.pointRadius, pointPaint);
            }
        }
    }

    void _drawPriceLabels(Canvas canvas, Size size) {
        final priceLabelStyle = style.priceLabelStyle;
        if (!priceLabelStyle.show) return;

        // Get layout configuration
        final layout = style.layout;

        final labelFontSize = priceLabelStyle.fontSize;
        final labelColor = priceLabelStyle.color;
        final bgColor = priceLabelStyle.backgroundColor ?? style.backgroundColor;
        final fontWeight = priceLabelStyle.fontWeight;
        final labelCount = priceLabelStyle.labelCount;
        final formatter = priceLabelStyle.formatter;

        // Use layout padding for Y-axis labels (left/right padding around labels)
        final yAxisLabelPadding = priceLabelStyle.padding;

        // Fix: Prevent division by zero
        if (labelCount <= 0) return;

        final textStyle = TextStyle(
            color: labelColor,
            fontSize: labelFontSize,
            fontWeight: fontWeight,
        );
        final textPainter = TextPainter(textDirection: TextDirection.ltr);
        final bgPaint = Paint()
            ..color = bgColor
            ..style = PaintingStyle.fill;

        final scale = mapper.priceScale;
        // Fix: Check for valid price range (allow very small ranges for single candle case)
        // With the fix in PriceScale.fromCandles, range should always be > 0, but check for safety
        if (scale.range <= 0 || !scale.max.isFinite || !scale.min.isFinite) return;

        // Show exactly labelCount labels
        // Handle edge case: labelCount = 1
        if (labelCount == 1) {
            // Single label at middle price
            final price = (scale.max + scale.min) / 2;
            if (price.isFinite) {
                final y = mapper.priceToY(price);
                final clampedY = y.clamp(
                    mapper.paddingTop,
                    mapper.paddingTop + mapper.contentHeight,
                );
                final priceText = formatter.format(price);
                textPainter.text = TextSpan(text: priceText, style: textStyle);
                textPainter.layout();
                if (textPainter.width > 0 && textPainter.height > 0) {
                    final chartRight = mapper.paddingLeft + mapper.contentWidth;
                    final labelX = chartRight + layout.yAxisGap + yAxisLabelPadding.left;
                    if (bgColor.a > 0.0) {
                        final paddingH = yAxisLabelPadding.horizontal;
                        final paddingV = yAxisLabelPadding.vertical;
                        final labelRect = Rect.fromLTWH(
                            labelX - yAxisLabelPadding.left,
                            clampedY - textPainter.height / 2 - paddingV,
                            textPainter.width + paddingH,
                            textPainter.height + (paddingV * 2),
                        );
                        canvas.drawRect(labelRect, bgPaint);
                    }
                    textPainter.paint(
                        canvas,
                        Offset(labelX, clampedY - textPainter.height / 2),
                    );
                }
            }
            return;
        }

        // For labelCount > 1: distribute labels evenly from max to min
        for (int i = 0; i < labelCount; i++) {
            final price = scale.max - ((scale.max - scale.min) * i / (labelCount - 1));
            // Fix: Validate price is finite
            if (!price.isFinite) continue;

            final y = mapper.priceToY(price);

            // Clamp Y to visible chart area
            final clampedY = y.clamp(
                mapper.paddingTop,
                mapper.paddingTop + mapper.contentHeight,
            );

            // Use custom formatter if provided
            final priceText = formatter.format(price);
            textPainter.text = TextSpan(text: priceText, style: textStyle);
            textPainter.layout();

            // Fix: Validate text dimensions
            if (textPainter.width <= 0 || textPainter.height <= 0) continue;

            // Calculate Y-axis label position using layout model
            // Position: chartRight + yAxisGap + labelPadding.left
            final chartRight = mapper.paddingLeft + mapper.contentWidth;
            final labelX = chartRight + layout.yAxisGap + yAxisLabelPadding.left;

            // Draw background for label (if background color is provided)
            if (bgColor.a > 0.0) {
                final paddingH = yAxisLabelPadding.horizontal;
                final paddingV = yAxisLabelPadding.vertical;
                final labelRect = Rect.fromLTWH(
                    labelX - yAxisLabelPadding.left,
                    clampedY - textPainter.height / 2 - paddingV,
                    textPainter.width + paddingH,
                    textPainter.height + (paddingV * 2),
                );
                canvas.drawRect(labelRect, bgPaint);
            }

            // Draw label on right side of chart
            textPainter.paint(
                canvas,
                Offset(
                    labelX,
                    clampedY - textPainter.height / 2,
                ),
            );
        }
    }

    void _drawTimeLabels(Canvas canvas, Size size) {
        if (candles.isEmpty) return;

        final timeLabelStyle = style.timeLabelStyle;
        if (!timeLabelStyle.show) return;

        // Get layout configuration
        final layout = style.layout;

        final labelFontSize = timeLabelStyle.fontSize;
        final labelColor = timeLabelStyle.color;
        final bgColor = timeLabelStyle.backgroundColor ?? style.backgroundColor;
        final fontWeight = timeLabelStyle.fontWeight;
        final labelCount = timeLabelStyle.labelCount;
        final formatter = timeLabelStyle.formatter;

        // Use layout padding for X-axis labels (top/bottom padding around labels)
        final xAxisLabelPadding = timeLabelStyle.padding;

        // Fix: Prevent division by zero
        if (labelCount <= 0) return;

        final textStyle = TextStyle(
            color: labelColor,
            fontSize: labelFontSize,
            fontWeight: fontWeight,
        );
        final textPainter = TextPainter(textDirection: TextDirection.ltr);
        final bgPaint = Paint()
            ..color = bgColor
            ..style = PaintingStyle.fill;

        final visibleCount = candles.length;
        final labelCountToShow = math.min(visibleCount, labelCount);

        // Early return if no labels to show
        if (labelCountToShow <= 0) return;

        // Calculate visible time span for responsive formatting
        // Get first and last visible candles to determine time range
        final firstCandle = candles.first;
        final lastCandle = candles.last;
        final visibleTimeSpan = Duration(
            seconds: (lastCandle.time - firstCandle.time).abs(),
        );

        // Calculate chart boundaries for proper alignment
        final chartLeft = mapper.paddingLeft;
        final chartRight = mapper.paddingLeft + mapper.contentWidth;

        // Collect all label information first to check for overlaps
        final List<_LabelInfo> labelInfos = [];

        // Show exactly labelCountToShow labels (not labelCountToShow + 1)
        // First label at first candle, last label at last candle, middle labels distributed
        for (int i = 0; i < labelCountToShow; i++) {
            // Calculate relative index: distribute evenly across visible candles
            // For 3 labels (i=0,1,2) with 100 candles: positions at 0, 50, 99
            final relativeIndex = (visibleCount > 1)
                ? ((visibleCount - 1) * i / (labelCountToShow - 1)).round()
                : 0;

            // Ensure index is within valid range
            if (relativeIndex < 0 || relativeIndex >= candles.length) continue;

            final candle = candles[relativeIndex];

            // Calculate absolute index for X coordinate mapping
            final dataIndex = mapper.viewport.startIndex + relativeIndex;
            final x = mapper.indexToX(dataIndex);

            // Only validate that x is finite
            if (!x.isFinite) continue;

            // Determine if this is first or last label
            final isFirstLabel = (i == 0);
            final isLastLabel = (i == labelCountToShow - 1);

            // Create context for responsive formatting
            final context = TimeFormatContext(
                visibleTimeSpan: visibleTimeSpan,
                isFirstLabel: isFirstLabel,
                isLastLabel: isLastLabel,
                labelIndex: i,
                totalLabels: labelCountToShow,
            );

            // Use custom formatter with context for responsive formatting
            final timeText = formatter.format(candle.time, context: context);
            textPainter.text = TextSpan(text: timeText, style: textStyle);
            textPainter.layout();

            // Skip if text has invalid dimensions
            if (textPainter.width <= 0 || textPainter.height <= 0) continue;

            // Calculate label X position with MainAxisAlignment.spaceBetween behavior:
            // - First label: left edge aligned to first candle's left edge (first grid line position)
            // - Last label: left edge aligned to last candle's left edge (last grid line position)
            // - Middle labels: left edge aligned to their candle's left edge (grid line positions)
            // Special case: For single data point, center the label below the point
            // This ensures labels align perfectly with vertical grid lines
            double labelX;
            if (visibleCount == 1 && labelCountToShow == 1) {
                // Single data point: center the label below the point
                labelX = x - (textPainter.width / 2);
            } else if (isFirstLabel) {
                // First label: left edge at first candle's left edge (chartLeft = first grid line)
                labelX = chartLeft;
            } else if (isLastLabel) {
                // Last label: left edge at last candle's left edge (last grid line position)
                // The grid line is at indexToX(lastIndex), which is the left edge of the last candle
                // Position label so its left edge aligns with the grid line
                labelX = x; // x is already indexToX(dataIndex) for the last candle
            } else {
                // Middle labels: left edge at their candle's left edge (grid line position)
                labelX = x; // x is already indexToX(dataIndex)
            }

            // Ensure label doesn't go outside bounds
            labelX = labelX.clamp(chartLeft, chartRight - textPainter.width);

            labelInfos.add(_LabelInfo(
                    text: timeText,
                    x: labelX,
                    width: textPainter.width,
                    index: i,
                    isFirst: isFirstLabel,
                    isLast: isLastLabel,
                ));
        }

        // Filter labels to prevent overlap (minimum spacing between labels)
        // Always keep first and last labels, skip middle ones that overlap
        const double minSpacing = 8.0; // Minimum pixels between label edges
        final List<_LabelInfo> visibleLabels = [];

        // chartLeft and chartRight are already declared above, reuse them

        for (int i = 0; i < labelInfos.length; i++) {
            final label = labelInfos[i];

            // Special case: Single data point - use the already calculated centered position
            // Don't override with first/last label logic
            if (candles.length == 1 && labelInfos.length == 1) {
                // Single label for single data point - keep centered position
                // Center the label horizontally below the data point
                final centerX = mapper.paddingLeft + (mapper.contentWidth / 2);
                final centeredLabelX = (centerX - (label.width / 2)).clamp(chartLeft, chartRight - label.width);
                visibleLabels.add(_LabelInfo(
                        text: label.text,
                        x: centeredLabelX,
                        width: label.width,
                        index: label.index,
                        isFirst: true,
                        isLast: true,
                    ));
                continue;
            }

            // Always include first and last labels, but recalculate their positions for perfect alignment
            if (label.isFirst) {
                // First label: ensure left edge is exactly at chartLeft (first grid line)
                visibleLabels.add(_LabelInfo(
                        text: label.text,
                        x: chartLeft,
                        width: label.width,
                        index: label.index,
                        isFirst: true,
                        isLast: false,
                    ));
                continue;
            } else if (label.isLast) {
                // Last label: ensure left edge aligns with last candle's left edge (last grid line position)
                final lastIndex = mapper.viewport.startIndex + (candles.length - 1);
                final lastGridLineX = mapper.indexToX(lastIndex);
                visibleLabels.add(_LabelInfo(
                        text: label.text,
                        x: lastGridLineX.clamp(chartLeft, chartRight - label.width),
                        width: label.width,
                        index: label.index,
                        isFirst: false,
                        isLast: true,
                    ));
                continue;
            }

            // Check if this middle label would overlap with any already visible label
            bool overlaps = false;
            for (final visible in visibleLabels) {
                final labelLeft = label.x;
                final labelRight = label.x + label.width;
                final visibleLeft = visible.x;
                final visibleRight = visible.x + visible.width;

                // Check if labels overlap (with minimum spacing)
                if ((labelLeft < visibleRight + minSpacing) && (labelRight + minSpacing > visibleLeft)) {
                    overlaps = true;
                    break;
                }
            }

            // Only add middle label if it doesn't overlap
            if (!overlaps) {
                visibleLabels.add(label);
            }
        }

        // Sort visible labels by index to maintain proper order
        visibleLabels.sort((a, b) => a.index.compareTo(b.index));

        // Calculate X-axis label position using layout model
        // Position: chartBottom + xAxisGap + labelPadding.top
        final chartBottom = mapper.paddingTop + mapper.contentHeight;
        final labelY = chartBottom + layout.xAxisGap + xAxisLabelPadding.top;

        // Draw all visible labels
        for (final labelInfo in visibleLabels) {
            // Re-layout text for this label
            textPainter.text = TextSpan(text: labelInfo.text, style: textStyle);
            textPainter.layout();

            // Draw background (if background color is provided and has alpha)
            if (bgColor.a > 0.0) {
                final paddingH = xAxisLabelPadding.horizontal;
                final paddingV = xAxisLabelPadding.vertical;
                final labelRect = Rect.fromLTWH(
                    labelInfo.x - paddingH,
                    labelY - xAxisLabelPadding.top,
                    labelInfo.width + paddingH * 2,
                    textPainter.height + paddingV,
                );
                canvas.drawRect(labelRect, bgPaint);
            }

            // Draw label at bottom (always draw text, regardless of background)
            textPainter.paint(
                canvas,
                Offset(labelInfo.x, labelY),
            );
        }
    }

    void _drawCurrentPriceLine(Canvas canvas, Size size, double price) {
        final y = mapper.priceToY(price);
        final scale = mapper.priceScale;

        // Determine price change direction for label color
        double? previousPrice;
        if (candles.length >= 2) {
            previousPrice = candles[candles.length - 2].close;
        } else if (candles.isNotEmpty) {
            previousPrice = candles.first.open;
        }
        final isPriceUp = previousPrice != null ? price >= previousPrice : true;

        // Check if price is within visible range
        final isPriceVisible = price >= scale.min && price <= scale.max;

        // Determine Y position for line and label
        double lineY;
        if (isPriceVisible) {
            lineY = y;
        } else if (price < scale.min) {
            lineY = mapper.paddingTop + mapper.contentHeight;
        } else {
            lineY = mapper.paddingTop;
        }

        final currentPriceStyle = style.currentPriceStyle;
        final layout = style.layout;
        final chartRight = mapper.paddingLeft + mapper.contentWidth;

        // Draw line (only if enabled and price is visible)
        if (currentPriceStyle.showLine && isPriceVisible) {
            final paint = Paint()
                ..color = currentPriceStyle.lineColor
                ..strokeWidth = currentPriceStyle.lineWidth;

            // Line extends to Y-axis label area (same as grid)
            double lineEndX = chartRight;
            if (style.priceLabelStyle.show) {
                final yAxisLabelPadding = style.priceLabelStyle.padding;
                final textStartX = chartRight + layout.yAxisGap + yAxisLabelPadding.left;
                lineEndX = textStartX - layout.gridToLabelGapY;
            }

            _drawStyledLine(
                canvas,
                Offset(mapper.paddingLeft, lineY),
                Offset(lineEndX.clamp(mapper.paddingLeft, size.width), lineY),
                paint,
                currentPriceStyle.lineStyle,
            );
        }

        // Draw price label (if enabled)
        if (!currentPriceStyle.showLabel) return;

        // TradingView approach: Current price label is in SAME column as Y-axis labels
        // Just styled with colored background
        final labelBgColor = isPriceUp
            ? currentPriceStyle.bullishColor
            : currentPriceStyle.bearishColor;

        final textStyle = TextStyle(
            color: currentPriceStyle.textColor,
            fontSize: currentPriceStyle.labelFontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
        );

        final priceFormatter = style.priceLabelStyle.formatter;
        final priceText = priceFormatter.format(price);
        final textPainter = TextPainter(
            text: TextSpan(text: priceText, style: textStyle),
            textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final labelPaddingH = currentPriceStyle.labelPaddingH;
        final labelPaddingV = currentPriceStyle.labelPaddingV;
        final labelCornerRadius = currentPriceStyle.labelBorderRadius;
        final labelWidth = textPainter.width + (labelPaddingH * 2);
        final labelHeight = textPainter.height + (labelPaddingV * 2);

        // TradingView approach: Current price label in SAME column as Y-axis labels
        // Y-axis label background starts at: chartRight + yAxisGap
        // Y-axis label text starts at: chartRight + yAxisGap + yAxisLabelPadding.left
        // Current price label should follow same pattern:
        // - Background starts at: chartRight + yAxisGap (aligned with Y-axis label backgrounds)
        // - Text starts at: bgStartX + labelPaddingH
        final bgStartX = chartRight + layout.yAxisGap;
        final textX = bgStartX + labelPaddingH;

        // Y position: centered on the price line, clamped to visible area
        double labelY = lineY - labelHeight / 2;
        labelY = labelY.clamp(
            mapper.paddingTop,
            mapper.paddingTop + mapper.contentHeight - labelHeight,
        );

        // Draw rounded rectangle background (aligned with Y-axis labels)
        final labelRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(bgStartX, labelY, labelWidth, labelHeight),
            Radius.circular(labelCornerRadius),
        );

        final bgPaint = Paint()
            ..color = labelBgColor
            ..style = PaintingStyle.fill;
        canvas.drawRRect(labelRect, bgPaint);

        // Draw text centered in background
        textPainter.paint(
            canvas,
            Offset(textX, labelY + labelPaddingV),
        );
    }

    void _drawStyledLine(
        Canvas canvas,
        Offset start,
        Offset end,
        Paint paint,
        PriceLineStyle lineStyle,
    ) {
        switch (lineStyle) {
            case PriceLineStyle.solid:
                canvas.drawLine(start, end, paint);
                break;
            case PriceLineStyle.dashed:
                _drawDashedLine(canvas, start, end, paint, [8.0, 4.0]);
                break;
            case PriceLineStyle.dotted:
                _drawDashedLine(canvas, start, end, paint, [2.0, 3.0]);
                break;
        }
    }

    void _drawDashedLine(
        Canvas canvas,
        Offset start,
        Offset end,
        Paint paint,
        List<double> dashArray,
    ) {
        // Calculate line length and direction
        final dx = end.dx - start.dx;
        final dy = end.dy - start.dy;
        final length = math.sqrt(dx * dx + dy * dy);

        if (length == 0) return;

        // Normalize direction
        final unitX = dx / length;
        final unitY = dy / length;

        final dashLength = dashArray[0];
        final gapLength = dashArray.length > 1 ? dashArray[1] : dashArray[0];
        final totalPatternLength = dashLength + gapLength;

        double distance = 0.0;

        // Draw dash segments along the line
        while (distance < length) {
            final dashStart = distance;
            final dashEnd = math.min(distance + dashLength, length);

            if (dashEnd > dashStart) {
                final startX = start.dx + unitX * dashStart;
                final startY = start.dy + unitY * dashStart;
                final endX = start.dx + unitX * dashEnd;
                final endY = start.dy + unitY * dashEnd;

                canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
            }

            distance += totalPatternLength;
        }
    }

    void _drawRippleOnLastPoint(Canvas canvas, Size size) {
        if (candles.isEmpty) return;

        final lastCandle = candles.last;
        final lastIndex = mapper.viewport.startIndex + candles.length - 1;
        final x = mapper.getCandleCenterX(lastIndex);
        final y = mapper.priceToY(lastCandle.close);
        final center = Offset(x, y);

        // Chart boundaries
        final chartLeft = mapper.paddingLeft;
        final chartRight = mapper.paddingLeft + mapper.contentWidth;
        final chartTop = mapper.paddingTop;
        final chartBottom = mapper.paddingTop + mapper.contentHeight;

        // Ensure center is within chart bounds
        if (center.dx < chartLeft || center.dx > chartRight ||
            center.dy < chartTop || center.dy > chartBottom) {
            return;
        }

        final centerPointRadius = style.lineStyle.pointRadius > 0 ? style.lineStyle.pointRadius : 4.0;
        final rippleStyle = style.rippleStyle;
        final pulseColor = rippleStyle.color;
        final layout = style.layout;

        // Draw glowing center point for maximum visibility
        // Outer glow
        final glowPaint = Paint()
            ..color = pulseColor.withValues(alpha: 0.4)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
            ..isAntiAlias = true;
        canvas.drawCircle(center, centerPointRadius + 3.0, glowPaint);

        // Main center point
        final centerPaint = Paint()
            ..color = pulseColor
            ..style = PaintingStyle.fill
            ..isAntiAlias = true;
        canvas.drawCircle(center, centerPointRadius, centerPaint);

        // Bright border for visibility
        final centerBorderPaint = Paint()
            ..color = pulseColor.withValues(alpha: 0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0
            ..isAntiAlias = true;
        canvas.drawCircle(center, centerPointRadius + 1.5, centerBorderPaint);

        // Draw ripple burst effect when animation is active
        if (pulseProgress > 0.001) {
            final easedProgress = _easeOutCubic(pulseProgress);

            // Use configured maxRadius from style
            final preferredRadius = rippleStyle.maxRadius;

            // Calculate available space - allow ripple to extend into yAxisGap
            final distanceToTop = center.dy - chartTop;
            final distanceToBottom = chartBottom - center.dy;
            final distanceToLeft = center.dx - chartLeft;
            // Allow ripple to extend into the yAxisGap (but not into labels)
            final distanceToRight = (chartRight + layout.yAxisGap) - center.dx;

            // Use minimum distance for symmetric ripple
            final minVertical = math.min(distanceToTop, distanceToBottom);
            final minHorizontal = math.min(distanceToLeft, distanceToRight);
            final maxRadius = math.min(preferredRadius, math.min(minVertical, minHorizontal));

            if (maxRadius < 3.0) return;

            final radius = maxRadius * easedProgress;
            final opacity = math.pow(1.0 - easedProgress, 0.7).clamp(0.0, 1.0);

            if (radius > 1.0 && opacity > 0.01) {
                final baseOpacity = opacity.clamp(0.0, 1.0);
                final maxOp = rippleStyle.maxOpacity;

                // More intense gradient for obvious visibility
                final gradient = ui.Gradient.radial(
                    center,
                    radius,
                    [
                        pulseColor.withValues(alpha: baseOpacity * maxOp),           // 100% at center
                        pulseColor.withValues(alpha: baseOpacity * maxOp * 0.9),     // 90%
                        pulseColor.withValues(alpha: baseOpacity * maxOp * 0.7),     // 70%
                        pulseColor.withValues(alpha: baseOpacity * maxOp * 0.4),     // 40%
                        pulseColor.withValues(alpha: baseOpacity * maxOp * 0.15),    // 15%
                        pulseColor.withValues(alpha: rippleStyle.minOpacity),        // Fade out
                    ],
                    [0.0, 0.2, 0.4, 0.6, 0.85, 1.0],
                );

                final paint = Paint()
                    ..shader = gradient
                    ..style = PaintingStyle.fill
                    ..isAntiAlias = true;

                // Clip to chart area + yAxisGap to allow ripple overflow
                canvas.save();
                canvas.clipRect(Rect.fromLTWH(
                        chartLeft,
                        chartTop,
                        (chartRight + layout.yAxisGap) - chartLeft,  // Allow into yAxisGap
                        chartBottom - chartTop,
                    ));

                // Draw filled ripple
                canvas.drawCircle(center, radius, paint);

                // Draw visible ring stroke for extra emphasis
                final ringPaint = Paint()
                    ..color = pulseColor.withValues(alpha: baseOpacity * maxOp * 0.6)
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 2.5
                    ..isAntiAlias = true;
                canvas.drawCircle(center, radius * 0.7, ringPaint);

                // Outer ring
                final outerRingPaint = Paint()
                    ..color = pulseColor.withValues(alpha: baseOpacity * maxOp * 0.3)
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 1.5
                    ..isAntiAlias = true;
                canvas.drawCircle(center, radius, outerRingPaint);

                canvas.restore();
            }
        }
    }

    // Easing function for smooth animation (ease-out cubic)
    // Clamp input to avoid edge cases that cause jitter
    // This creates a smooth deceleration curve perfect for bursting effects
    double _easeOutCubic(double t) {
        final clampedT = t.clamp(0.0, 1.0);
        final oneMinusT = 1.0 - clampedT;
        // Ease-out cubic: 1 - (1-t)^3
        // This starts fast and decelerates smoothly
        return 1.0 - (oneMinusT * oneMinusT * oneMinusT);
    }

    void _drawCrosshair(Canvas canvas, Size size) {
        if (crosshairPosition == null || crosshairIndex == null || crosshairIndex! < 0 || crosshairIndex! >= candles.length) {
            return;
        }

        final candle = candles[crosshairIndex!];

        // Calculate the EXACT position where the data point is drawn
        // This ensures crosshair perfectly aligns with the actual chart data point
        final absoluteIndex = mapper.viewport.startIndex + crosshairIndex!;
        final x = mapper.getCandleCenterX(absoluteIndex);
        final y = mapper.priceToY(candle.close);

        // Validate coordinates are within chart bounds
        if (!x.isFinite || !y.isFinite) return;

        // Get crosshair style
        final cs = style.crosshairStyle;

        // === LINE STYLING ===
        // Draw vertical line - extends full height of chart content area
        final vLinePaint = Paint()
            ..color = cs.verticalLineColor
            ..strokeWidth = cs.verticalLineWidth;
        _drawStyledLine(
            canvas,
            Offset(x, mapper.paddingTop),
            Offset(x, mapper.paddingTop + mapper.contentHeight),
            vLinePaint,
            cs.verticalLineStyle,
        );

        // Draw horizontal line - extends full width of chart content area at exact price level
        final hLinePaint = Paint()
            ..color = cs.horizontalLineColor
            ..strokeWidth = cs.horizontalLineWidth;
        _drawStyledLine(
            canvas,
            Offset(mapper.paddingLeft, y),
            Offset(mapper.paddingLeft + mapper.contentWidth, y),
            hLinePaint,
            cs.horizontalLineStyle,
        );

        // === TRACKER POINT ===
        // Draw highlighted point at exact intersection (on the actual data point)
        final pointPaint = Paint()
            ..color = cs.trackerColor
            ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), cs.trackerRadius, pointPaint);

        // Add outer ring for better visibility (if enabled)
        if (cs.showTrackerRing) {
            final ringPaint = Paint()
                ..color = cs.trackerRingColor
                ..style = PaintingStyle.stroke
                ..strokeWidth = cs.trackerRingWidth;
            canvas.drawCircle(Offset(x, y), cs.trackerRadius + 2.0, ringPaint);
        }

        // === LABEL STYLING ===
        final labelFontSize = cs.labelFontSize ?? style.labelFontSize;

        // === PRICE LABEL (Right side) ===
        if (cs.showPriceLabel) {
            // Use crosshair formatter with 4 decimal places for precision
            final crosshairPriceFormatter = PriceFormatter.crosshair();
            final priceText = crosshairPriceFormatter.format(candle.close);
            final priceTextStyle = TextStyle(
                color: cs.labelTextColor,
                fontSize: labelFontSize,
                fontWeight: cs.labelFontWeight,
            );
            final pricePainter = TextPainter(
                text: TextSpan(text: priceText, style: priceTextStyle),
                textDirection: TextDirection.ltr,
            );
            pricePainter.layout();

            // Position price label on right side of chart
            final priceLabelX = mapper.paddingLeft + mapper.contentWidth + style.axisStyle.yAxisPadding + 3;
            var priceLabelY = y - pricePainter.height / 2;

            // Clamp Y position to stay within chart bounds
            priceLabelY = priceLabelY.clamp(
                mapper.paddingTop,
                mapper.paddingTop + mapper.contentHeight - pricePainter.height,
            );

            // Draw background with rounded corners
            final priceBgRect = Rect.fromLTWH(
                priceLabelX - cs.labelPaddingH,
                priceLabelY - cs.labelPaddingV,
                pricePainter.width + (cs.labelPaddingH * 2),
                pricePainter.height + (cs.labelPaddingV * 2),
            );
            final priceBgPaint = Paint()
                ..color = cs.labelBackgroundColor
                ..style = PaintingStyle.fill;
            final priceRRect = RRect.fromRectAndRadius(priceBgRect, Radius.circular(cs.labelBorderRadius));
            canvas.drawRRect(priceRRect, priceBgPaint);

            // Draw price text
            pricePainter.paint(canvas, Offset(priceLabelX, priceLabelY));
        }

        // === TIME LABEL (Bottom) ===
        if (cs.showTimeLabel) {
            // Use crosshair time formatter: DD ShortMonth, YY HH:MM AM/PM
            final crosshairTimeFormatter = const CrosshairTimeFormatter();
            final timeText = crosshairTimeFormatter.format(candle.time);
            final timeTextStyle = TextStyle(
                color: cs.labelTextColor,
                fontSize: labelFontSize,
                fontWeight: cs.labelFontWeight,
            );
            final timePainter = TextPainter(
                text: TextSpan(text: timeText, style: timeTextStyle),
                textDirection: TextDirection.ltr,
            );
            timePainter.layout();

            // Position time label at bottom, centered on crosshair X
            var timeLabelX = x - timePainter.width / 2;
            // Clamp to stay within chart bounds
            timeLabelX = timeLabelX.clamp(
                mapper.paddingLeft,
                mapper.paddingLeft + mapper.contentWidth - timePainter.width,
            );
            final timeLabelY = mapper.paddingTop + mapper.contentHeight + style.axisStyle.xAxisPadding + 2;

            // Draw background with rounded corners
            final timeBgRect = Rect.fromLTWH(
                timeLabelX - cs.labelPaddingH,
                timeLabelY - cs.labelPaddingV,
                timePainter.width + (cs.labelPaddingH * 2),
                timePainter.height + (cs.labelPaddingV * 2),
            );
            final timeBgPaint = Paint()
                ..color = cs.labelBackgroundColor
                ..style = PaintingStyle.fill;
            final timeRRect = RRect.fromRectAndRadius(timeBgRect, Radius.circular(cs.labelBorderRadius));
            canvas.drawRRect(timeRRect, timeBgPaint);

            // Draw time text
            timePainter.paint(canvas, Offset(timeLabelX, timeLabelY));
        }
    }

    @override
    bool shouldRepaint(ChartPainter oldDelegate) {
        // Always repaint if candles list length changed
        if (candles.length != oldDelegate.candles.length) {
            return true;
        }

        // Check if last candle changed (for live updates)
        if (candles.isNotEmpty && oldDelegate.candles.isNotEmpty) {
            final lastCandle = candles.last;
            final oldLastCandle = oldDelegate.candles.last;
            if (lastCandle.close != oldLastCandle.close ||
                lastCandle.high != oldLastCandle.high ||
                lastCandle.low != oldLastCandle.low) {
                return true;
            }
        }

        return candles != oldDelegate.candles ||
            mapper != oldDelegate.mapper ||
            style != oldDelegate.style ||
            currentPrice != oldDelegate.currentPrice ||
            (pulseProgress - oldDelegate.pulseProgress).abs() > 0.01 ||
            crosshairPosition != oldDelegate.crosshairPosition ||
            crosshairIndex != oldDelegate.crosshairIndex;
    }
}

// ChartStyle is now in models/chart_style.dart