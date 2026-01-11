import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart'
    show Candle, ChartStyle;
import 'package:imp_trading_chart/src/data/enums.dart' show LineStyle;
import 'package:imp_trading_chart/src/formatters/price_formatter.dart'
    show PriceFormatter;
import 'package:imp_trading_chart/src/formatters/time_formatter.dart'
    show TimeFormatContext, CrosshairTimeFormatter;
import 'package:imp_trading_chart/src/math/coordinate_mapper.dart'
    show CoordinateMapper;

/// ---------------------------------------------------------------------------
/// INTERNAL LABEL MODEL (PRIVATE)
/// ---------------------------------------------------------------------------
///
/// Holds metadata about a single axis label.
/// This is used **only during layout calculation** to:
/// - Detect overlaps
/// - Preserve first & last labels
/// - Maintain consistent spacing
///
/// This class NEVER reaches rendering logic directly.
class _LabelInfo {
  /// The formatted label text
  final String text;

  /// X position (left-aligned)
  final double x;

  /// Precomputed width of the label text
  final double width;

  /// Index of the label in the sequence
  final int index;

  /// Whether this is the first label in the axis
  final bool isFirst;

  /// Whether this is the last label in the axis
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

/// ---------------------------------------------------------------------------
/// CHART PAINTER (CORE RENDERING LAYER)
/// ---------------------------------------------------------------------------
///
/// A **high-performance, stateless CustomPainter** responsible ONLY for drawing.
///
/// ### Responsibilities
/// - Render visible candles only (viewport-based)
/// - Draw grid, labels, line, ripple, crosshair
/// - Use precomputed math from [CoordinateMapper]
///
/// ### Explicit Non-Responsibilities
/// ❌ No state mutation
/// ❌ No data transformation
/// ❌ No gesture handling
/// ❌ No viewport logic
///
/// This separation ensures:
/// - Extremely fast repaint cycles
/// - Predictable rendering behavior
/// - Easy debugging and extensibility
class ChartPainter extends CustomPainter {
  /// Visible candles only (already clipped by viewport)
  final List<Candle> candles;

  /// Precomputed coordinate mapper (index → pixel, price → pixel)
  final CoordinateMapper mapper;

  /// Immutable styling configuration
  final ChartStyle style;

  /// Optional current price (used for price line & label)
  final double? currentPrice;

  /// Animation progress for ripple effect (0 → 1)
  final double pulseProgress;

  /// Touch position for crosshair (screen coordinates)
  final Offset? crosshairPosition;

  /// Index of candle under crosshair (relative to visible candles)
  final int? crosshairIndex;

  const ChartPainter({
    required this.candles,
    required this.mapper,
    required this.style,
    this.currentPrice,
    this.pulseProgress = 0.0,
    this.crosshairPosition,
    this.crosshairIndex,
  });

  /// -------------------------------------------------------------------------
  /// PAINT ENTRY POINT
  /// -------------------------------------------------------------------------
  ///
  /// Paint order is **EXTREMELY IMPORTANT** for correct layering:
  ///
  /// 1️⃣ Clip & draw chart data (line)
  /// 2️⃣ Restore clip
  /// 3️⃣ Grid
  /// 4️⃣ Axis labels
  /// 5️⃣ Current price
  /// 6️⃣ Ripple animation
  /// 7️⃣ Crosshair (ALWAYS TOPMOST)
  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    // Save canvas state so clipping does not affect other layers
    canvas.save();

    /// Clip drawing strictly to chart content area
    /// (prevents lines/glows from leaking into label regions)
    final chartRect = Rect.fromLTWH(
      mapper.paddingLeft,
      mapper.paddingTop,
      mapper.contentWidth,
      mapper.contentHeight,
    );
    canvas.clipRect(chartRect);

    /// Draw the price line (inside clipped area only)
    _drawLineChart(canvas);

    /// Restore canvas to allow grid & labels outside clip
    canvas.restore();

    /// Draw grid lines (extend visually into label areas)
    if (style.axisStyle.showGrid) {
      _drawGrid(canvas, size);
    }

    /// Draw Y-axis price labels (right side)
    if (style.priceLabelStyle.show) {
      _drawPriceLabels(canvas, size);
    }

    /// Draw X-axis time labels (bottom)
    if (style.timeLabelStyle.show) {
      _drawTimeLabels(canvas, size);
    }

    /// Draw current price indicator
    /// - Label always shown
    /// - Line optional
    if (currentPrice != null) {
      _drawCurrentPriceLine(canvas, size, currentPrice!);
    }

    /// Draw live ripple animation on the latest candle
    if (candles.isNotEmpty && style.rippleStyle.show) {
      _drawRippleOnLastPoint(canvas, size);
    }

    /// Crosshair MUST be last so it is never hidden
    if (crosshairPosition != null &&
        crosshairIndex != null &&
        style.crosshairStyle.show) {
      _drawCrosshair(canvas, size);
    }
  }

