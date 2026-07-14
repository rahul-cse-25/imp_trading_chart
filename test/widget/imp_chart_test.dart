import 'package:flutter/material.dart';
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

  testWidgets('trading chart builds with controller', (tester) async {
    final controller = ImpChartController(
      candles: buildCandles(120),
      defaultVisibleCount: 60,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: ImpChart.trading(
              candles: buildCandles(120),
              controller: controller,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ImpChart), findsOneWidget);
  });

  testWidgets('legacy chart usage still builds without controller', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: ImpChart.simple(
              candles: buildCandles(40),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ImpChart), findsOneWidget);
  });
}
