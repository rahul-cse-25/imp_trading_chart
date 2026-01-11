# imp_trading_chart

<p align="center">
  <img src="screenshots/pub/professional_crop.jpg" height="360"/>
  <img src="screenshots/real.jpg" height="360"/>
</p>

<p align="center">
  <b>A high-performance trading chart engine for Flutter</b><br/>
  Inspired by TradingView Lightweight Charts
</p>

<p align="center">
  <a href="https://pub.dev/packages/imp_trading_chart">
    <img src="https://img.shields.io/pub/v/imp_trading_chart.svg">
  </a>
  <a href="https://github.com/rahul-cse-25/imp_trading_chart">
    <img src="https://img.shields.io/github/stars/rahul-cse-25/imp_trading_chart?style=social">
  </a>
</p>

---

## 🚀 Overview

`imp_trading_chart` is a **rendering-first trading chart engine** for Flutter.

It is **not a widget-heavy chart**, but a **CustomPainter + viewport-driven engine**
designed for **performance, precision, and scalability**.

Built specifically for:

* 📈 Financial & stock market apps
* 💹 Crypto & trading platforms
* ⚡ Real-time price feeds
* 🧠 Large datasets (10k+ candles)

---

## ✨ Visual Themes & Styles

<p align="center">
  <img src="screenshots/pub/aurora_crop.jpg" width="220"/>
  <img src="screenshots/pub/cyber_crop.jpg" width="220"/>
  <img src="screenshots/pub/glass_crop.jpg" width="220"/>
</p>

<p align="center">
  <img src="screenshots/pub/sunset_crop.jpg" width="220"/>
  <img src="screenshots/pub/professional_crop.jpg" width="220"/>
</p>

---

## 🎬 Live Interaction Demos

### 🌎 Real App Integration

<p align="center">
  <img src="screenshots/gifs/real_crosshair.gif" width="300"/>
</p>

### ▶️ Full Market Simulation

<p align="center">
  <img src="screenshots/gifs/sim.gif" width="300"/>
</p>

### ✋ Drag / Pan Viewport

<p align="center">
  <img src="screenshots/gifs/point_drag.gif" width="300"/>
</p>

### 🔍 Pinch-to-Zoom

<p align="center">
  <img src="screenshots/gifs/pinch.gif" width="300"/>
</p>

---

## 📊 Chart Variants

<p align="center">
  <img src="screenshots/cyber.jpg" width="200"/>
  <img src="screenshots/glass.jpg" width="200"/>
  <img src="screenshots/aurora.jpg" width="200"/>
  <img src="screenshots/sunset.jpg" width="200"/>
  <img src="screenshots/professional.jpg" width="200"/>
</p>

<p align="center">
  <img src="screenshots/sim_trade.jpg" width="200"/>
  <img src="screenshots/sim_simple.jpg" width="200"/>
  <img src="screenshots/sim_compact.jpg" width="200"/>
  <img src="screenshots/sim_minimal.jpg" width="200"/>
</p>

| Variant | Use Case                         |
| ------- | -------------------------------- |
| Trading | Full-featured professional chart |
| Simple  | Clean chart with labels          |
| Compact | Dashboards & lists               |
| Minimal | Sparklines & previews            |


---

## 🧠 Engine-First Architecture

```
Candle Data (List<Candle>)
        ↓
ChartEngine (viewport, scaling, mapping)
        ↓
CustomPainter (pixels only)
```

### Why this matters

* ❌ No widget-per-candle
* ❌ No DateTime math in render loop
* ❌ No unnecessary rebuilds

✅ Only **visible candles** are processed
✅ Pan & zoom are **O(1)** operations
✅ Perfect for **live trading data**

---

## 📦 Installation

```yaml
dependencies:
  imp_trading_chart: ^0.1.0
```

---

## 🚀 Basic Usage

```dart
ImpChart.trading(
  candles: candles
);
```

---

## 🕯 Candle Model

```dart
Candle(
  time: 1700000000,
  open: 100,
  high: 120,
  low: 90,
  close: 110,
);
```

> ⚠️ The engine does **not** aggregate data.

---

## 🧪 Example App

A complete interactive demo is included in the `example/` folder.

```bash
cd example
flutter run
```

---

## 📚 Documentation

* 📘 Architecture & Internals → [DOCUMENTATION.md](DOCUMENTATION.md)
* ⚡ Quick API Guide → [QUICK_REFERENCE.md](QUICK_REFERENCE.md)

---

## 🔒 Public API Stability

Only these are public & stable:

* `ImpChart`
* `Candle`
* `ChartStyle`
* `ChartLayout`
* `LabelStyles`

---

## 🚧 Roadmap

* Public `ChartController`
* Programmatic zoom / pan API
* Indicator overlays (MA, EMA, VWAP)

---

## 📄 License

MIT License
© Rahul Prajapati