  /// -------------------------------------------------------------------------
  /// GRID RENDERING
  /// -------------------------------------------------------------------------
  ///
  /// Draws horizontal (price) and vertical (time) grid lines.
  ///
  /// Design goals:
  /// - All grid lines align PERFECTLY
  /// - Grid visually connects to labels (TradingView behavior)
  /// - No grid line ever overlaps label text
  void _drawGrid(Canvas canvas, Size size) {
    final axisStyle = style.axisStyle;
    if (!axisStyle.showGrid) return;

    final layout = style.layout;

    final paint = Paint()
      ..color = axisStyle.gridColor.withValues(alpha: 0.2)
      ..strokeWidth = axisStyle.gridLineWidth;

    /// Safety: avoid division by zero
    if (mapper.contentHeight <= 0) return;

    /// Chart boundaries (content only)
    final chartLeft = mapper.paddingLeft;
    final chartRight = mapper.paddingLeft + mapper.contentWidth;
    final chartTop = mapper.paddingTop;
    final chartBottom = mapper.paddingTop + mapper.contentHeight;

    /// Calculate where grid lines should END so they never touch label text
    double horizontalLineEndX = chartRight;
    if (style.priceLabelStyle.show) {
      final labelPadding = style.priceLabelStyle.padding;
      final textStartX = chartRight + layout.yAxisGap + labelPadding.left;
      horizontalLineEndX = textStartX - layout.gridToLabelGapY;
    }

    final clampedHorizontalEndX =
        horizontalLineEndX.clamp(chartLeft, size.width);

    double verticalLineEndY = chartBottom;
    if (style.timeLabelStyle.show) {
      final labelPadding = style.timeLabelStyle.padding;
      final textStartY = chartBottom + layout.xAxisGap + labelPadding.top;
      verticalLineEndY = textStartY - layout.gridToLabelGapX;
    }

    final clampedVerticalEndY = verticalLineEndY.clamp(chartTop, size.height);

    /// Draw horizontal grid lines (price levels)
    final horizontalLines = axisStyle.horizontalGridLines;
    if (horizontalLines > 0) {
      for (int i = 0; i <= horizontalLines; i++) {
        final y = chartTop + (mapper.contentHeight * i / horizontalLines);
        _drawStyledLine(
          canvas,
          Offset(chartLeft, y),
          Offset(clampedHorizontalEndX, y),
          paint,
          axisStyle.gridLineStyle,
        );
      }
    }

    /// Draw vertical grid lines (time levels)
    final visibleCount = candles.length;
    if (visibleCount == 0) return;

    final verticalLines = axisStyle.verticalGridLines > 0
        ? axisStyle.verticalGridLines
        : math.min(visibleCount, 6);

    for (int i = 0; i <= verticalLines; i++) {
      final relativeIndex =
          (visibleCount * i / verticalLines).round().clamp(0, visibleCount - 1);
      final index = mapper.viewport.startIndex + relativeIndex;
      final x = mapper.indexToX(index);

      if (x.isFinite && x >= chartLeft && x <= chartRight) {
        _drawStyledLine(
          canvas,
          Offset(x, chartTop),
          Offset(x, clampedVerticalEndY),
          paint,
          axisStyle.gridLineStyle,
        );
      }
    }
  }

