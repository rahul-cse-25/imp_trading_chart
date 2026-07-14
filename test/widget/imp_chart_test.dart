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

  testWidgets('legacy chart usage still builds without controller',
      (tester) async {
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

  testWidgets('old viewport callback still fires', (tester) async {
    bool fired = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: ImpChart.simple(
              candles: buildCandles(50),
              onViewportChanged: (_) => fired = true,
            ),
          ),
        ),
      ),
    );

    expect(fired, isTrue);
  });

  testWidgets('mutated candle list preserves detached viewport on rebuild', (
    tester,
  ) async {
    final candles = buildCandles(120);
    final controller = ImpChartController(
      candles: candles,
      defaultVisibleCount: 20,
    );
    controller.panByCandles(-10);
    final beforeStart = controller.viewport.startIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: ImpChart.trading(
              candles: candles,
              controller: controller,
            ),
          ),
        ),
      ),
    );

    candles.add(
      Candle(
        time: 1700009999,
        open: 300,
        high: 305,
        low: 295,
        close: 302,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: ImpChart.trading(
              candles: candles,
              controller: controller,
            ),
          ),
        ),
      ),
    );

    expect(controller.viewport.startIndex, beforeStart);
    expect(controller.isFollowingLatest, isFalse);
  });

  testWidgets('mutated candle list auto-follows when still near latest', (
    tester,
  ) async {
    final candles = buildCandles(120);
    final controller = ImpChartController(
      candles: candles,
      defaultVisibleCount: 20,
    );
    controller.panByCandles(-2);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: ImpChart.trading(
              candles: candles,
              controller: controller,
            ),
          ),
        ),
      ),
    );

    candles.add(
      Candle(
        time: 1700010000,
        open: 400,
        high: 405,
        low: 395,
        close: 403,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: ImpChart.trading(
              candles: candles,
              controller: controller,
            ),
          ),
        ),
      ),
    );

    expect(controller.isFollowingLatest, isTrue);
    expect(controller.viewport.endIndex, controller.candles.length);
  });

  testWidgets('shows live indicator when detached data updates arrive', (
    tester,
  ) async {
    final candles = buildCandles(120);
    final controller = ImpChartController(
      candles: candles,
      defaultVisibleCount: 20,
    );
    controller.panByCandles(-10);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: ImpChart.trading(
              candles: candles,
              controller: controller,
            ),
          ),
        ),
      ),
    );

    candles.add(
      Candle(
        time: 1700011000,
        open: 500,
        high: 505,
        low: 495,
        close: 503,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: ImpChart.trading(
              candles: candles,
              controller: controller,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Go to live (+1)'), findsOneWidget);
  });

  testWidgets('tapping live indicator scrolls back to latest', (tester) async {
    final candles = buildCandles(120);
    final controller = ImpChartController(
      candles: candles,
      defaultVisibleCount: 20,
    );
    controller.panByCandles(-10);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: ImpChart.trading(
              candles: candles,
              controller: controller,
            ),
          ),
        ),
      ),
    );

    candles.add(
      Candle(
        time: 1700012000,
        open: 600,
        high: 605,
        low: 595,
        close: 603,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: ImpChart.trading(
              candles: candles,
              controller: controller,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Go to live (+1)'));
    await tester.pump();

    expect(controller.isFollowingLatest, isTrue);
    expect(controller.viewport.endIndex, controller.candles.length);
    expect(find.text('Go to live (+1)'), findsNothing);
  });
}
