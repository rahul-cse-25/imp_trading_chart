# ImpChart Library - Complete Documentation

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Data Models](#data-models)
3. [Engine Layer](#engine-layer)
4. [Rendering Layer](#rendering-layer)
5. [Widget Layer](#widget-layer)
6. [Coordinate System](#coordinate-system)
7. [Layout System](#layout-system)
8. [Example Calculations](#example-calculations)

---

## Architecture Overview

### Data Flow
```
List<Candle> (Data)
    ↓
ChartEngine (Viewport + PriceScale calculation)
    ↓
CoordinateMapper (Index/Price → X/Y coordinates)
    ↓
ChartPainter (Canvas drawing)
    ↓
ImpChart Widget (State management + Gestures)
```

### Key Principles
1. **Viewport-based rendering**: Only visible candles are rendered (performance)
2. **Index-based X positioning**: No DateTime math in rendering
3. **Cached calculations**: PriceScale calculated once, reused
4. **Stateless painter**: No state mutations in paint()
5. **Immutable engine**: All updates create new instances

---

## Data Models

### Candle (`models/candle.dart`)

**Purpose**: Represents OHLC (Open, High, Low, Close) price data at a specific time.

**Fields**:
- `time`: Unix timestamp (seconds or milliseconds) - **WHY**: Avoids DateTime overhead in rendering
- `open`, `high`, `low`, `close`: Price values - **WHY**: Standard OHLC format

**Key Methods**:

#### `updateWithTick(double price)`
**Purpose**: Updates candle with new price tick for live updates.

**Logic**:
```dart
high: price > high ? price : high,  // WHY: Track maximum price
low: price < low ? price : low,     // WHY: Track minimum price
close: price,                         // WHY: Latest price is close
```

**Example**:
- Initial: `Candle(open: 100, high: 105, low: 98, close: 102)`
- Tick: `price = 107`
- Result: `Candle(open: 100, high: 107, low: 98, close: 107)`
- **Calculation**: `high = max(105, 107) = 107`, `low = min(98, 107) = 98`

#### `isBullish` getter
**Purpose**: Determines if candle represents price increase.

**Formula**: `close >= open`
- **Example**: `open=100, close=105` → `isBullish = true`
- **Example**: `open=100, close=95` → `isBullish = false`

#### `changePercent` getter
**Purpose**: Calculates percentage price change.

**Formula**: `((close - open) / open) * 100`
- **Example**: `open=100, close=105` → `((105-100)/100)*100 = 5.0%`
- **Example**: `open=100, close=95` → `((95-100)/100)*100 = -5.0%`

---

### ChartViewport (`models/chart_viewport.dart`)

**Purpose**: Controls which candles are visible on screen (CRITICAL for performance).

**Fields**:
- `startIndex`: First visible candle index (0-based)
- `visibleCount`: Number of candles to show
- `totalCount`: Total candles in dataset

**Why This Exists**: 
- Prevents rendering more candles than screen pixels
- Example: 1000 candles, 400px width → only render 100 visible candles

#### Factory: `ChartViewport.last(int visibleCount, int totalCount)`
**Purpose**: Show last N candles (right-aligned, default behavior).

**Calculation**:
```dart
start = (totalCount - visibleCount).clamp(0, totalCount)
```

**Example**:
- `totalCount = 500`, `visibleCount = 100`
- `start = (500 - 100).clamp(0, 500) = 400`
- Result: Shows candles [400, 500) = last 100 candles

**Why clamp**: Prevents negative start or exceeding total count.

#### Method: `pan(int delta)`
**Purpose**: Pan viewport left/right.

**Calculation**:
```dart
newStart = (startIndex + delta).clamp(0, (totalCount - visibleCount).clamp(0, totalCount))
```

**Example**:
- Current: `startIndex=400, visibleCount=100, totalCount=500`
- Pan right: `delta = -10` (negative = scroll right)
- `newStart = (400 + (-10)).clamp(0, 400) = 390`
- Result: Shows candles [390, 490) - scrolled 10 candles right

**Why negative delta for right**: Natural scrolling (drag right = show older data = lower index).

#### Method: `zoom(int delta, {minVisible=5, maxVisible=1000})`
**Purpose**: Zoom in/out by changing visible count.

**Calculation**:
```dart
newVisible = (visibleCount + delta).clamp(minVisible, maxVisible.clamp(minVisible, totalCount))
newStart = startIndex.clamp(0, maxStart)
```

**Example**:
- Current: `startIndex=400, visibleCount=100, totalCount=500`
- Zoom in: `delta = -10` (negative = zoom in = fewer candles)
- `newVisible = (100 + (-10)).clamp(5, 1000) = 90`
- `maxStart = (500 - 90) = 410`
- `newStart = 400.clamp(0, 410) = 400`
- Result: Shows 90 candles starting at 400

**Why clamp start**: Prevents showing beyond total count.

#### Method: `zoomAround(int anchorIndex, int delta, ...)`
**Purpose**: Zoom around a specific candle (keeps it at same screen position).

**Calculation**:
```dart
ratio = (anchorIndex - startIndex) / visibleCount  // Position ratio (0.0 to 1.0)
newStart = (anchorIndex - (newVisible * ratio).round()).clamp(0, maxStart)
```

**Example**:
- Current: `startIndex=400, visibleCount=100, totalCount=500`
- Anchor: `anchorIndex = 450` (middle of viewport)
- Zoom in: `delta = -20` → `newVisible = 80`
- `ratio = (450 - 400) / 100 = 0.5` (50% from start)
- `newStart = (450 - (80 * 0.5)).round() = 410`
- Result: Candle 450 stays at 50% position, now shows 80 candles

**Why this formula**: Maintains visual anchor point during zoom.

---

### PriceScale (`models/price_scale.dart`)

**Purpose**: Maps price values to Y coordinates (calculated ONCE, cached).

**Fields**:
- `min`: Minimum price (with padding)
- `max`: Maximum price (with padding)
- `range`: `max - min` (computed)

#### Factory: `PriceScale.fromCandles(List<Candle> candles, {paddingPercent=0.05})`
**Purpose**: Calculate price range from visible candles with padding.

**Calculation Steps**:
1. Find min/max from all candles:
   ```dart
   minPrice = min(all candle.low)
   maxPrice = max(all candle.high)
   ```

2. Add padding:
   ```dart
   priceRange = maxPrice - minPrice
   padding = priceRange * paddingPercent
   min = minPrice - padding
   max = maxPrice + padding
   ```

**Example**:
- Candles: `[low: 100, high: 110], [low: 105, high: 120], [low: 115, high: 125]`
- `minPrice = 100`, `maxPrice = 125`
- `priceRange = 125 - 100 = 25`
- `padding = 25 * 0.05 = 1.25`
- `min = 100 - 1.25 = 98.75`
- `max = 125 + 1.25 = 126.25`
- **Result**: PriceScale(min: 98.75, max: 126.25, range: 27.5)

**Why padding**: Prevents candles from touching chart edges.

#### Method: `priceToY(double price, double chartHeight)`
**Purpose**: Convert price to Y coordinate (inverted: max price = top).

**Formula**:
```dart
normalized = (price - min) / range  // 0.0 (min) to 1.0 (max)
y = chartHeight * (1.0 - normalized)  // Inverted: 0.0 (max) to chartHeight (min)
```

**Example**:
- `PriceScale(min: 100, max: 200, range: 100)`
- `chartHeight = 400`
- Price `150` (middle):
  - `normalized = (150 - 100) / 100 = 0.5`
  - `y = 400 * (1.0 - 0.5) = 200` (middle of chart)
- Price `200` (max):
  - `normalized = (200 - 100) / 100 = 1.0`
  - `y = 400 * (1.0 - 1.0) = 0` (top)
- Price `100` (min):
  - `normalized = (100 - 100) / 100 = 0.0`
  - `y = 400 * (1.0 - 0.0) = 400` (bottom)

**Why inverted**: Financial charts show high prices at top (standard convention).

#### Method: `yToPrice(double y, double chartHeight)`
**Purpose**: Convert Y coordinate back to price (reverse of priceToY).

**Formula**:
```dart
normalized = 1.0 - (y / chartHeight)  // Invert: 0.0 (top) to 1.0 (bottom)
price = min + (normalized * range)
```

**Example**:
- `PriceScale(min: 100, max: 200, range: 100)`
- `chartHeight = 400`
- Y `200` (middle):
  - `normalized = 1.0 - (200 / 400) = 0.5`
  - `price = 100 + (0.5 * 100) = 150`
- Y `0` (top):
  - `normalized = 1.0 - (0 / 400) = 1.0`
  - `price = 100 + (1.0 * 100) = 200` (max)

---

### ChartLayout (`models/chart_layout.dart`)

**Purpose**;itioning in the chart.

**Layout Structure**:
```
┌─────────────────────────────────────────────┐
│ Chart Container (Full Widget Size)          │
│  ┌─────────────────────────────────────┐   │
│  │ chartDataPadding.top (10px)         │   │
│  │  ┌───────────────────────────────┐  │   │
│  │  │                               │  │   │
│  │  │  Chart Content Area            │  │   │
│  │  │  (Grid, Line, Ripple)          │  │   │
│  │  │                               │  │   │
│  │  │  chartDataPadding.left (10px) │  │   │
│  │  └───────────────────────────────┘  │   │
│  │ chartDataPadding.bottom (10px)      │   │
│  └─────────────────────────────────────┘   │
│  xAxisGap (8px)                             │
│  ┌─────────────────────────────────────┐   │
│  │ xAxisLabelPadding (vertical: 10px)  │   │
│  │ Time Labels                          │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  chartDataPadding.right (10px)              │
│  yAxisGap (8px)                             │
│  ┌─────────────────────────────────────┐   │
│  │ yAxisLabelPadding (left: 25px)       │   │
│  │ Price Labels                         │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

**Key Parameters**:

#### `chartDataPadding: EdgeInsets.all(10.0)`
**Purpose**: Padding around chart drawing area (grid/line).

**Why**: Creates space so data doesn't touch edges.

**Example Calculation**:
- Widget size: `400x300`
- `chartDataPadding = EdgeInsets.all(10)`
- Content area: `width = 400 - 10 - 10 = 380`, `height = 300 - 10 - 10 = 280`

#### `yAxisGap: 8.0`
**Purpose**: Gap between chart right edge and Y-axis labels.

**Why**: Visual separation between chart and labels.

**Example Calculation**:
- Chart right edge: `paddingLeft + contentWidth = 10 + 380 = 390`
- Label start: `390 + 8 = 398`

#### `yAxisLabelPadding: EdgeInsets.only(left: 25)`
**Purpose**: Padding around individual price labels.

**Why**: Prevents label text from touching chart edge.

**Example Calculation**:
- Label text X: `chartRight + yAxisGap + padding.left = 390 + 8 + 25 = 423`

#### `gridToLabelGapY: 4.0`
**Purpose**: Gap between grid line end and label text start.

**Why**: Creates visual connection (TradingView style).

**Example Calculation**:
- Grid end X: `textStartX - gridToLabelGapY = 423 - 4 = 419`
- **Result**: Grid extends to 419px, label text starts at 423px (4px gap)

---

## Engine Layer

### ChartEngine (`engine/chart_engine.dart`)

**Purpose**: Core logic layer - manages viewport, scaling, coordinate mapping (NO rendering).

**Key Fields**:
- `_candles`: Immutable list of all candles
- `_viewport`: Current viewport (which candles visible)
- `_cachedScale`: Cached PriceScale (performance optimization)
- `_scaleVersion`: Version counter for cache invalidation

**Why Immutable**: Prevents state mutations, enables efficient caching.

#### Method: `getVisibleCandles()`
**Purpose**: Get only candles visible in current viewport.

**Calculation**:
```dart
range = viewport.visibleRange  // [startIndex, endIndex)
return candles.sublist(range.start, range.end)
```

**Example**:
- `candles.length = 500`
- `viewport = ChartViewport(startIndex: 400, visibleCount: 100, totalCount: 500)`
- `range.start = 400`, `range.end = 500`
- **Result**: Returns `candles[400..500)` = 100 candles

**Why**: Only render visible candles (performance).

#### Method: `getPriceScale({paddingPercent=0.05})`
**Purpose**: Calculate price scale for visible candles (CACHED).

**Caching Logic**:
```dart
if (_cachedScale != null && _cachedScaleVersion == _scaleVersion) {
  return _cachedScale!;  // Return cached (FAST)
}
// Recalculate (SLOW, only when needed)
_cachedScale = PriceScale.fromCandles(visibleCandles, paddingPercent: paddingPercent)
```

**Why Cache**: PriceScale calculation is expensive (iterates all visible candles).

**Cache Invalidation**:
- When viewport changes: `_scaleVersion++` (invalidates cache)
- When candles change: `_cachedScaleVersion = _scaleVersion + 1` (invalidates cache)

**Example**:
1. First call: Cache miss → Calculate → Cache result
2. Second call (same viewport): Cache hit → Return cached (FAST)
3. Viewport changes: `_scaleVersion++` → Cache invalidated
4. Third call: Cache miss → Recalculate → Cache new result

#### Method: `createMapper({chartWidth, chartHeight, paddingLeft, ...})`
**Purpose**: Create CoordinateMapper for rendering.

**Calculation**:
```dart
scale = getPriceScale(paddingPercent: paddingPercent)  // Get cached or calculate
return CoordinateMapper(
  viewport: _viewport,
  priceScale: scale,
  chartWidth: chartWidth,
  chartHeight: chartHeight,
  paddingLeft: paddingLeft,
  ...
)
```

**Example**:
- `chartWidth = 400`, `chartHeight = 300`
- `paddingLeft = 10`, `paddingRight = 80`, `paddingTop = 10`, `paddingBottom = 40`
- `viewport = ChartViewport(startIndex: 400, visibleCount: 100, totalCount: 500)`
- `priceScale = PriceScale(min: 100, max: 200, range: 100)`
- **Result**: CoordinateMapper with all mapping functions ready

---

## Coordinate System

### CoordinateMapper (`utils/coordinate_mapper.dart`)

**Purpose**: Maps data coordinates (index, price) to screen coordinates (X, Y).

**Key Properties**:
- `contentWidth = chartWidth - paddingLeft - paddingRight`
- `contentHeight = chartHeight - paddingTop - paddingBottom`

**Why Separate**: Content area excludes padding (where data is drawn).

#### Method: `indexToX(int index)`
**Purpose**: Convert candle index to X coordinate.

**Formula**:
```dart
relativeIndex = index - viewport.startIndex  // Index relative to viewport start
normalizedX = relativeIndex / viewport.visibleCount  // 0.0 to 1.0
x = (normalizedX * contentWidth) + paddingLeft
```

**Example**:
- `viewport.startIndex = 400`, `viewport.visibleCount = 100`
- `contentWidth = 380`, `paddingLeft = 10`
- Index `450` (middle of viewport):
  - `relativeIndex = 450 - 400 = 50`
  - `normalizedX = 50 / 100 = 0.5`
  - `x = (0.5 * 380) + 10 = 200` (middle of chart)
- Index `400` (first visible):
  - `relativeIndex = 400 - 400 = 0`
  - `normalizedX = 0 / 100 = 0.0`
  - `x = (0.0 * 380) + 10 = 10` (left edge)
- Index `499` (last visible):
  - `relativeIndex = 499 - 400 = 99`
  - `normalizedX = 99 / 100 = 0.99`
  - `x = (0.99 * 380) + 10 = 386.2` (near right edge)

**Why This Formula**: Evenly distributes candles across content width.

#### Method: `xToIndex(double x)`
**Purpose**: Convert X coordinate back to candle index (for gestures).

**Formula**:
```dart
relativeX = x - paddingLeft  // Remove padding offset
if (relativeX < 0 || relativeX > contentWidth) return -1  // Outside chart
normalizedX = relativeX / contentWidth  // 0.0 to 1.0
relativeIndex = (normalizedX * visibleCount).round()  // Round to nearest candle
index = viewport.startIndex + relativeIndex
```

**Example**:
- `viewport.startIndex = 400`, `viewport.visibleCount = 100`
- `contentWidth = 380`, `paddingLeft = 10`
- X `200` (middle):
  - `relativeX = 200 - 10 = 190`
  - `normalizedX = 190 / 380 = 0.5`
  - `relativeIndex = (0.5 * 100).round() = 50`
  - `index = 400 + 50 = 450`
- X `10` (left edge):
  - `relativeX = 10 - 10 = 0`
  - `normalizedX = 0 / 380 = 0.0`
  - `relativeIndex = (0.0 * 100).round() = 0`
  - `index = 400 + 0 = 400`

**Why Round**: Maps continuous X coordinate to discrete candle index.

#### Method: `priceToY(double price)`
**Purpose**: Convert price to Y coordinate (includes padding offset).

**Formula**:
```dart
y = priceScale.priceToY(price, contentHeight)  // Y in content area (0 to contentHeight)
return y + paddingTop  // Add padding offset
```

**Example**:
- `priceScale = PriceScale(min: 100, max: 200, range: 100)`
- `contentHeight = 280`, `paddingTop = 10`
- Price `150` (middle):
  - `y_in_content = 280 * (1.0 - 0.5) = 140`
  - `y = 140 + 10 = 150` (middle of chart including padding)
- Price `200` (max):
  - `y_in_content = 280 * (1.0 - 1.0) = 0`
  - `y = 0 + 10 = 10` (top including padding)

**Why Add Padding**: Screen coordinates include padding area.

#### Property: `candleWidth`
**Purpose**: Calculate width of each candle based on visible count.

**Formula**: `contentWidth / viewport.visibleCount`

**Example**:
- `contentWidth = 380`, `viewport.visibleCount = 100`
- `candleWidth = 380 / 100 = 3.8` pixels per candle

**Why**: Even spacing of candles across content width.

---

## Rendering Layer

### ChartPainter (`renderer/chart_painter.dart`)

**Purpose**: Stateless CustomPainter that draws chart on Canvas.

**Key Principle**: NO calculations, NO state mutations - only coordinate mapping and drawing.

#### Method: `paint(Canvas canvas, Size size)`
**Purpose**: Main paint method (called by Flutter framework).

**Drawing Order** (CRITICAL):
1. **Clip to content area** (line 50)
   - **Why**: Prevents line chart from drawing outside bounds
   - **Rect**: `(paddingLeft, paddingTop, contentWidth, contentHeight)`

2. **Draw line chart** (inside clip)
   - **Why**: Line must stay within content area

3. **Restore canvas** (remove clip)
   - **Why**: Grid and labels need to draw outside content area

4. **Draw grid** (outside clip)
   - **Why**: Grid extends toward labels (TradingView style)

5. **Draw labels** (outside clip)
   - **Why**: Labels are positioned outside content area

**Why This Order**: Clipping prevents overlap, then grid/labels extend properly.

#### Method: `_drawGrid(Canvas canvas, Size size)`
**Purpose**: Draw grid lines extending toward labels.

**Key Calculation** (lines 122-156):

**Horizontal Lines (Y-axis labels)**:
```dart
textStartX = chartRight + yAxisGap + yAxisLabelPadding.left
horizontalLineEndX = textStartX - gridToLabelGapY
```

**Example**:
- `chartRight = 390` (paddingLeft + contentWidth = 10 + 380)
- `yAxisGap = 8`
- `yAxisLabelPadding.left = 25`
- `gridToLabelGapY = 4`
- `textStartX = 390 + 8 + 25 = 423`
- `horizontalLineEndX = 423 - 4 = 419`
- **Result**: All horizontal lines extend to X=419, labels start at X=423 (4px gap)

**Why Calculate Once**: All horizontal lines end at same X (symmetry).

**Vertical Lines (X-axis labels)**:
```dart
textStartY = chartBottom + xAxisGap + xAxisLabelPadding.top
verticalLineEndY = textStartY - gridToLabelGapX
```

**Example**:
- `chartBottom = 290` (paddingTop + contentHeight = 10 + 280)
- `xAxisGap = 8`
- `xAxisLabelPadding.top = 10`
- `gridToLabelGapX = 4`
- `textStartY = 290 + 8 + 10 = 308`
- `verticalLineEndY = 308 - 4 = 304`
- **Result**: All vertical lines extend to Y=304, labels start at Y=308 (4px gap)

**Grid Line Drawing** (lines 162-174):
```dart
for (int i = 0; i <= horizontalLines; i++) {
  y = chartTop + (contentHeight * i / horizontalLines)  // Evenly spaced
  drawLine(Offset(chartLeft, y), Offset(clampedHorizontalEndX, y))  // Same Y = horizontal
}
```

**Example** (5 horizontal lines):
- `chartTop = 10`, `contentHeight = 280`, `horizontalLines = 5`
- Line 0: `y = 10 + (280 * 0 / 5) = 10` (top)
- Line 1: `y = 10 + (280 * 1 / 5) = 66` (20%)
- Line 2: `y = 10 + (280 * 2 / 5) = 122` (40%)
- Line 3: `y = 10 + (280 * 3 / 5) = 178` (60%)
- Line 4: `y = 10 + (280 * 4 / 5) = 234` (80%)
- Line 5: `y = 10 + (280 * 5 / 5) = 290` (bottom)
- **All lines extend to X=419** (same end position = symmetry)

#### Method: `_drawLineChart(Canvas canvas)`
**Purpose**: Draw the main price line.

**Process**:
1. Create Path
2. For each candle:
   - `x = mapper.getCandleCenterX(index)` (center of candle)
   - `y = mapper.priceToY(candle.close)` (price to Y coordinate)
   - Add point to path
3. Draw path with Paint

**Example**:
- Candle at index 450, close price 150
- `x = mapper.getCandleCenterX(450) = 200` (middle of chart)
- `y = mapper.priceToY(150) = 150` (middle price)
- **Result**: Point at (200, 150)

**Why Center X**: Line connects candle centers (not edges).

#### Method: `_drawPriceLabels(Canvas canvas, Size size)`
**Purpose**: Draw Y-axis price labels.

**Key Calculation** (line 305):
```dart
labelX = chartRight + yAxisGap + yAxisLabelPadding.left
```

**Example**:
- `chartRight = 390`
- `yAxisGap = 8`
- `yAxisLabelPadding.left = 25`
- `labelX = 390 + 8 + 25 = 423`
- **Result**: All price labels start at X=423

**Label Distribution** (lines 281-282):
```dart
for (int i = 0; i <= labelCount; i++) {
  price = scale.max - ((scale.max - scale.min) * i / labelCount)
  y = mapper.priceToY(price)
}
```

**Example** (5 labels, scale 100-200):
- Label 0: `price = 200 - ((200-100) * 0 / 5) = 200` (max, top)
- Label 1: `price = 200 - ((200-100) * 1 / 5) = 180` (80%)
- Label 2: `price = 200 - ((200-100) * 2 / 5) = 160` (60%)
- Label 3: `price = 200 - ((200-100) * 3 / 5) = 140` (40%)
- Label 4: `price = 200 - ((200-100) * 4 / 5) = 120` (20%)
- Label 5: `price = 200 - ((200-100) * 5 / 5) = 100` (min, bottom)

**Why This Formula**: Evenly distributes labels from max (top) to min (bottom).

---

## Widget Layer

### ImpChart (`widget/imp_chart.dart`)

**Purpose**: StatefulWidget that manages ChartEngine state and handles gestures.

**Key State**:
- `_engine`: ChartEngine instance (immutable, replaced on updates)
- `_pulseProgress`: Animation progress (0.0 to 1.0)
- `_baseScale`: Gesture zoom accumulation
- `_accumulatedPanDelta`: Smooth panning accumulation

#### Method: `_calculatePadding(Size size)`
**Purpose**: Dynamically calculate padding based on label sizes.

**Why Dynamic**: Label widths vary (e.g., "$1.2K" vs "$1,234,567.89").

**Calculation Steps**:

1. **Y-axis Width** (if `showPriceLabels = true`):
   ```dart
   // Measure widest label
   for (each price label) {
     maxLabelWidth = max(maxLabelWidth, textPainter.width)
   }
   baseYAxisWidth = yAxisGap + maxLabelWidth + yAxisLabelPadding.horizontal
   ```

2. **Add Ripple Extension** (if `showRippleAnimation = true`):
   ```dart
   rippleExtension = maxRippleRadius + pointRadius + 3.0
   ```

3. **Add Current Price Label** (if shown):
   ```dart
   currentPriceLabelArea = rippleExtension + currentPriceLabelGap + currentPriceLabelWidth
   yAxisAreaWidth = max(baseYAxisWidth, currentPriceLabelArea)
   ```

**Example**:
- `yAxisGap = 8`
- `maxLabelWidth = 45` (widest price label)
- `yAxisLabelPadding.horizontal = 25`
- `baseYAxisWidth = 8 + 45 + 25 = 78`
- `rippleExtension = 31` (if enabled)
- `currentPriceLabelWidth = 60` (if shown)
- `currentPriceLabelArea = 31 + 4 + 60 = 95`
- `yAxisAreaWidth = max(78, 95) = 95`
- **Result**: `paddingRight = 95` (ensures labels fit)

**Why This Complexity**: Ensures labels never get clipped, accounts for all elements.

#### Method: `_handleScaleUpdate(ScaleUpdateDetails details, Size size)`
**Purpose**: Handle zoom/pan gestures.

**Zoom Detection** (line 412):
```dart
scaleChange = (details.scale - _baseScale).abs()
isZoom = scaleChange > 0.05  // Threshold to avoid false zoom
```

**Why Threshold**: Small scale changes are pan gestures, not zoom.

**Zoom Calculation** (lines 416-434):
```dart
zoomDelta = (details.scale - _baseScale) > 0 ? -1 : 1  // Negative = zoom in
anchorIndex = mapper.xToIndex(details.focalPoint.dx)  // Zoom around touch point
engine.zoomAround(anchorIndex, zoomDelta)
```

**Example**:
- Touch at X=200, scale increases from 1.0 to 1.1
- `anchorIndex = mapper.xToIndex(200) = 450`
- `zoomDelta = -1` (scale increased = zoom in)
- **Result**: Zoom in around candle 450 (keeps it at same screen position)

**Pan Calculation** (lines 442-456):
```dart
delta = _lastPanPosition.dx - details.focalPoint.dx  // Inverted for natural scroll
_accumulatedPanDelta += delta
candleDelta = (_accumulatedPanDelta / candleWidth).round()
if (candleDelta.abs() >= 1) {
  engine.pan(candleDelta)
  _accumulatedPanDelta -= (candleDelta * candleWidth)  // Keep remainder
}
```

**Example**:
- `candleWidth = 3.8`
- Pan 5px right: `delta = -5` (inverted), `accumulated = -5`
- `candleDelta = (-5 / 3.8).round() = -1`
- **Result**: Pan 1 candle left (shows older data)

**Why Accumulate**: Smooth panning (small movements accumulate before updating).

---

## Example Calculations

### Complete Example: 1000 Candles, 400x300 Widget

**Initial State**:
- `candles.length = 1000`
- Widget size: `400x300`
- Default viewport: Last 100 candles

**Step 1: Viewport Creation**:
```dart
viewport = ChartViewport.last(100, 1000)
// startIndex = (1000 - 100).clamp(0, 1000) = 900
// visibleCount = 100
// Result: Shows candles [900, 1000)
```

**Step 2: Price Scale Calculation**:
```dart
visibleCandles = candles[900..1000]  // 100 candles
minPrice = min(all candle.low) = 100
maxPrice = max(all candle.high) = 200
priceRange = 200 - 100 = 100
padding = 100 * 0.05 = 5
PriceScale(min: 95, max: 205, range: 110)
```

**Step 3: Padding Calculation**:
```dart
chartDataPadding = EdgeInsets.all(10)
// Left: 10, Top: 10

// Y-axis (if labels shown):
maxLabelWidth = 45  // "$205.00"
yAxisGap = 8
yAxisLabelPadding.horizontal = 25
baseYAxisWidth = 8 + 45 + 25 = 78
rippleExtension = 31  // if enabled
yAxisAreaWidth = 78 + 31 = 109
// Right: 109

// X-axis (if labels shown):
labelHeight = 12
xAxisGap = 8
xAxisLabelPadding.vertical = 10
xAxisAreaHeight = 8 + 12 + 10 = 30
// Bottom: 30

// Result: paddingLeft=10, paddingRight=109, paddingTop=10, paddingBottom=30
```

**Step 4: Content Area**:
```dart
contentWidth = 400 - 10 - 109 = 281
contentHeight = 300 - 10 - 30 = 260
```

**Step 5: Coordinate Mapping**:
```dart
// Candle at index 950 (middle of viewport):
x = ((950 - 900) / 100) * 281 + 10 = (0.5 * 281) + 10 = 150.5

// Price 150 (middle of scale):
y = 260 * (1.0 - ((150 - 95) / 110)) + 10
  = 260 * (1.0 - 0.5) + 10
  = 130 + 10 = 140
```

**Step 6: Grid Extension**:
```dart
// Horizontal lines:
chartRight = 10 + 281 = 291
textStartX = 291 + 8 + 25 = 324
horizontalLineEndX = 324 - 4 = 320
// All horizontal lines extend to X=320

// Vertical lines:
chartBottom = 10 + 260 = 270
textStartY = 270 + 8 + 10 = 288
verticalLineEndY = 288 - 4 = 284
// All vertical lines extend to Y=284
```

---

## Summary

### Key Formulas

1. **Index to X**: `x = ((index - startIndex) / visibleCount) * contentWidth + paddingLeft`
2. **Price to Y**: `y = contentHeight * (1.0 - (price - min) / range) + paddingTop`
3. **Grid End X**: `textStartX - gridToLabelGapY` where `textStartX = chartRight + yAxisGap + labelPadding.left`
4. **Grid End Y**: `textStartY - gridToLabelGapX` where `textStartY = chartBottom + xAxisGap + labelPadding.top`
5. **Candle Width**: `contentWidth / visibleCount`
6. **Price Scale**: `min = minPrice - (range * 0.05)`, `max = maxPrice + (range * 0.05)`

### Performance Optimizations

1. **Viewport**: Only render visible candles (never more than screen pixels)
2. **Cached PriceScale**: Calculated once, reused until viewport/candles change
3. **Stateless Painter**: No calculations in paint() - all precomputed
4. **RepaintBoundary**: Isolates chart repaints from parent widget

### Design Decisions

1. **Inverted Y-axis**: High prices at top (financial convention)
2. **Index-based X**: No DateTime math in rendering (performance)
3. **Immutable Engine**: All updates create new instances (predictable state)
4. **Dynamic Padding**: Calculates label space to prevent clipping
5. **Grid Extension**: Extends to labels for visual connection (TradingView style)

---

This documentation covers every aspect of the imp_chart library with detailed explanations, formulas, and examples. Each line of code exists for a specific purpose, and this document explains why.

