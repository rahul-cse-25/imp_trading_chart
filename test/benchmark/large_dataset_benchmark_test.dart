import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart';

void main() {
  test('10k candles: compare and correct a historical candle', () {
    final candles = List<Candle>.generate(
      10000,
      (index) => Candle(
        time: 1700000000 + index * 60,
        open: index.toDouble(),
        high: index + 2.0,
        low: index - 2.0,
        close: index + 1.0,
      ),
    );
    final controller = ImpChartController(candles: candles);
    final timer = Stopwatch()..start();

    for (var revision = 0; revision < 30; revision++) {
      final replacement = List<Candle>.of(controller.candles);
      replacement[5000] = replacement[5000].copyWith(
        close: 5000.0 + revision,
      );
      controller.setCandles(replacement);
      controller.setCandles(replacement);
    }

    timer.stop();
    expect(controller.candles[5000].close, 5029);
    debugPrint('10k candles, 30 corrections and 30 no-op comparisons: '
        '${timer.elapsedMilliseconds} ms');
    controller.dispose();
  });
}
