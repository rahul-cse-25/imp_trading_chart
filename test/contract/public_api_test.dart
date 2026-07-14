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
}
