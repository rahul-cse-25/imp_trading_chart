/// imp_trading_chart
///
/// A high-performance trading chart engine for Flutter,
/// inspired by TradingView Lightweight Charts.
///
/// ─────────────────────────────────────────────────────────
/// 📌 PACKAGE PHILOSOPHY
/// ─────────────────────────────────────────────────────────
///
/// This package is designed as a **chart rendering engine**,
/// not as a widget-heavy charting library.
///
/// Core principles:
/// - Engine-first architecture (not widget-first)
/// - CustomPainter + Canvas based rendering
/// - Viewport-driven drawing (only visible data is rendered)
/// - Integer-based timestamps (no DateTime math in render loop)
/// - Clear separation of responsibilities:
///
///   Data → Engine → Rendering → Widget
///
/// ─────────────────────────────────────────────────────────
/// 🔒 PUBLIC API BOUNDARY
/// ─────────────────────────────────────────────────────────
///
/// This file defines the **only supported public API surface**
/// of the package.
///
/// Consumers of this package **must only import**:
///
/// ```dart
/// import 'package:imp_trading_chart/imp_trading_chart.dart';
/// ```
///
/// Everything under `lib/src/` is considered **internal
/// implementation detail** and may change without notice.
///
/// If a class or utility is not exported here, it is:
/// - ❌ Not supported for direct use
/// - ❌ Not guaranteed to remain stable
///
/// This boundary allows the engine internals to evolve
/// without breaking user code.
library;

/// ─────────────────────────────────────────────────────────
/// 📊 DATA MODELS (SAFE TO EXPOSE)
/// ─────────────────────────────────────────────────────────
///
/// Pure, immutable data structures used to feed the chart.
/// These models contain **no rendering or engine logic**.
///
/// Users are expected to prepare and aggregate data
/// before passing it to the chart.
export 'src/data/candle.dart';
export 'src/data/enums.dart';

/// ─────────────────────────────────────────────────────────
/// 🔤 FORMATTERS (PUBLIC EXTENSION POINTS)
/// ─────────────────────────────────────────────────────────
///
/// Formatters are intentionally exposed so that users can:
/// - Use the built-in default implementations
/// - Provide their own custom formatting logic
///
/// These are **pure formatting abstractions** and are
/// safe to customize without affecting engine behavior.
export 'src/formatters/price_formatter.dart';
export 'src/formatters/time_formatter.dart';

/// ─────────────────────────────────────────────────────────
/// 🎨 STYLING & LAYOUT CONFIGURATION
/// ─────────────────────────────────────────────────────────
///
/// Configuration objects that control:
/// - Colors
/// - Label styles
/// - Axis sizes and layout constraints
///
/// These classes are declarative and contain **no engine logic**.
/// They are safe to expose and safe to extend in future versions.
export 'src/theme/theme_export.dart';

/// ─────────────────────────────────────────────────────────
/// 🧩 FLUTTER WIDGET API
/// ─────────────────────────────────────────────────────────
///
/// The primary Flutter-facing widget that wires:
/// - Data
/// - Configuration
/// - Engine
/// - Rendering
///
/// This widget is intentionally kept thin and declarative.
/// All heavy logic lives in the internal engine and renderer.
export 'src/widgets/imp_chart.dart';
