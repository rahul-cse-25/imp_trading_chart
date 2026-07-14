# imp_trading_chart_example

A comprehensive Flutter example application demonstrating the full capabilities of **imp_trading_chart**, including real-time simulations, multiple chart styles, and professional trading-grade UI patterns.

This project is designed to showcase **best practices**, **factory-based APIs**, and **high-performance chart rendering** for financial and trading applications.

---

## ✨ Features

- 📈 **Multiple Chart Styles**
    - Trading (full-featured)
    - Simple
    - Compact
    - Minimal (sparkline style)

- ⚡ **Live Price Simulation**
    - Low price range (micro values)
    - Medium range (up to $100K)
    - High range (up to $1B)
    - Mixed mode (dynamic range switching)

- 🎯 **Real-Time Candle Updates**
    - Proper OHLC candle updates
    - High/Low tracking per tick
    - Time-aligned candle generation

- 🎛️ **Controller Lab**
    - External `ImpChartController` usage
    - Programmatic pan, zoom, fit-all, reset, and scroll-to-latest
    - Manual and live update actions to verify controller behavior

- 🧭 **Interactive Trading Tools**
    - Crosshair with price & time labels
    - Current price indicator
    - Responsive label formatting

- 🎨 **Modern UI**
    - Dark trading theme
    - Tab-based chart switching
    - Stats bar with live indicators
    - Dashboard-ready components

---

## 🧠 Purpose of This Example

This example is built to:

- Demonstrate **all factory constructors** of `ImpChart`
- Demonstrate **controller-centered integrations**
- Showcase **realistic trading data behavior**
- Provide a **ready reference** for:
    - Live charts
    - Dashboard charts
    - Mobile trading apps
- Serve as a **learning resource** for developers integrating trading charts into Flutter apps

---

## 📊 Chart Types Explained

| Chart Type | Description |
|-----------|------------|
| **Trading** | Full-featured chart with crosshair, labels, ripple & indicators |
| **Simple** | Clean chart with labels and minimal interaction |
| **Compact** | Optimized for dashboards and small widgets |
| **Minimal** | Ultra-lightweight sparkline-style chart |

---

## ▶️ Running the Example

### Prerequisites

- Flutter SDK (stable channel)
- Dart 3.x
- Android Studio / VS Code / Xcode

### Steps

```bash
flutter pub get
flutter run
```

---

## 🧪 Simulation Modes

| Mode | Description |
|-----|-------------|
| **Low** | Extremely small values (micro prices, scientific or crypto data) |
| **Medium** | Standard market prices |
| **High** | Institutional-scale prices (up to billions) |
| **Mixed** | Adaptive volatility across all ranges |

Each mode supports **live updates** with correct OHLC candle behavior.

---

## 🏗 Architecture Highlights

- Factory-based chart creation
- Immutable candle data model
- Efficient state updates
- Integer timestamp rendering (no DateTime in render pipeline)
- Pluggable price & time formatters
- Fully customizable styles and layouts

---

## 📦 Related Package

This example depends on:

- **imp_trading_chart**  
  A high-performance, customizable trading chart engine for Flutter.

---

## 📌 Use Cases

- Trading applications
- Crypto exchanges
- Stock market dashboards
- Financial analytics tools
- Portfolio tracking apps

---

## 🤝 Contributing

This project is intended as an **example showcase**.

You are welcome to:
- Fork it
- Experiment with simulations
- Adapt it for your own trading or analytics applications

---

## 📄 License

This example follows the same license as the **imp_trading_chart** package.

---

## 🚀 Final Note

This example is intentionally **realistic**, **scalable**, and **production-oriented** — not just a visual demo.

If you are building a serious trading or finance app in Flutter, this example reflects **how it should be done**.
