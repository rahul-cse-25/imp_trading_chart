# ImpChart Quick Reference Guide

## Common Calculations Cheat Sheet

### 1. Viewport Calculations

#### Show Last N Candles
```dart
startIndex = (totalCount - visibleCount).clamp(0, totalCount)
// Example: totalCount=500, visibleCount=100 → startIndex=400
// Shows candles [400, 500)
```

#### Pan Right (Show Older Data)
```dart
newStart = (startIndex - delta).clamp(0, maxStart)
// Example: startIndex=400, delta=10 → newStart=390
// Scrolled 10 candles to the right (showing older data)
```

#### Pan Left (Show Newer Data)
```dart
newStart = (startIndex + delta).clamp(0, maxStart)
// Example: startIndex=400, delta=10 → newStart=410
// Scrolled 10 candles to the left (showing newer data)
```

#### Zoom In (Fewer Candles)
```dart
newVisible = (visibleCount - delta).clamp(minVisible, maxVisible)
// Example: visibleCount=100, delta=10 → newVisible=90
// Shows 90 candles instead of 100 (zoomed in)
```

#### Zoom Out (More Candles)
```dart
newVisible = (visibleCount + delta).clamp(minVisible, maxVisible)
// Example: visibleCount=100, delta=10 → newVisible=110
// Shows 110 candles instead of 100 (zoomed out)
```

---

### 2. Coordinate Mapping

#### Index to X Coordinate
```dart
relativeIndex = index - viewport.startIndex
normalizedX = relativeIndex / viewport.visibleCount
x = (normalizedX * contentWidth) + paddingLeft
```

**Example**:
- `index = 450`, `startIndex = 400`, `visibleCount = 100`
- `contentWidth = 380`, `paddingLeft = 10`
- `relativeIndex = 450 - 400 = 50`
- `normalizedX = 50 / 100 = 0.5`
- `x = (0.5 * 380) + 10 = 200` ✅

#### X Coordinate to Index
```dart
relativeX = x - paddingLeft
normalizedX = relativeX / contentWidth
relativeIndex = (normalizedX * visibleCount).round()
index = startIndex + relativeIndex
```

**Example**:
- `x = 200`, `paddingLeft = 10`, `contentWidth = 380`
- `startIndex = 400`, `visibleCount = 100`
- `relativeX = 200 - 10 = 190`
- `normalizedX = 190 / 380 = 0.5`
- `relativeIndex = (0.5 * 100).round() = 50`
- `index = 400 + 50 = 450` ✅

#### Price to Y Coordinate
```dart
normalized = (price - scale.min) / scale.range
y_in_content = contentHeight * (1.0 - normalized)
y = y_in_content + paddingTop
```

**Example**:
- `price = 150`, `scale.min = 100`, `scale.max = 200`, `scale.range = 100`
- `contentHeight = 280`, `paddingTop = 10`
- `normalized = (150 - 100) / 100 = 0.5`
- `y_in_content = 280 * (1.0 - 0.5) = 140`
- `y = 140 + 10 = 150` ✅

#### Y Coordinate to Price
```dart
relativeY = y - paddingTop
normalized = 1.0 - (relativeY / contentHeight)
price = scale.min + (normalized * scale.range)
```

**Example**:
- `y = 150`, `paddingTop = 10`, `contentHeight = 280`
- `scale.min = 100`, `scale.range = 100`
- `relativeY = 150 - 10 = 140`
- `normalized = 1.0 - (140 / 280) = 0.5`
- `price = 100 + (0.5 * 100) = 150` ✅

---

### 3. Price Scale Calculations

#### Calculate Price Scale from Candles
```dart
minPrice = min(all candle.low)
maxPrice = max(all candle.high)
priceRange = maxPrice - minPrice
padding = priceRange * paddingPercent  // default: 0.05 (5%)
min = minPrice - padding
max = maxPrice + padding
range = max - min
```

**Example**:
- Candles: `[low: 100, high: 110], [low: 105, high: 120], [low: 115, high: 125]`
- `minPrice = 100`, `maxPrice = 125`
- `priceRange = 125 - 100 = 25`
- `padding = 25 * 0.05 = 1.25`
- `min = 100 - 1.25 = 98.75`
- `max = 125 + 1.25 = 126.25`
- `range = 126.25 - 98.75 = 27.5` ✅

---

### 4. Layout Calculations

