import 'package:flutter_test/flutter_test.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart';

void main() {
  List<Candle> buildCandles(int count) {
    return List.generate(
      count,
      (index) => Candle(
        time: 1700000000 + index,
        open: 100 + index.toDouble(),
        high: 101 + index.toDouble(),
        low: 99 + index.toDouble(),
        close: 100.5 + index.toDouble(),
      ),
    );
  }

  group('ImpChartController', () {
    test('initializes viewport from provided candles', () {
      final controller = ImpChartController(
        candles: buildCandles(200),
        defaultVisibleCount: 80,
      );

      expect(controller.viewport.startIndex, 120);
      expect(controller.viewport.visibleCount, 80);
      expect(controller.visibleRange.length, 80);
    });

    test('supports pan and reset commands', () {
      final controller = ImpChartController(
        candles: buildCandles(150),
        defaultVisibleCount: 50,
      );

      controller.panByCandles(-10);
      expect(controller.viewport.startIndex, 90);

      controller.resetViewport();
      expect(controller.viewport.startIndex, 100);
      expect(controller.viewport.visibleCount, 50);
    });

    test('supports selection and clearing', () {
      final candles = buildCandles(60);
      final controller = ImpChartController(
        candles: candles,
        defaultVisibleCount: 20,
      );

      controller.showCrosshairAtIndex(55);
      expect(controller.selection, isNotNull);
      expect(controller.selection!.absoluteIndex, 55);
      expect(controller.selection!.candle, candles[55]);

      controller.hideCrosshair();
      expect(controller.selection, isNull);
    });
  });
}
