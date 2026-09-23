import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart';

void main() {
  final candles = List<Candle>.generate(
    30,
    (index) => Candle(
      time: 1700000000 + index * 60,
      open: 90 + index.toDouble(),
      high: 93 + index.toDouble(),
      low: 88 + index.toDouble(),
      close: 91 + index.toDouble() + (index.isEven ? 1 : -1),
    ),
  );

  Widget frame(Widget chart) => MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF101820),
          body: Center(
            child: SizedBox(
              width: 400,
              height: 260,
              child: chart,
            ),
          ),
        ),
      );

  testWidgets('simple line chart', (tester) async {
    await tester.pumpWidget(frame(ImpChart.simple(candles: candles)));
    await expectLater(
      find.byType(ImpChart),
      matchesGoldenFile('goldens/simple_line.png'),
    );
  });

  testWidgets('trading line chart with static price marker', (tester) async {
    final style = ChartStyle.trading().copyWith(
      rippleStyle: RippleAnimationStyle.hidden(),
    );
    await tester.pumpWidget(frame(ImpChart(candles: candles, style: style)));
    await expectLater(
      find.byType(ImpChart),
      matchesGoldenFile('goldens/trading_line.png'),
    );
  });

  testWidgets('detached chart shows its live action', (tester) async {
    final controller = ImpChartController(
      candles: candles,
      defaultVisibleCount: 12,
    );
    controller.panByCandles(-6);
    await tester.pumpWidget(frame(ImpChart.simple(
      candles: candles,
      controller: controller,
      gestureMode: ChartGestureMode.none,
    )));
    controller.appendCandle(Candle(
      time: candles.last.time + 60,
      open: 120,
      high: 123,
      low: 119,
      close: 122,
    ));
    await tester.pump();
    await expectLater(
      find.byType(ImpChart),
      matchesGoldenFile('goldens/detached_live.png'),
    );
  });
}