#### Content Area Dimensions
```dart
contentWidth = chartWidth - paddingLeft - paddingRight
contentHeight = chartHeight - paddingTop - paddingBottom
```

**Example**:
- `chartWidth = 400`, `chartHeight = 300`
- `paddingLeft = 10`, `paddingRight = 109`, `paddingTop = 10`, `paddingBottom = 30`
- `contentWidth = 400 - 10 - 109 = 281`
- `contentHeight = 300 - 10 - 30 = 260` ✅

#### Candle Width
```dart
candleWidth = contentWidth / viewport.visibleCount
```

**Example**:
- `contentWidth = 281`, `visibleCount = 100`
- `candleWidth = 281 / 100 = 2.81` pixels per candle ✅

#### Y-Axis Label Position
```dart
chartRight = paddingLeft + contentWidth
labelX = chartRight + yAxisGap + yAxisLabelPadding.left
```

**Example**:
- `paddingLeft = 10`, `contentWidth = 281`
- `yAxisGap = 8`, `yAxisLabelPadding.left = 25`
- `chartRight = 10 + 281 = 291`
- `labelX = 291 + 8 + 25 = 324` ✅

#### X-Axis Label Position
```dart
chartBottom = paddingTop + contentHeight
labelY = chartBottom + xAxisGap + xAxisLabelPadding.top
```

**Example**:
- `paddingTop = 10`, `contentHeight = 260`
- `xAxisGap = 8`, `xAxisLabelPadding.top = 10`
- `chartBottom = 10 + 260 = 270`
- `labelY = 270 + 8 + 10 = 288` ✅

#### Grid Line End Positions
```dart
// Horizontal lines (Y-axis)
textStartX = chartRight + yAxisGap + yAxisLabelPadding.left
horizontalLineEndX = textStartX - gridToLabelGapY

// Vertical lines (X-axis)
textStartY = chartBottom + xAxisGap + xAxisLabelPadding.top
verticalLineEndY = textStartY - gridToLabelGapX
```

**Example**:
- `chartRight = 291`, `yAxisGap = 8`, `yAxisLabelPadding.left = 25`, `gridToLabelGapY = 4`
- `textStartX = 291 + 8 + 25 = 324`
- `horizontalLineEndX = 324 - 4 = 320` ✅
- All horizontal grid lines extend to X=320

- `chartBottom = 270`, `xAxisGap = 8`, `xAxisLabelPadding.top = 10`, `gridToLabelGapX = 4`
- `textStartY = 270 + 8 + 10 = 288`
- `verticalLineEndY = 288 - 4 = 284` ✅
- All vertical grid lines extend to Y=284

---

### 5. Dynamic Padding Calculations

#### Y-Axis Area Width
```dart
// Step 1: Measure widest label
maxLabelWidth = max(all price label widths)

// Step 2: Base width
baseYAxisWidth = yAxisGap + maxLabelWidth + yAxisLabelPadding.horizontal

// Step 3: Add ripple extension (if enabled)
rippleExtension = maxRippleRadius + pointRadius + 3.0

// Step 4: Add current price label (if shown)
currentPriceLabelArea = rippleExtension + currentPriceLabelGap + currentPriceLabelWidth

// Step 5: Final width
yAxisAreaWidth = max(baseYAxisWidth, currentPriceLabelArea)
paddingRight = yAxisAreaWidth
```

**Example**:
- `yAxisGap = 8`
- `maxLabelWidth = 45` (widest price: "$205.00")
- `yAxisLabelPadding.horizontal = 25`
- `baseYAxisWidth = 8 + 45 + 25 = 78`
- `rippleExtension = 31` (if enabled)
- `currentPriceLabelWidth = 60` (if shown)
- `currentPriceLabelArea = 31 + 4 + 60 = 95`
- `yAxisAreaWidth = max(78, 95) = 95`
- `paddingRight = 95` ✅

#### X-Axis Area Height
```dart
// Measure label height
labelHeight = textPainter.height  // Sample: "00:00"

// Calculate height
xAxisAreaHeight = xAxisGap + labelHeight + xAxisLabelPadding.vertical
paddingBottom = xAxisAreaHeight
```

**Example**:
- `xAxisGap = 8`
- `labelHeight = 12` (time label height)
- `xAxisLabelPadding.vertical = 10`
- `xAxisAreaHeight = 8 + 12 + 10 = 30`
- `paddingBottom = 30` ✅

