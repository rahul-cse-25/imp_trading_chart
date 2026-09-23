import 'package:flutter_test/flutter_test.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart';
import 'package:imp_trading_chart/src/behavior/chart_gesture_policy.dart'
    show ChartGesturePolicy;

void main() {
  const expected = <ChartGestureMode, List<bool>>{
    ChartGestureMode.mixed: [true, true, true, true],
    ChartGestureMode.navigation: [true, true, true, false],
    ChartGestureMode.holdOnly: [false, false, false, true],
    ChartGestureMode.panOnly: [true, false, false, false],
    ChartGestureMode.zoomOnly: [false, true, false, false],
    ChartGestureMode.none: [false, false, false, false],
  };

  for (final entry in expected.entries) {
    test('${entry.key.name} permits the documented gestures', () {
      final policy = ChartGesturePolicy.resolve(
        defaultMode: ChartGestureMode.none,
        mode: entry.key,
        overrides: null,
        enableGestures: true,
        styleShowsCrosshair: true,
        revealCrosshairForPreset: false,
      );

      expect(
        [
          policy.pan,
          policy.pinchZoom,
          policy.doubleTapReset,
          policy.longPressCrosshair,
        ],
        entry.value,
      );
    });
  }

  test('overrides replace only the named permissions', () {
    final policy = ChartGesturePolicy.resolve(
      defaultMode: ChartGestureMode.none,
      mode: ChartGestureMode.mixed,
      overrides: const ChartGestureOverrides(
        pinchZoom: false,
        doubleTapReset: false,
      ),
      enableGestures: true,
      styleShowsCrosshair: true,
      revealCrosshairForPreset: false,
    );

    expect(policy.pan, isTrue);
    expect(policy.pinchZoom, isFalse);
    expect(policy.doubleTapReset, isFalse);
    expect(policy.longPressCrosshair, isTrue);
  });

  test('legacy hard-off overrides explicit mode and individual settings', () {
    final policy = ChartGesturePolicy.resolve(
      defaultMode: ChartGestureMode.none,
      mode: ChartGestureMode.mixed,
      overrides: const ChartGestureOverrides(pan: true),
      enableGestures: false,
      styleShowsCrosshair: true,
      revealCrosshairForPreset: false,
    );

    expect(policy.pan, isFalse);
    expect(policy.pinchZoom, isFalse);
    expect(policy.doubleTapReset, isFalse);
    expect(policy.longPressCrosshair, isFalse);
  });

  test('explicit hold reveals a preset crosshair but not a custom hidden one',
      () {
    ChartGesturePolicy resolve(bool reveal) => ChartGesturePolicy.resolve(
          defaultMode: ChartGestureMode.navigation,
          mode: ChartGestureMode.holdOnly,
          overrides: null,
          enableGestures: true,
          styleShowsCrosshair: false,
          revealCrosshairForPreset: reveal,
        );

    expect(resolve(true).longPressCrosshair, isTrue);
    expect(resolve(true).crosshairVisible, isTrue);
    expect(resolve(false).longPressCrosshair, isFalse);
  });
}
