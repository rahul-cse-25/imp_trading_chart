# imp_trading_chart

A **high-performance trading chart engine for Flutter**, inspired by
TradingView Lightweight Charts.

`imp_trading_chart` is designed as a **rendering engine**, not a widget tree.
It is optimized for **large datasets**, **real-time updates**, and **smooth
pan & zoom**, while keeping the public API minimal and stable.

---

## ✨ Key Features

- ⚡ CustomPainter-based rendering (no widget candles)
- 📈 Viewport-driven drawing (only visible data is rendered)
- 🧮 Index-based timestamps (no DateTime math in painter)
- 🧠 Cached price scale & coordinate mapping
- 🧩 Clean separation: **Data → Engine → Rendering**
- 🖐 Pan, zoom, double-tap gestures
- 🪟 Multiple chart instances supported
- 🎨 Fully customizable styling & layout
- 🚀 Designed for large datasets (10k+ candles)

---

## 🧠 Design Philosophy

This package intentionally avoids:
- Widget-per-candle rendering
- DateTime calculations in the render loop
- Rebuilding UI for every data change

Instead, it follows a **chart engine architecture**:

```
Data (List<Candle>)
   ↓
Chart Engine (viewport, scaling, mapping)
   ↓
Rendering Layer (CustomPainter)
```

---

## 📦 Installation

```yaml
dependencies:
  imp_trading_chart: ^0.1.0
```

---

## 🚀 Basic Usage

```dart
import 'package:imp_trading_chart/imp_chart.dart';

ImpChart(
  candles: candles,
  style: ChartStyle(
    bullishColor: Colors.green,
    bearishColor: Colors.red,
  ),
);
```

---

## 📊 Candle Model

```dart
Candle(
  timestamp: 0,
  open: 100,
  high: 120,
  low: 90,
  close: 110,
  volume: 500,
);
```

> ⚠️ The chart engine does **not** perform time aggregation.
> Data should be prepared before passing to the chart.

---

## 🎨 Styling & Layout

### ChartStyle
```dart
ChartStyle(
  bullishColor: Colors.green,
  bearishColor: Colors.red,
  gridColor: const Color(0xFF2A2A2A),
  backgroundColor: const Color(0xFF0E0E0E),
  wickWidth: 1,
  candleSpacing: 2,
);
```

### ChartLayout
```dart
ChartLayout(
  priceAxisWidth: 60,
  timeAxisHeight: 24,
);
```

---

## 🧪 Example App

A complete runnable example is included in the `example/` folder.

```bash
cd example
flutter run
```

---

## 📚 Documentation

- Quick Reference: [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- Architecture & Internals: [DOCUMENTATION.md](DOCUMENTATION.md)

---

## 🔒 Public API vs Internals

Only the following are part of the **public API**:

- `ImpChart`
- `Candle`
- `ChartStyle`
- `ChartLayout`
- `LabelStyles`

All engine internals are intentionally hidden to allow future optimizations
without breaking users.

---

## 🚧 Roadmap

- Public `ChartController` API

---

## 📄 License

MIT License  
© Rahul Prajapati