---

### 6. Grid Line Distribution

#### Horizontal Grid Lines (Price Levels)
```dart
for (int i = 0; i <= horizontalLines; i++) {
  y = chartTop + (contentHeight * i / horizontalLines)
}
```

**Example** (5 horizontal lines):
- `chartTop = 10`, `contentHeight = 260`
- Line 0: `y = 10 + (260 * 0 / 5) = 10` (top)
- Line 1: `y = 10 + (260 * 1 / 5) = 62` (20%)
- Line 2: `y = 10 + (260 * 2 / 5) = 114` (40%)
- Line 3: `y = 10 + (260 * 3 / 5) = 166` (60%)
- Line 4: `y = 10 + (260 * 4 / 5) = 218` (80%)
- Line 5: `y = 10 + (260 * 5 / 5) = 270` (bottom) ✅

#### Vertical Grid Lines (Time Levels)
```dart
for (int i = 0; i <= verticalLines; i++) {
  relativeIndex = (visibleCount * i / verticalLines).round()
  index = viewport.startIndex + relativeIndex
  x = mapper.indexToX(index)
}
```

**Example** (6 vertical lines, 100 visible candles):
- `startIndex = 400`, `visibleCount = 100`
- Line 0: `relativeIndex = (100 * 0 / 6).round() = 0` → `index = 400` → `x = 10` (left)
- Line 1: `relativeIndex = (100 * 1 / 6).round() = 17` → `index = 417` → `x ≈ 58`
- Line 2: `relativeIndex = (100 * 2 / 6).round() = 33` → `index = 433` → `x ≈ 106`
- Line 3: `relativeIndex = (100 * 3 / 6).round() = 50` → `index = 450` → `x ≈ 155` (middle)
- Line 4: `relativeIndex = (100 * 4 / 6).round() = 67` → `index = 467` → `x ≈ 203`
- Line 5: `relativeIndex = (100 * 5 / 6).round() = 83` → `index = 483` → `x ≈ 252`
- Line 6: `relativeIndex = (100 * 6 / 6).round() = 100` → `index = 500` → `x = 291` (right) ✅

---

### 7. Price Label Distribution

#### Calculate Label Prices
```dart
for (int i = 0; i <= labelCount; i++) {
  price = scale.max - ((scale.max - scale.min) * i / labelCount)
  y = mapper.priceToY(price)
}
```

**Example** (5 labels, scale 100-200):
- `scale.min = 100`, `scale.max = 200`
- Label 0: `price = 200 - ((200-100) * 0 / 5) = 200` (max, top)
- Label 1: `price = 200 - ((200-100) * 1 / 5) = 180` (80%)
- Label 2: `price = 200 - ((200-100) * 2 / 5) = 160` (60%)
- Label 3: `price = 200 - ((200-100) * 3 / 5) = 140` (40%)
- Label 4: `price = 200 - ((200-100) * 4 / 5) = 120` (20%)
- Label 5: `price = 200 - ((200-100) * 5 / 5) = 100` (min, bottom) ✅

---

## Common Patterns

### Check if Candle is Visible
```dart
bool isVisible = index >= viewport.startIndex && index < viewport.endIndex
```

### Get Candle Center X
```dart
x = mapper.indexToX(index) + (mapper.candleWidth / 2)
// Or use helper:
x = mapper.getCandleCenterX(index)
```

### Check if Price is in Visible Range
```dart
bool isVisible = price >= priceScale.min && price <= priceScale.max
```

### Calculate Percentage Change
```dart
changePercent = ((close - open) / open) * 100
// Example: open=100, close=105 → ((105-100)/100)*100 = 5.0%
```

---

## Performance Tips

1. **Viewport**: Always use viewport to limit visible candles
   - Never render more candles than screen pixels
   - Example: 400px width → max 400 candles (1px per candle)

2. **Cache PriceScale**: PriceScale is cached in ChartEngine
   - Only recalculates when viewport or candles change
   - Access via `engine.getPriceScale()` (not `PriceScale.fromCandles()`)

3. **CoordinateMapper**: Created once per paint, reused for all calculations
   - Don't create multiple mappers
   - Use single mapper for all coordinate conversions

4. **Stateless Painter**: ChartPainter has no state
   - All calculations done before paint()
   - Painter only maps coordinates and draws

---

This quick reference provides instant access to all common calculations in the imp_chart library.

