import 'package:flutter/foundation.dart';

/// Common combinations of touch interactions supported by the chart widget.
///
/// A mode controls user input only. Controller commands and live following are
/// independent of this setting.
enum ChartGestureMode {
  /// Pan, pinch zoom, double-tap reset, and long-press crosshair.
  mixed,

  /// Pan, pinch zoom, and double-tap reset without a crosshair gesture.
  navigation,

  /// Long-press crosshair only.
  holdOnly,

  /// One-finger horizontal panning only.
  panOnly,

  /// Two-finger pinch zoom only.
  zoomOnly,

  /// No chart gestures. A visible Go to live button remains tappable.
  none,
}

/// Optional changes to individual gestures in a [ChartGestureMode].
///
/// A null value inherits the selected mode. Explicit values take precedence
/// over the mode, while `enableGestures: false` disables all four.
@immutable
class ChartGestureOverrides {
  /// Allow one-finger horizontal panning.
  final bool? pan;

  /// Allow two-finger pinch zoom.
  final bool? pinchZoom;

  /// Allow double tap to restore the latest-aligned viewport.
  final bool? doubleTapReset;

  /// Allow long press to inspect a candle with the crosshair.
  final bool? longPressCrosshair;

  /// Creates per-gesture overrides for a chart widget.
  const ChartGestureOverrides({
    this.pan,
    this.pinchZoom,
    this.doubleTapReset,
    this.longPressCrosshair,
  });
}

/// Resolved, widget-local interaction permissions.
@immutable
class ChartGesturePolicy {
  final bool pan;
  final bool pinchZoom;
  final bool doubleTapReset;
  final bool longPressCrosshair;
  final bool crosshairVisible;

  const ChartGesturePolicy._({
    required this.pan,
    required this.pinchZoom,
    required this.doubleTapReset,
    required this.longPressCrosshair,
    required this.crosshairVisible,
  });

  /// Applies preset defaults, explicit configuration, and the legacy switch.
  factory ChartGesturePolicy.resolve({
    required ChartGestureMode defaultMode,
    required ChartGestureMode? mode,
    required ChartGestureOverrides? overrides,
    required bool enableGestures,
    required bool styleShowsCrosshair,
    required bool revealCrosshairForPreset,
  }) {
    final selected = mode ?? defaultMode;
    final base = switch (selected) {
      ChartGestureMode.mixed => (true, true, true, true),
      ChartGestureMode.navigation => (true, true, true, false),
      ChartGestureMode.holdOnly => (false, false, false, true),
      ChartGestureMode.panOnly => (true, false, false, false),
      ChartGestureMode.zoomOnly => (false, true, false, false),
      ChartGestureMode.none => (false, false, false, false),
    };
    final requestedHold = overrides?.longPressCrosshair ?? base.$4;
    final visible = styleShowsCrosshair ||
        (enableGestures &&
            revealCrosshairForPreset &&
            (mode != null || overrides?.longPressCrosshair == true) &&
            requestedHold);

    return ChartGesturePolicy._(
      pan: enableGestures && (overrides?.pan ?? base.$1),
      pinchZoom: enableGestures && (overrides?.pinchZoom ?? base.$2),
      doubleTapReset: enableGestures && (overrides?.doubleTapReset ?? base.$3),
      longPressCrosshair: enableGestures && requestedHold && visible,
      crosshairVisible: visible,
    );
  }
}
