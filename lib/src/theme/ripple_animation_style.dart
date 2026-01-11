import 'package:flutter/material.dart';

// ============================================================================
// RIPPLE ANIMATION STYLE
// ============================================================================

/// Styling for the **ripple / pulse animation** drawn on the latest data point.
///
/// This animation is used to:
/// - Draw attention to the most recent price
/// - Indicate a live / updating market
/// - Improve visual feedback without overwhelming the chart
///
/// Important design notes:
/// - This class is **pure configuration**
/// - All animation timing is handled externally (Ticker / AnimationController)
/// - The painter reads these values every frame
class RippleAnimationStyle {
  /// Whether to show the ripple animation at all.
  ///
  /// When `false`:
  /// - No animation controller is required
  /// - Painter completely skips ripple drawing
  ///
  /// This is important for:
  /// - Performance-sensitive charts
  /// - Historical / static charts
  final bool show;

  /// Base color of the ripple effect.
  ///
  /// This color is used to generate:
  /// - Radial gradients
  /// - Stroke rings
  /// - Glow overlays
  ///
  /// Opacity is dynamically controlled by animation progress.
  final Color color;

  /// Maximum radius the ripple expands to.
  ///
  /// This value is **upper-bounded** by chart layout constraints
  /// at runtime to prevent overflow into labels.
  ///
  /// Larger values:
  /// - Increase visual emphasis
  /// - Require more GPU fill work
  final double maxRadius;

  /// Minimum opacity when the ripple is fully expanded.
  ///
  /// Typically `0.0` so the ripple fades out completely.
  /// Non-zero values create a persistent halo.
  final double minOpacity;

  /// Maximum opacity at the start of the ripple.
  ///
  /// This is the strongest visual moment of the animation.
  /// Usually paired with ease-out curves.
  final double maxOpacity;

  /// Duration of a single ripple expansion animation (milliseconds).
  ///
  /// This controls **how fast** the ripple expands.
  /// Does NOT include idle time between ripples.
  final int animationDurationMs;

  /// Idle interval between ripple cycles (milliseconds).
  ///
  /// Total cycle time:
  /// `animationDurationMs + intervalMs`
  ///
  /// Example:
  /// - animationDurationMs = 2000
  /// - intervalMs = 2000
  /// → One ripple every 4 seconds
  final int intervalMs;

  /// Default constructor with highly visible defaults.
  ///
  /// Defaults are tuned for:
  /// - Dark backgrounds
  /// - Live trading charts
  /// - Clear visibility without being distracting
  const RippleAnimationStyle({
    this.show = true,
    this.color = Colors.white,
    this.maxRadius = 35.0,
    this.minOpacity = 0.0,
    this.maxOpacity = 1.0,
    this.animationDurationMs = 2000,
    this.intervalMs = 2000,
  });

  /// Create a **hidden ripple** (no animation).
  ///
  /// This is preferred over `show: false` in inline configs
  /// for readability and intent clarity.
  factory RippleAnimationStyle.hidden() {
    return const RippleAnimationStyle(show: false);
  }

  /// Create a **subtle ripple** effect.
  ///
  /// Intended for:
  /// - Secondary charts
  /// - Compact layouts
  /// - Reduced visual noise
  factory RippleAnimationStyle.subtle({
    Color color = Colors.white,
  }) {
    return RippleAnimationStyle(
      color: color,
      maxRadius: 16.0,
      maxOpacity: 0.3,
    );
  }

  /// Create a **prominent ripple** effect.
  ///
  /// Intended for:
  /// - Primary trading screens
  /// - Live tickers
  /// - Strong visual emphasis
  factory RippleAnimationStyle.prominent({
    Color color = Colors.white,
  }) {
    return RippleAnimationStyle(
      color: color,
      maxRadius: 32.0,
      maxOpacity: 0.7,
    );
  }

  /// Creates a modified copy while preserving immutability.
  ///
  /// This is heavily used by:
  /// - Theme overrides
  /// - ChartStyle.copyWith
  /// - Runtime animation tuning
  RippleAnimationStyle copyWith({
    bool? show,
    Color? color,
    double? maxRadius,
    double? minOpacity,
    double? maxOpacity,
    int? animationDurationMs,
    int? intervalMs,
  }) {
    return RippleAnimationStyle(
      show: show ?? this.show,
      color: color ?? this.color,
      maxRadius: maxRadius ?? this.maxRadius,
      minOpacity: minOpacity ?? this.minOpacity,
      maxOpacity: maxOpacity ?? this.maxOpacity,
      animationDurationMs: animationDurationMs ?? this.animationDurationMs,
      intervalMs: intervalMs ?? this.intervalMs,
    );
  }

  /// Strict equality is required for repaint correctness.
  ///
  /// Any visual change must trigger a repaint.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RippleAnimationStyle &&
          runtimeType == other.runtimeType &&
          show == other.show &&
          color == other.color &&
          maxRadius == other.maxRadius &&
          minOpacity == other.minOpacity &&
          maxOpacity == other.maxOpacity &&
          animationDurationMs == other.animationDurationMs &&
          intervalMs == other.intervalMs;

  @override
  int get hashCode =>
      show.hashCode ^
      color.hashCode ^
      maxRadius.hashCode ^
      minOpacity.hashCode ^
      maxOpacity.hashCode ^
      animationDurationMs.hashCode ^
      intervalMs.hashCode;
}