  /// -------------------------------------------------------------------------
  /// LINE DISPATCHER
  /// -------------------------------------------------------------------------
  ///
  /// Decides how to render price data based on:
  /// - Number of candles
  /// - Line style (smooth vs straight)
  void _drawLineChart(Canvas canvas) {
    /// Single candle → draw a point (not a line)
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

  /// ---------------------------------------------------------------------------
  /// SINGLE DATA POINT RENDERING
  /// ---------------------------------------------------------------------------
  ///
  /// Draws a single point when only **one candle** is visible.
  ///
  /// WHY this exists:
  /// - A single candle cannot form a line
  /// - Without special handling, the point would appear stuck to an edge
  ///
  /// DESIGN:
  /// - X axis: centered horizontally inside chart content
  /// - Y axis: mapped using price scale (which centers single points with padding)
  ///
  /// This guarantees:
  /// - Alignment with current price line
  /// - Alignment with ripple animation
  /// - Visual consistency with multi-point charts
  void _drawSingleDataPoint(Canvas canvas) {
    if (candles.isEmpty) return;

    final candle = candles.first;
    if (!candle.close.isFinite) return;

    // Center horizontally in chart content
    final x = mapper.paddingLeft + (mapper.contentWidth / 2);

    // Y position derived from price scale (handles single-point centering)
    final y = mapper.priceToY(candle.close);

    if (!x.isFinite || !y.isFinite) return;

    final lineStyle = style.lineStyle;

    // Ensure a visible radius even if user disables pointRadius
    final pointRadius = lineStyle.pointRadius > 0 ? lineStyle.pointRadius : 6.0;

    /// Optional glow for visibility (drawn behind the point)
    if (lineStyle.showGlow) {
      final glowPaint = Paint()
        ..color = lineStyle.color.withValues(alpha: 0.3)
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, lineStyle.glowWidth * 3);
      canvas.drawCircle(Offset(x, y), pointRadius + 4, glowPaint);
    }

    /// Main data point
    final pointPaint = Paint()
      ..color = lineStyle.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), pointRadius, pointPaint);
  }

  /// ---------------------------------------------------------------------------
  /// STRAIGHT LINE CHART RENDERING
  /// ---------------------------------------------------------------------------
  ///
  /// Draws a polyline connecting candle close prices directly.
  ///
  /// Used when:
  /// - `lineStyle.smooth == false`
  ///
  /// Characteristics:
  /// - Fastest rendering path
  /// - No curve interpolation
  /// - Ideal for large datasets
  void _drawStraightLineChart(Canvas canvas) {
    if (candles.length < 2) return;

    final path = Path();
    bool isFirst = true;

    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      if (!candle.close.isFinite) continue;

      // Absolute index in full dataset
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

  /// ---------------------------------------------------------------------------
  /// SMOOTH LINE CHART RENDERING
  /// ---------------------------------------------------------------------------
  ///
  /// Draws a visually smooth curve through all data points.
  ///
  /// Used when:
  /// - `lineStyle.smooth == true`
  ///
  /// Implementation:
  /// - Collects valid points first
  /// - Generates a Cardinal Spline
  /// - Clips to chart bounds to prevent overflow artifacts
  void _drawSmoothLineChart(Canvas canvas) {
    if (candles.length < 2) return;

    final List<Offset> points = [];

    /// Collect all valid (finite) points
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

    /// Generate smooth spline path
    final path = _generateCardinalSplinePath(points);

    /// Clip to chart content area so curves never leak into labels
    final chartLeft = mapper.paddingLeft;
    final chartTop = mapper.paddingTop;
    final chartRight = mapper.paddingLeft + mapper.contentWidth;
    final chartBottom = mapper.paddingTop + mapper.contentHeight;

    canvas.save();
    canvas
        .clipRect(Rect.fromLTRB(chartLeft, chartTop, chartRight, chartBottom));
    _drawPathWithEffects(canvas, path);
    canvas.restore();
  }

  /// ---------------------------------------------------------------------------
  /// CARDINAL SPLINE GENERATION
  /// ---------------------------------------------------------------------------
  ///
  /// Generates a smooth curve passing **exactly through all points**.
  ///
  /// WHY Cardinal Spline:
  /// - Same family used by TradingView & fl_chart
  /// - No sharp corners
  /// - Continuous slope
  ///
  /// User control:
  /// - `curveTension = 0` → very smooth (Catmull-Rom)
  /// - `curveTension = 1` → straight lines
  Path _generateCardinalSplinePath(List<Offset> points) {
    final path = Path();
    final n = points.length;

    if (n < 2) return path;

    path.moveTo(points[0].dx, points[0].dy);

    if (n == 2) {
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }

    /// Invert user tension so higher value = more curvature
    final userTension = style.lineStyle.curveTension.clamp(0.0, 1.0);
    final tension = 1.0 - userTension;

    /// Cardinal coefficient
    final c = (1.0 - tension) / 2.0;

    for (int i = 0; i < n - 1; i++) {
      final Offset p0;
      final Offset p3;

      /// Virtual points ensure smooth endpoints
      if (i == 0) {
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
        p3 = Offset(
          2 * points[n - 1].dx - points[n - 2].dx,
          2 * points[n - 1].dy - points[n - 2].dy,
        );
      } else {
        p3 = points[i + 2];
      }

      /// Tangent vectors
      final t1x = c * (p2.dx - p0.dx);
      final t1y = c * (p2.dy - p0.dy);
      final t2x = c * (p3.dx - p1.dx);
      final t2y = c * (p3.dy - p1.dy);

      /// Convert Hermite → Bezier
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

  /// ---------------------------------------------------------------------------
  /// DRAW PATH WITH VISUAL EFFECTS
  /// ---------------------------------------------------------------------------
  ///
  /// Renders the final price path with optional visual layers:
  /// 1. Glow (behind the line)
  /// 2. Main stroke (actual line)
  /// 3. Optional data points (circles)
  ///
  /// IMPORTANT:
  /// - This method does ZERO calculations
  /// - Path is already prepared (straight or smooth)
  /// - Pure rendering only
  ///
  /// Rendering order is critical for correct visual stacking.
  void _drawPathWithEffects(Canvas canvas, Path path) {
    final lineStyle = style.lineStyle;

    /// -------------------------------------------------------------------------
    /// GLOW LAYER (drawn FIRST, behind the line)
    /// -------------------------------------------------------------------------
    ///
    /// - Uses blur mask for soft glow
    /// - Stroke width is expanded so glow appears outside the main line
    /// - Alpha is reduced to avoid overpowering the chart
    if (lineStyle.showGlow) {
      final glowPaint = Paint()
        ..color = lineStyle.color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineStyle.width + (lineStyle.glowWidth * 2)
        ..maskFilter =
            ui.MaskFilter.blur(ui.BlurStyle.normal, lineStyle.glowWidth);

      canvas.drawPath(path, glowPaint);
    }

    /// -------------------------------------------------------------------------
    /// MAIN LINE (actual price line)
    /// -------------------------------------------------------------------------
    ///
    /// - Rounded caps & joins to avoid sharp corners
    /// - Drawn ABOVE glow
    final linePaint = Paint()
      ..color = lineStyle.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineStyle.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    /// -------------------------------------------------------------------------
    /// DATA POINTS (optional)
    /// -------------------------------------------------------------------------
    ///
    /// - Useful for debugging or stylistic preference
    /// - Drawn on top of the line
    /// - Uses candle close price only
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

        canvas.drawCircle(
          Offset(x, y),
          lineStyle.pointRadius,
          pointPaint,
        );
      }
    }
  }

  /// ---------------------------------------------------------------------------
  /// Y-AXIS PRICE LABELS (RIGHT SIDE)
  /// ---------------------------------------------------------------------------
  ///
  /// Responsibilities:
  /// - Calculate evenly distributed price levels
  /// - Format prices using PriceFormatter
  /// - Render text + optional background
  /// - Align perfectly with grid lines
  ///
  /// Design goals:
  /// - TradingView-style label placement
  /// - No overlap with chart content
  /// - Correct behavior for single candle & flat price ranges
  void _drawPriceLabels(Canvas canvas, Size size) {
    final priceLabelStyle = style.priceLabelStyle;
    if (!priceLabelStyle.show) return;

    final layout = style.layout;

    final labelFontSize = priceLabelStyle.fontSize;
    final labelColor = priceLabelStyle.color;
    final bgColor = priceLabelStyle.backgroundColor ?? style.backgroundColor;
    final fontWeight = priceLabelStyle.fontWeight;
    final labelCount = priceLabelStyle.labelCount;
    final formatter = priceLabelStyle.formatter;

    /// Padding around label text (left/right & top/bottom)
    final yAxisLabelPadding = priceLabelStyle.padding;

    /// Guard: prevent division by zero
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

    /// Safety check:
    /// - Should never fail due to PriceScale guarantees
    /// - Kept for defensive programming
    if (scale.range <= 0 || !scale.max.isFinite || !scale.min.isFinite) {
      return;
    }

    /// -------------------------------------------------------------------------
    /// SPECIAL CASE: SINGLE LABEL
    /// -------------------------------------------------------------------------
    ///
    /// - When labelCount == 1
    /// - Show a single label centered vertically
    if (labelCount == 1) {
      final price = (scale.max + scale.min) / 2;
      if (!price.isFinite) return;

      final y = mapper.priceToY(price);
      final clampedY = y.clamp(
        mapper.paddingTop,
        mapper.paddingTop + mapper.contentHeight,
      );

      final priceText = formatter.format(price);
      textPainter.text = TextSpan(text: priceText, style: textStyle);
      textPainter.layout();

      if (textPainter.width <= 0 || textPainter.height <= 0) {
        return;
      }

      final chartRight = mapper.paddingLeft + mapper.contentWidth;
      final labelX = chartRight + layout.yAxisGap + yAxisLabelPadding.left;

      if (bgColor.a > 0.0) {
        final paddingH = yAxisLabelPadding.horizontal;
        final paddingV = yAxisLabelPadding.vertical;
        final rect = Rect.fromLTWH(
          labelX - yAxisLabelPadding.left,
          clampedY - textPainter.height / 2 - paddingV,
          textPainter.width + paddingH,
          textPainter.height + (paddingV * 2),
        );
        canvas.drawRect(rect, bgPaint);
      }

      textPainter.paint(
        canvas,
        Offset(labelX, clampedY - textPainter.height / 2),
      );
      return;
    }

    /// -------------------------------------------------------------------------
    /// NORMAL CASE: MULTIPLE LABELS
    /// -------------------------------------------------------------------------
    ///
    /// Prices distributed evenly from max → min
    for (int i = 0; i < labelCount; i++) {
      final price =
          scale.max - ((scale.max - scale.min) * i / (labelCount - 1));
      if (!price.isFinite) continue;

      final y = mapper.priceToY(price);
      final clampedY = y.clamp(
        mapper.paddingTop,
        mapper.paddingTop + mapper.contentHeight,
      );

      final priceText = formatter.format(price);
      textPainter.text = TextSpan(text: priceText, style: textStyle);
      textPainter.layout();

      if (textPainter.width <= 0 || textPainter.height <= 0) {
        continue;
      }

      final chartRight = mapper.paddingLeft + mapper.contentWidth;
      final labelX = chartRight + layout.yAxisGap + yAxisLabelPadding.left;

      if (bgColor.a > 0.0) {
        final paddingH = yAxisLabelPadding.horizontal;
        final paddingV = yAxisLabelPadding.vertical;
        final rect = Rect.fromLTWH(
          labelX - yAxisLabelPadding.left,
          clampedY - textPainter.height / 2 - paddingV,
          textPainter.width + paddingH,
          textPainter.height + (paddingV * 2),
        );
        canvas.drawRect(rect, bgPaint);
      }

      textPainter.paint(
        canvas,
        Offset(labelX, clampedY - textPainter.height / 2),
      );
    }
  }

  /// ---------------------------------------------------------------------------
  /// X-AXIS TIME LABELS (BOTTOM AXIS)
  /// ---------------------------------------------------------------------------
  ///
  /// Responsibilities:
  /// - Render time labels aligned with visible candles
  /// - Prevent label overlap automatically
  /// - Ensure perfect alignment with vertical grid lines
  /// - Support responsive formatting based on visible time span
  ///
  /// Design goals (TradingView-style):
  /// - First label aligns with first grid line
  /// - Last label aligns with last grid line
  /// - Middle labels align with their candle grid lines
  /// - Labels never overlap or overflow chart bounds
  ///
  /// Important architectural notes:
  /// - Labels are calculated FIRST, then filtered for overlap
  /// - Positioning uses CoordinateMapper (never raw pixel guesses)
  /// - Formatting is delegated to TimeFormatter with context
  ///
  /// This method does NOT:
  /// - Mutate state
  /// - Cache anything
  /// - Perform heavy calculations inside paint loops
  void _drawTimeLabels(Canvas canvas, Size size) {
    // No candles = nothing to label
    if (candles.isEmpty) return;

    final timeLabelStyle = style.timeLabelStyle;
    if (!timeLabelStyle.show) return;

    // Layout configuration (gaps, padding, grid alignment rules)
    final layout = style.layout;

    final labelFontSize = timeLabelStyle.fontSize;
    final labelColor = timeLabelStyle.color;
    final bgColor = timeLabelStyle.backgroundColor ?? style.backgroundColor;
    final fontWeight = timeLabelStyle.fontWeight;
    final labelCount = timeLabelStyle.labelCount;
    final formatter = timeLabelStyle.formatter;

    // Padding around X-axis labels (top/bottom)
    final xAxisLabelPadding = timeLabelStyle.padding;

    // Safety: avoid division by zero
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

    /// -------------------------------------------------------------------------
    /// LABEL COUNT RESOLUTION
    /// -------------------------------------------------------------------------
    ///
    /// We never show more labels than visible candles.
    /// This prevents clustering when zoomed in tightly.
    final visibleCount = candles.length;
    final labelCountToShow = math.min(visibleCount, labelCount);

    if (labelCountToShow <= 0) return;

    /// -------------------------------------------------------------------------
    /// RESPONSIVE TIME FORMATTING CONTEXT
    /// -------------------------------------------------------------------------
    ///
    /// Used by TimeFormatter to decide:
    /// - Whether to show date, time, or both
    /// - Whether to abbreviate month/year
    ///
    /// Example:
    /// - Large span → show date
    /// - Small span → show time only
    final firstCandle = candles.first;
    final lastCandle = candles.last;
    final visibleTimeSpan = Duration(
      seconds: (lastCandle.time - firstCandle.time).abs(),
    );

    // Chart boundaries (used for clamping)
    final chartLeft = mapper.paddingLeft;
    final chartRight = mapper.paddingLeft + mapper.contentWidth;

    /// -------------------------------------------------------------------------
    /// PASS 1: COLLECT ALL POTENTIAL LABELS
    /// -------------------------------------------------------------------------
    ///
    /// We first calculate ALL candidate labels with:
    /// - Text
    /// - X position
    /// - Width
    ///
    /// Then we filter overlaps in a second pass.
    final List<_LabelInfo> labelInfos = [];

    for (int i = 0; i < labelCountToShow; i++) {
      /// Distribute labels evenly across visible candles
      ///
      /// Example:
      /// - 3 labels over 100 candles → indices: 0, 50, 99
      final relativeIndex = (visibleCount > 1)
          ? ((visibleCount - 1) * i / (labelCountToShow - 1)).round()
          : 0;

      if (relativeIndex < 0 || relativeIndex >= candles.length) {
        continue;
      }

      final candle = candles[relativeIndex];

      /// Convert relative index → absolute data index
      final dataIndex = mapper.viewport.startIndex + relativeIndex;

      final x = mapper.indexToX(dataIndex);
      if (!x.isFinite) continue;

      final isFirstLabel = (i == 0);
      final isLastLabel = (i == labelCountToShow - 1);

      /// Create formatting context for formatter
      final context = TimeFormatContext(
        visibleTimeSpan: visibleTimeSpan,
        isFirstLabel: isFirstLabel,
        isLastLabel: isLastLabel,
        labelIndex: i,
        totalLabels: labelCountToShow,
      );

      final timeText = formatter.format(candle.time, context: context);

      textPainter.text = TextSpan(text: timeText, style: textStyle);
      textPainter.layout();

      if (textPainter.width <= 0 || textPainter.height <= 0) {
        continue;
      }

      /// Label alignment rules:
      /// - First → chartLeft
      /// - Last → last grid line
      /// - Middle → their candle’s grid line
      double labelX;

      if (visibleCount == 1 && labelCountToShow == 1) {
        // Single candle → center label
        labelX = x - (textPainter.width / 2);
      } else if (isFirstLabel) {
        labelX = chartLeft;
      } else if (isLastLabel) {
        labelX = x;
      } else {
        labelX = x;
      }

      // Clamp to visible bounds
      labelX = labelX.clamp(
        chartLeft,
        chartRight - textPainter.width,
      );

      labelInfos.add(
        _LabelInfo(
          text: timeText,
          x: labelX,
          width: textPainter.width,
          index: i,
          isFirst: isFirstLabel,
          isLast: isLastLabel,
        ),
      );
    }

    /// -------------------------------------------------------------------------
    /// PASS 2: OVERLAP FILTERING
    /// -------------------------------------------------------------------------
    ///
    /// Strategy:
    /// - Always keep first & last labels
    /// - Remove overlapping middle labels
    /// - Maintain minimum spacing between labels
    const double minSpacing = 8.0;

    final List<_LabelInfo> visibleLabels = [];

    for (final label in labelInfos) {
      // Single candle special case
      if (candles.length == 1 && labelInfos.length == 1) {
        final centerX = mapper.paddingLeft + (mapper.contentWidth / 2);

        visibleLabels.add(
          _LabelInfo(
            text: label.text,
            x: (centerX - label.width / 2).clamp(
              chartLeft,
              chartRight - label.width,
            ),
            width: label.width,
            index: label.index,
            isFirst: true,
            isLast: true,
          ),
        );
        continue;
      }

      if (label.isFirst || label.isLast) {
        visibleLabels.add(label);
        continue;
      }

      bool overlaps = false;
      for (final visible in visibleLabels) {
        if ((label.x < visible.x + visible.width + minSpacing) &&
            (label.x + label.width + minSpacing > visible.x)) {
          overlaps = true;
          break;
        }
      }

      if (!overlaps) {
        visibleLabels.add(label);
      }
    }

    /// Maintain correct order
    visibleLabels.sort(
      (a, b) => a.index.compareTo(b.index),
    );

    /// -------------------------------------------------------------------------
    /// FINAL DRAW PASS
    /// -------------------------------------------------------------------------
    ///
    /// Y position is fixed for all X-axis labels:
    /// chartBottom + gap + padding
    final chartBottom = mapper.paddingTop + mapper.contentHeight;

    final labelY = chartBottom + layout.xAxisGap + xAxisLabelPadding.top;

    for (final labelInfo in visibleLabels) {
      textPainter.text = TextSpan(text: labelInfo.text, style: textStyle);
      textPainter.layout();

      // Optional background
      if (bgColor.a > 0.0) {
        final labelRect = Rect.fromLTWH(
          labelInfo.x - xAxisLabelPadding.horizontal,
          labelY - xAxisLabelPadding.top,
          labelInfo.width + xAxisLabelPadding.horizontal * 2,
          textPainter.height + xAxisLabelPadding.vertical,
        );
        canvas.drawRect(labelRect, bgPaint);
      }

      // Draw label text
      textPainter.paint(
        canvas,
        Offset(labelInfo.x, labelY),
      );
    }
  }

  /// ---------------------------------------------------------------------------
  /// CURRENT PRICE LINE + LABEL
  /// ---------------------------------------------------------------------------
  ///
  /// Mimics TradingView behavior:
  /// - Line drawn only if price is visible
  /// - Label ALWAYS shown (if enabled)
  /// - Label shares same column as Y-axis labels
  ///
  /// Color logic:
  /// - Green if price >= previous close
  /// - Red otherwise
  void _drawCurrentPriceLine(Canvas canvas, Size size, double price) {
    final y = mapper.priceToY(price);
    final scale = mapper.priceScale;

    /// Determine price direction
    double? previousPrice;
    if (candles.length >= 2) {
      previousPrice = candles[candles.length - 2].close;
    } else if (candles.isNotEmpty) {
      previousPrice = candles.first.open;
    }

    final isPriceUp = previousPrice != null ? price >= previousPrice : true;

    /// Check visibility inside scale
    final isPriceVisible = price >= scale.min && price <= scale.max;

    /// Clamp line position if outside range
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

    /// -------------------------------------------------------------------------
    /// DRAW PRICE LINE (optional)
    /// -------------------------------------------------------------------------
    if (currentPriceStyle.showLine && isPriceVisible) {
      final paint = Paint()
        ..color = currentPriceStyle.lineColor
        ..strokeWidth = currentPriceStyle.lineWidth;

      double lineEndX = chartRight;
      if (style.priceLabelStyle.show) {
        final yAxisLabelPadding = style.priceLabelStyle.padding;
        final textStartX =
            chartRight + layout.yAxisGap + yAxisLabelPadding.left;
        lineEndX = textStartX - layout.gridToLabelGapY;
      }

      _drawStyledLine(
        canvas,
        Offset(mapper.paddingLeft, lineY),
        Offset(
          lineEndX.clamp(mapper.paddingLeft, size.width),
          lineY,
        ),
        paint,
        currentPriceStyle.lineStyle,
      );
    }

    /// -------------------------------------------------------------------------
    /// DRAW PRICE LABEL (always visible if enabled)
    /// -------------------------------------------------------------------------
    if (!currentPriceStyle.showLabel) return;

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

    final labelWidth = textPainter.width + (labelPaddingH * 2);
    final labelHeight = textPainter.height + (labelPaddingV * 2);

    /// Align with Y-axis labels (TradingView behavior)
    final bgStartX = chartRight + layout.yAxisGap;
    final textX = bgStartX + labelPaddingH;

    double labelY = lineY - labelHeight / 2;
    labelY = labelY.clamp(
      mapper.paddingTop,
      mapper.paddingTop + mapper.contentHeight - labelHeight,
    );

    final labelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bgStartX, labelY, labelWidth, labelHeight),
      Radius.circular(currentPriceStyle.labelBorderRadius),
    );

    final bgPaint = Paint()
      ..color = labelBgColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(labelRect, bgPaint);

    textPainter.paint(
      canvas,
      Offset(textX, labelY + labelPaddingV),
    );
  }

  /// ---------------------------------------------------------------------------
  /// DRAW STYLED LINE (SOLID / DASHED / DOTTED)
  /// ---------------------------------------------------------------------------
  ///
  /// Central dispatcher for line rendering styles.
  ///
  /// Why this exists:
  /// - Keeps style decisions out of calling code
  /// - Allows grid lines, price lines, crosshair lines to share logic
  ///
  /// This method:
  /// - Does NOT calculate coordinates
  /// - Does NOT mutate state
  /// - Only decides HOW a line is drawn
  void _drawStyledLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    LineStyle lineStyle,
  ) {
    switch (lineStyle) {
      case LineStyle.solid:
        // Simple, continuous line
        canvas.drawLine(start, end, paint);
        break;

      case LineStyle.dashed:
        // Dash pattern: long dash + gap
        _drawDashedLine(canvas, start, end, paint, [8.0, 4.0]);
        break;

      case LineStyle.dotted:
        // Dot-like pattern: short dash + gap
        _drawDashedLine(canvas, start, end, paint, [2.0, 3.0]);
        break;
    }
  }

  /// ---------------------------------------------------------------------------
  /// DRAW DASHED / DOTTED LINE
  /// ---------------------------------------------------------------------------
  ///
  /// Generic dashed-line renderer using vector math.
  ///
  /// How it works:
  /// 1. Compute direction vector from start → end
  /// 2. Normalize direction
  /// 3. Step forward in dash + gap increments
  /// 4. Draw short line segments (dashes)
  ///
  /// Why manual implementation:
  /// - Flutter Canvas has no native dashed-line support
  /// - Gives full control over dash & gap lengths
  /// - Used consistently across grid, price lines, crosshair
  ///
  /// dashArray:
  /// - [dashLength, gapLength]
  /// - If only one value provided, same value used for both
  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    List<double> dashArray,
  ) {
    /// Vector from start to end
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;

    /// Euclidean length of the line
    final length = math.sqrt(dx * dx + dy * dy);

    /// Guard: zero-length line
    if (length == 0) return;

    /// Normalize direction vector
    final unitX = dx / length;
    final unitY = dy / length;

    /// Dash & gap lengths
    final dashLength = dashArray[0];
    final gapLength = dashArray.length > 1 ? dashArray[1] : dashArray[0];

    /// Total length of one dash+gap cycle
    final totalPatternLength = dashLength + gapLength;

    double distance = 0.0;

    /// Walk along the line and draw dash segments
    while (distance < length) {
      final dashStart = distance;
      final dashEnd = math.min(distance + dashLength, length);

      if (dashEnd > dashStart) {
        final startX = start.dx + unitX * dashStart;
        final startY = start.dy + unitY * dashStart;
        final endX = start.dx + unitX * dashEnd;
        final endY = start.dy + unitY * dashEnd;

        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          paint,
        );
      }

      distance += totalPatternLength;
    }
  }

  /// ---------------------------------------------------------------------------
  /// RIPPLE / PULSE EFFECT ON LAST DATA POINT
  /// ---------------------------------------------------------------------------
  ///
  /// Purpose:
  /// - Visually highlight the most recent price
  /// - Indicate live / updating data
  /// - Mimic TradingView-style pulse animation
  ///
  /// Visual layers (from bottom → top):
  /// 1. Soft outer glow
  /// 2. Solid center point
  /// 3. Bright outline ring
  /// 4. Expanding radial ripple (animated)
  ///
  /// IMPORTANT:
  /// - Uses ONLY last candle
  /// - Uses easing to avoid harsh animation
  /// - Clipped to chart + yAxisGap (never overlaps labels)
  void _drawRippleOnLastPoint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    /// Determine exact position of last data point
    final lastCandle = candles.last;
    final lastIndex = mapper.viewport.startIndex + candles.length - 1;
    final x = mapper.getCandleCenterX(lastIndex);
    final y = mapper.priceToY(lastCandle.close);
    final center = Offset(x, y);

    /// Chart boundaries
    final chartLeft = mapper.paddingLeft;
    final chartRight = mapper.paddingLeft + mapper.contentWidth;
    final chartTop = mapper.paddingTop;
    final chartBottom = mapper.paddingTop + mapper.contentHeight;

    /// Guard: ensure point is visible
    if (center.dx < chartLeft ||
        center.dx > chartRight ||
        center.dy < chartTop ||
        center.dy > chartBottom) {
      return;
    }

    final centerPointRadius =
        style.lineStyle.pointRadius > 0 ? style.lineStyle.pointRadius : 4.0;

    final rippleStyle = style.rippleStyle;
    final pulseColor = rippleStyle.color;
    final layout = style.layout;

    /// -------------------------------------------------------------------------
    /// CENTER POINT (STATIC)
    /// -------------------------------------------------------------------------

    /// Soft outer glow
    final glowPaint = Paint()
      ..color = pulseColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
      ..isAntiAlias = true;
    canvas.drawCircle(
      center,
      centerPointRadius + 3.0,
      glowPaint,
    );

    /// Main filled point
    final centerPaint = Paint()
      ..color = pulseColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(center, centerPointRadius, centerPaint);

    /// Bright outline ring (contrast on dark backgrounds)
    final centerBorderPaint = Paint()
      ..color = pulseColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;
    canvas.drawCircle(
      center,
      centerPointRadius + 1.5,
      centerBorderPaint,
    );

    /// -------------------------------------------------------------------------
    /// RIPPLE ANIMATION (EXPANDING CIRCLE)
    /// -------------------------------------------------------------------------
    if (pulseProgress > 0.001) {
      final easedProgress = _easeOutCubic(pulseProgress);

      /// Max radius requested by style
      final preferredRadius = rippleStyle.maxRadius;

      /// Available space (allow overflow into yAxisGap)
      final distanceToTop = center.dy - chartTop;
      final distanceToBottom = chartBottom - center.dy;
      final distanceToLeft = center.dx - chartLeft;
      final distanceToRight = (chartRight + layout.yAxisGap) - center.dx;

      /// Clamp ripple to smallest available space
      final minVertical = math.min(distanceToTop, distanceToBottom);
      final minHorizontal = math.min(distanceToLeft, distanceToRight);

      final maxRadius = math.min(
        preferredRadius,
        math.min(minVertical, minHorizontal),
      );

      if (maxRadius < 3.0) return;

      final radius = maxRadius * easedProgress;
      final opacity = math.pow(1.0 - easedProgress, 0.7).clamp(0.0, 1.0);

      if (radius > 1.0 && opacity > 0.01) {
        final baseOpacity = opacity.clamp(0.0, 1.0);
        final maxOp = rippleStyle.maxOpacity;

        /// Radial gradient for smooth fade-out
        final gradient = ui.Gradient.radial(
          center,
          radius,
          [
            pulseColor.withValues(alpha: baseOpacity * maxOp),
            pulseColor.withValues(alpha: baseOpacity * maxOp * 0.9),
            pulseColor.withValues(alpha: baseOpacity * maxOp * 0.7),
            pulseColor.withValues(alpha: baseOpacity * maxOp * 0.4),
            pulseColor.withValues(alpha: baseOpacity * maxOp * 0.15),
            pulseColor.withValues(
              alpha: rippleStyle.minOpacity,
            ),
          ],
          [0.0, 0.2, 0.4, 0.6, 0.85, 1.0],
        );

        final paint = Paint()
          ..shader = gradient
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;

        /// Allow ripple into yAxisGap, but NOT into labels
        canvas.save();
        canvas.clipRect(
          Rect.fromLTWH(
            chartLeft,
            chartTop,
            (chartRight + layout.yAxisGap) - chartLeft,
            chartBottom - chartTop,
          ),
        );

        /// Filled ripple
        canvas.drawCircle(center, radius, paint);

        /// Inner emphasis ring
        final ringPaint = Paint()
          ..color = pulseColor.withValues(alpha: baseOpacity * maxOp * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..isAntiAlias = true;
        canvas.drawCircle(center, radius * 0.7, ringPaint);

        /// Outer subtle ring
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

  /// ---------------------------------------------------------------------------
  /// EASING FUNCTION — EASE-OUT CUBIC
  /// ---------------------------------------------------------------------------
  ///
  /// Purpose:
  /// - Smooth deceleration for animations (used by ripple / pulse)
  /// - Starts fast, slows down naturally toward the end
  ///
  /// Why ease-out cubic:
  /// - Ideal for burst / ripple effects
  /// - Visually pleasing and non-linear
  /// - Mimics TradingView-style animations
  ///
  /// Mathematical form:
  ///   f(t) = 1 - (1 - t)^3
  ///
  /// Input:
  /// - t ∈ [0, 1]
  ///
  /// Output:
  /// - Smoothly eased value ∈ [0, 1]
  ///
  /// Important:
  /// - Input is clamped to avoid jitter or overshoot
  /// - No state, no side effects
  double _easeOutCubic(double t) {
    // Clamp input to valid animation range
    final clampedT = t.clamp(0.0, 1.0);

    final oneMinusT = 1.0 - clampedT;

    // Ease-out cubic curve:
    // Fast at start, slow at end
    return 1.0 - (oneMinusT * oneMinusT * oneMinusT);
  }

  /// ---------------------------------------------------------------------------
  /// CROSSHAIR RENDERING
  /// ---------------------------------------------------------------------------
  ///
  /// Responsibilities:
  /// - Draw vertical & horizontal guide lines
  /// - Draw tracker point at exact data location
  /// - Draw price label (right axis)
  /// - Draw time label (bottom axis)
  ///
  /// Design principles:
  /// - Pixel-perfect alignment with rendered data
  /// - No guessing based on touch position
  /// - Always mapped through CoordinateMapper
  ///
  /// IMPORTANT:
  /// - Crosshair uses candle INDEX, not raw touch X
  /// - Ensures alignment with line / candlestick centers
  void _drawCrosshair(Canvas canvas, Size size) {
    // Guard: ensure valid crosshair state
    if (crosshairPosition == null ||
        crosshairIndex == null ||
        crosshairIndex! < 0 ||
        crosshairIndex! >= candles.length) {
      return;
    }

    final candle = candles[crosshairIndex!];

    /// Calculate the EXACT rendered position of the data point
    /// This ensures perfect alignment between:
    /// - Crosshair lines
    /// - Tracker dot
    /// - Chart line / candle
    final absoluteIndex = mapper.viewport.startIndex + crosshairIndex!;
    final x = mapper.getCandleCenterX(absoluteIndex);
    final y = mapper.priceToY(candle.close);

    // Guard against invalid geometry
    if (!x.isFinite || !y.isFinite) return;

    final cs = style.crosshairStyle;

    /// -------------------------------------------------------------------------
    /// CROSSHAIR LINES
    /// -------------------------------------------------------------------------

    // Vertical line (time axis)
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

    // Horizontal line (price axis)
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

    /// -------------------------------------------------------------------------
    /// TRACKER POINT (INTERSECTION)
    /// -------------------------------------------------------------------------

    // Solid center point
    final pointPaint = Paint()
      ..color = cs.trackerColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(x, y),
      cs.trackerRadius,
      pointPaint,
    );

    // Optional outer ring for contrast
    if (cs.showTrackerRing) {
      final ringPaint = Paint()
        ..color = cs.trackerRingColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = cs.trackerRingWidth;

      canvas.drawCircle(
        Offset(x, y),
        cs.trackerRadius + 2.0,
        ringPaint,
      );
    }

    /// -------------------------------------------------------------------------
    /// LABEL STYLING
    /// -------------------------------------------------------------------------

    final labelFontSize = cs.labelFontSize ?? style.labelFontSize;

    /// -------------------------------------------------------------------------
    /// PRICE LABEL (RIGHT SIDE)
    /// -------------------------------------------------------------------------
    if (cs.showPriceLabel) {
      // High-precision formatter for crosshair
      final crosshairPriceFormatter = PriceFormatter.crosshair();

      final priceText = crosshairPriceFormatter.format(candle.close);

      final priceTextStyle = TextStyle(
        color: cs.labelTextColor,
        fontSize: labelFontSize,
        fontWeight: cs.labelFontWeight,
      );

      final pricePainter = TextPainter(
        text: TextSpan(
          text: priceText,
          style: priceTextStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      pricePainter.layout();

      /// Position price label just outside chart content
      final priceLabelX = mapper.paddingLeft +
          mapper.contentWidth +
          style.axisStyle.yAxisPadding +
          3;

      var priceLabelY = y - pricePainter.height / 2;

      // Clamp vertically to visible area
      priceLabelY = priceLabelY.clamp(
        mapper.paddingTop,
        mapper.paddingTop + mapper.contentHeight - pricePainter.height,
      );

      // Background rectangle
      final priceBgRect = Rect.fromLTWH(
        priceLabelX - cs.labelPaddingH,
        priceLabelY - cs.labelPaddingV,
        pricePainter.width + (cs.labelPaddingH * 2),
        pricePainter.height + (cs.labelPaddingV * 2),
      );

      final priceBgPaint = Paint()
        ..color = cs.labelBackgroundColor
        ..style = PaintingStyle.fill;

      final priceRRect = RRect.fromRectAndRadius(
        priceBgRect,
        Radius.circular(cs.labelBorderRadius),
      );

      canvas.drawRRect(priceRRect, priceBgPaint);

      // Draw text
      pricePainter.paint(
        canvas,
        Offset(priceLabelX, priceLabelY),
      );
    }

    /// -------------------------------------------------------------------------
    /// TIME LABEL (BOTTOM)
    /// -------------------------------------------------------------------------
    if (cs.showTimeLabel) {
      // Fixed TradingView-style formatter
      final crosshairTimeFormatter = const CrosshairTimeFormatter();

      final timeText = crosshairTimeFormatter.format(candle.time);

      final timeTextStyle = TextStyle(
        color: cs.labelTextColor,
        fontSize: labelFontSize,
        fontWeight: cs.labelFontWeight,
      );

      final timePainter = TextPainter(
        text: TextSpan(
          text: timeText,
          style: timeTextStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      timePainter.layout();

      /// Center label on crosshair X
      var timeLabelX = x - timePainter.width / 2;

      timeLabelX = timeLabelX.clamp(
        mapper.paddingLeft,
        mapper.paddingLeft + mapper.contentWidth - timePainter.width,
      );

      final timeLabelY = mapper.paddingTop +
          mapper.contentHeight +
          style.axisStyle.xAxisPadding +
          2;

      final timeBgRect = Rect.fromLTWH(
        timeLabelX - cs.labelPaddingH,
        timeLabelY - cs.labelPaddingV,
        timePainter.width + (cs.labelPaddingH * 2),
        timePainter.height + (cs.labelPaddingV * 2),
      );

      final timeBgPaint = Paint()
        ..color = cs.labelBackgroundColor
        ..style = PaintingStyle.fill;

      final timeRRect = RRect.fromRectAndRadius(
        timeBgRect,
        Radius.circular(cs.labelBorderRadius),
      );

      canvas.drawRRect(timeRRect, timeBgPaint);

      timePainter.paint(
        canvas,
        Offset(timeLabelX, timeLabelY),
      );
    }
  }

  /// ---------------------------------------------------------------------------
  /// REPAINT DECISION — PERFORMANCE CRITICAL
  /// ---------------------------------------------------------------------------
  ///
  /// Determines whether the chart must be repainted.
  ///
  /// Strategy:
  /// - Be aggressive for live updates
  /// - Be conservative for static state
  ///
  /// Why this matters:
  /// - CustomPainter repaint = expensive
  /// - Avoid unnecessary GPU work
  /// - Keep scrolling / gestures smooth
  @override
  bool shouldRepaint(ChartPainter oldDelegate) {
    /// Candle count change → structural change
    if (candles.length != oldDelegate.candles.length) {
      return true;
    }

    /// Live update optimization:
    /// Only repaint if last candle values changed
    if (candles.isNotEmpty && oldDelegate.candles.isNotEmpty) {
      final lastCandle = candles.last;
      final oldLastCandle = oldDelegate.candles.last;

      if (lastCandle.close != oldLastCandle.close ||
          lastCandle.high != oldLastCandle.high ||
          lastCandle.low != oldLastCandle.low) {
        return true;
      }
    }

    /// Full state comparison fallback
    return candles != oldDelegate.candles ||
        mapper != oldDelegate.mapper ||
        style != oldDelegate.style ||
        currentPrice != oldDelegate.currentPrice ||
        (pulseProgress - oldDelegate.pulseProgress).abs() > 0.01 ||
        crosshairPosition != oldDelegate.crosshairPosition ||
        crosshairIndex != oldDelegate.crosshairIndex;
  }
}
