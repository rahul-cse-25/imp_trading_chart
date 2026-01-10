/// imp_trading_chart
///
/// High-performance trading chart for Flutter.
/// Engine-driven, CustomPainter-based, TradingView-style rendering.
///
/// This file defines the **public API surface** of the package.
/// Everything else lives in `src/` and is considered internal.
library;

/// ─────────────────────────────────────────────────────────
/// DATA (safe to expose)
/// ─────────────────────────────────────────────────────────

export 'src/data/candle.dart';

/// ─────────────────────────────────────────────────────────
/// STYLING & LAYOUT (configuration only, no logic)
/// ─────────────────────────────────────────────────────────

export 'src/theme/chart_style.dart';
export 'src/theme/label_styles.dart';
export 'src/layout/chart_layout.dart';

/// ─────────────────────────────────────────────────────────
/// WIDGETS (Flutter-facing API)
/// ─────────────────────────────────────────────────────────

export 'src/widgets/imp_chart.dart';
