# imp_trading_chart

<p align="center">
  <img src="screenshots/pub/professional_crop.jpg" height="360"/>
  <img src="screenshots/real.jpg" height="360"/>
</p>

<p align="center">
  <b>A controller-driven trading line chart for Flutter</b><br/>
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

`imp_trading_chart` is a **rendering-first trading line chart** for Flutter.

It is **not a widget-heavy chart**, but a **CustomPainter + viewport-driven engine**
designed for **performance, precision, and scalability**.

Built specifically for:

* 📈 Financial & stock market apps
* 💹 Crypto & trading platforms
* ⚡ Real-time price feeds
* 🧠 Viewport-limited rendering for large datasets

---

## Quick Start

```dart
import 'package:imp_trading_chart/imp_trading_chart.dart';

ImpChart.trading(candles: candles);

// Inspect by holding without allowing drag or zoom.
ImpChart.trading(
  candles: candles,
  gestureMode: ChartGestureMode.holdOnly,
);
```

The current renderer draws a line through each candle's **close** price. The
`Candle` model also carries OHLC and optional volume values; candle bodies and
volume panels are planned for a later release.

### Gesture Modes

| Mode | Pan | Pinch | Double tap reset | Hold crosshair |
| --- | --- | --- | --- | --- |
| `mixed` | Yes | Yes | Yes | Yes |
| `navigation` | Yes | Yes | Yes | No |
| `holdOnly` | No | No | No | Yes |
| `panOnly` | Yes | No | No | No |
| `zoomOnly` | No | Yes | No | No |
| `none` | No | No | No | No |

`trading` defaults to `mixed`; `simple` and `compact` default to `navigation`;
`minimal` stays non-interactive unless given a mode or overrides. Existing
`enableGestures: false` always disables chart gestures. To change one action:

```dart
ImpChart.trading(
  candles: candles,
  gestureOverrides: const ChartGestureOverrides(
    pinchZoom: false,
    doubleTapReset: false,
  ),
);
```

Gesture modes are per widget. Charts may share one controller yet use different
modes. Modes do not change programmatic controller commands or live following.
The Go to live button remains tappable when a chart is in `none` or `holdOnly`.

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
  <img src="screenshots/cyber.jpg" width="150"/>
  <img src="screenshots/glass.jpg" width="150"/>
  <img src="screenshots/aurora.jpg" width="150"/>
  <img src="screenshots/sunset.jpg" width="150"/>
  <img src="screenshots/professional.jpg" width="150"/>
</p>

<p align="center">
  <img src="screenshots/sim_trade.jpg" width="200"/>
  <img src="screenshots/sim_simple.jpg" width="200"/>
  <img src="screenshots/sim_compact.jpg" width="200"/>
  <img src="screenshots/sim_minimal.jpg" width="200"/>
</p>

| Variant | Use Case                         |
| ------- | -------------------------------- |
| Trading | Interactive close-price line chart |
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
Pan and zoom update a bounded viewport; rendering processes the visible slice.
The reproducible 10k-candle comparison benchmark is in `test/benchmark/`.

---

## 📦 Installation

```yaml
dependencies:
  imp_trading_chart: ^0.2.1
```

---

## 🚀 Basic Usage

```dart
ImpChart.trading(
  candles: candles
);
```

### Controller Usage

```dart
final controller = ImpChartController(
  defaultVisibleCount: 120,
);

ImpChart.trading(
  candles: candles,
  controller: controller,
);

controller.scrollToLatest();
controller.zoomIn();
```

### Live Update UX

`imp_trading_chart` now uses a preserve-context live-update policy:

- If the chart is at or near the latest candles, it keeps following live data.
- If the user pans into older history, incoming candles update the data without force-scrolling.
- If new candles arrive while detached, the chart shows a `Go to live (+count)` action that scrolls back to the latest candles on tap.
- Calling `scrollToLatest()` or resetting the viewport restores follow-latest behavior.

The internal near-latest threshold is currently `3` candles.

### Architecture Highlights

- `ImpChart` stays easy to use and keeps the controller optional.
- `ImpChartController` is the public orchestration API for pan, zoom, reset, fit-all, scroll-to-latest, and live updates.
- `ChartPainter` is now a rendering shell that delegates to focused internal renderers for line, grid, axis labels, current price, ripple, and crosshair drawing.
- Widget-only mechanics are split into focused internal helpers for pulse animation, gesture translation, and live-update affordances.
- `PaddingResolver` owns axis/current-price layout spacing so renderers stay drawing-focused.

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
  * `ImpChartController`
  * `ChartGestureMode` and `ChartGestureOverrides`
  * Controller snapshots and `ChartEvent`
* `Candle`
* `ChartStyle`
* `ChartLayout`
* `LabelStyles`

---

## 🚧 Roadmap

* Indicator overlays (MA, EMA, VWAP)
* Additional theme presets
* Extended visual regression coverage

---

## 🤝 Contributing

We welcome contributions! Please see our [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to get started, project structure, and our [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

For a deep dive into the engine's internals, check out [ARCHITECTURE.md](ARCHITECTURE.md).

## 📌 Stability & Versioning

This project follows [Semantic Versioning (semver)](https://semver.org/).

- **v0.x.x**: Public API is considered stable but minor breaking changes may occur in minor versions while we approach 1.0.
- **Internal APIs**: Everything under `lib/src/` is considered internal and is not part of the stable public API. Use with caution.

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
