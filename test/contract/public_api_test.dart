import 'package:flutter_test/flutter_test.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart';

void main() {
  test('public controller and snapshot types are exported', () {
    final controller = ImpChartController();

    expect(controller.events, isA<Stream<ChartEvent>>());
    expect(controller.viewport, isA<ChartViewportSnapshot>());
    expect(controller.visibleRange, isA<ChartVisibleRange>());
    expect(controller.snapshot, isA<ChartRenderSnapshot>());
    expect(controller.followLatestState, isA<ChartFollowLatestState>());
  });

  test('legacy constructors keep controller optional', () {
    expect(
      ImpChart.trading(candles: const <Candle>[]),
      isA<ImpChart>(),
    );
    expect(
      ImpChart.simple(candles: const <Candle>[]),
      isA<ImpChart>(),
    );
    expect(
      ImpChart.compact(candles: const <Candle>[]),
      isA<ImpChart>(),
    );
    expect(
      ImpChart.minimal(candles: const <Candle>[]),
      isA<ImpChart>(),
    );
  });

  test('gesture modes and overrides are available from the package import', () {
    final chart = ImpChart.trading(
      candles: const <Candle>[],
      gestureMode: ChartGestureMode.holdOnly,
      gestureOverrides: const ChartGestureOverrides(pan: true),
    );

    expect(chart.gestureMode, ChartGestureMode.holdOnly);
    expect(chart.gestureOverrides!.pan, isTrue);
    expect(ImpChart.trading(candles: const <Candle>[]).gestureMode,
        ChartGestureMode.mixed);
    expect(ImpChart.simple(candles: const <Candle>[]).gestureMode,
        ChartGestureMode.navigation);
    expect(ImpChart.compact(candles: const <Candle>[]).gestureMode,
        ChartGestureMode.navigation);
    expect(ImpChart.minimal(candles: const <Candle>[]).enableGestures, isFalse);
  });
}
