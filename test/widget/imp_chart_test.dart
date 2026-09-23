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

  testWidgets('trading preset allows pan and hold together', (tester) async {
    final candles = buildCandles(120);
    final controller = ImpChartController(
      candles: candles,
      defaultVisibleCount: 20,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 250,
          child: ImpChart.trading(candles: candles, controller: controller),
        ),
      ),
    ));

    final chart = find.byType(ImpChart);
    final before = controller.viewport.startIndex;
    await tester.timedDrag(
      chart,
      const Offset(180, 0),
      const Duration(milliseconds: 250),
    );
    await tester.pump();
    expect(controller.viewport.startIndex, lessThan(before));

    final gesture = await tester.startGesture(tester.getCenter(chart));
    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.selection, isNotNull);
    final selectedStart = controller.viewport.startIndex;
    await gesture.moveBy(const Offset(-80, 0));
    await tester.pump();
    expect(controller.viewport.startIndex, selectedStart);
    await gesture.up();
    await tester.pump();
    expect(controller.selection, isNull);
  });

  testWidgets('two widgets sharing one controller keep independent modes',
      (tester) async {
    final candles = buildCandles(120);
    final controller = ImpChartController(
      candles: candles,
      defaultVisibleCount: 20,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Row(children: [
          SizedBox(
            width: 350,
            height: 240,
            child: ImpChart.trading(
              candles: candles,
              controller: controller,
              gestureMode: ChartGestureMode.none,
            ),
          ),
          SizedBox(
            width: 350,
            height: 240,
            child: ImpChart.compact(
              candles: candles,
              controller: controller,
              gestureMode: ChartGestureMode.panOnly,
            ),
          ),
        ]),
      ),
    ));

    final charts = find.byType(ImpChart);
    final before = controller.viewport.startIndex;
    await tester.timedDrag(
      charts.first,
      const Offset(180, 0),
      const Duration(milliseconds: 250),
    );
    await tester.pump();
    expect(controller.viewport.startIndex, before);

    await tester.timedDrag(
      charts.last,
      const Offset(180, 0),
      const Duration(milliseconds: 250),
    );
    await tester.pump();
    expect(controller.viewport.startIndex, lessThan(before));
  });

  testWidgets('new mode can be applied during a rebuild', (tester) async {
    final candles = buildCandles(120);
    final controller = ImpChartController(
      candles: candles,
      defaultVisibleCount: 20,
    );
    Widget chart(ChartGestureMode mode) => MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 250,
              child: ImpChart.trading(
                candles: candles,
                controller: controller,
                gestureMode: mode,
              ),
            ),
          ),
        );

    await tester.pumpWidget(chart(ChartGestureMode.none));
    final before = controller.viewport.startIndex;
    await tester.timedDrag(
      find.byType(ImpChart),
      const Offset(180, 0),
      const Duration(milliseconds: 250),
    );
    await tester.pump();
    expect(controller.viewport.startIndex, before);

    await tester.pumpWidget(chart(ChartGestureMode.panOnly));
    await tester.timedDrag(
      find.byType(ImpChart),
      const Offset(180, 0),
      const Duration(milliseconds: 250),
    );
    await tester.pump();
    expect(controller.viewport.startIndex, lessThan(before));
  });

  testWidgets('rebuild with stale input does not undo controller append',
      (tester) async {
    final candles = buildCandles(120);
    final controller = ImpChartController(
      candles: candles,
      defaultVisibleCount: 20,
    );
    Widget chart() => MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 250,
              child: ImpChart.simple(
                candles: candles,
                controller: controller,
              ),
            ),
          ),
        );

    await tester.pumpWidget(chart());
    controller.appendCandle(buildCandles(121).last);
    await tester.pump();
    await tester.pumpWidget(chart());
    await tester.pump();
    expect(controller.candles.length, 121);
  });

  testWidgets('in-place middle correction reaches an external controller',
      (tester) async {
    final candles = buildCandles(120);
    final controller = ImpChartController(
      candles: candles,
      defaultVisibleCount: 20,
    );
    Widget chart() => MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 250,
              child: ImpChart.simple(
                candles: candles,
                controller: controller,
              ),
            ),
          ),
        );

    await tester.pumpWidget(chart());
    controller.panByCandles(-10);
    final before = controller.viewport.startIndex;
    candles[50] = candles[50].copyWith(close: 999);
    await tester.pumpWidget(chart());
    await tester.pump();

    expect(controller.candles[50].close, 999);
    expect(controller.viewport.startIndex, before);
  });

  testWidgets('last-candle update never adds a phantom live candle count',
      (tester) async {
    final candles = buildCandles(120);
    final controller = ImpChartController(
      candles: candles,
      defaultVisibleCount: 20,
    );
    controller.panByCandles(-10);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 250,
          child: ImpChart.trading(
            candles: candles,
            controller: controller,
            gestureMode: ChartGestureMode.none,
          ),
        ),
      ),
    ));
    controller.updateLastCandle(candles.last.copyWith(close: 999));
    await tester.pump();
    expect(find.textContaining('Go to live'), findsNothing);

    controller.appendCandle(buildCandles(121).last);
    await tester.pump();
    expect(find.text('Go to live (+1)'), findsOneWidget);
    controller.updateLastCandle(
      controller.candles.last
          .copyWith(close: controller.candles.last.close + 1),
    );
    await tester.pump();
    expect(find.text('Go to live (+1)'), findsOneWidget);
    await tester.tap(find.text('Go to live (+1)'));
    await tester.pump();
    expect(controller.isFollowingLatest, isTrue);
  });

  testWidgets('holdOnly keeps the Go to live action available', (tester) async {
    final candles = buildCandles(120);
    final controller = ImpChartController(
      candles: candles,
      defaultVisibleCount: 20,
    );
    controller.panByCandles(-10);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 250,
          child: ImpChart.trading(
            candles: candles,
            controller: controller,
            gestureMode: ChartGestureMode.holdOnly,
          ),
        ),
      ),
    ));

    controller.appendCandle(buildCandles(121).last);
    await tester.pump();
    await tester.tap(find.text('Go to live (+1)'));
    await tester.pump();
    expect(controller.isFollowingLatest, isTrue);
  });

  testWidgets('mode permissions and hard-off select the right recognizers',
      (tester) async {
    final candles = buildCandles(30);
    Future<GestureDetector> detector(
      ChartGestureMode mode, {
      bool enabled = true,
      ChartGestureOverrides? overrides,
    }) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 250,
            child: ImpChart.trading(
              candles: candles,
              gestureMode: mode,
              gestureOverrides: overrides,
              enableGestures: enabled,
            ),
          ),
        ),
      ));
      return tester.widget<GestureDetector>(find
          .descendant(
            of: find.byType(ImpChart),
            matching: find.byType(GestureDetector),
          )
          .first);
    }

    final mixed = await detector(ChartGestureMode.mixed);
    expect(mixed.onScaleUpdate, isNotNull);
    expect(mixed.onDoubleTap, isNotNull);
    expect(mixed.onLongPressStart, isNotNull);

    final hold = await detector(ChartGestureMode.holdOnly);
    expect(hold.onScaleUpdate, isNull);
    expect(hold.onDoubleTap, isNull);
    expect(hold.onLongPressStart, isNotNull);

    final pan = await detector(ChartGestureMode.panOnly);
    expect(pan.onScaleUpdate, isNotNull);
    expect(pan.onDoubleTap, isNull);
    expect(pan.onLongPressStart, isNull);

    final none = await detector(ChartGestureMode.none);
    expect(none.onScaleUpdate, isNull);
    expect(none.onLongPressStart, isNull);

    final off = await detector(
      ChartGestureMode.mixed,
      enabled: false,
      overrides: const ChartGestureOverrides(pan: true),
    );
    expect(off.onScaleUpdate, isNull);
    expect(off.onDoubleTap, isNull);
    expect(off.onLongPressStart, isNull);
  });

  testWidgets('double tap restores follow latest when allowed', (tester) async {
    final candles = buildCandles(120);
    final controller = ImpChartController(
      candles: candles,
      defaultVisibleCount: 20,
    );
    controller.panByCandles(-10);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 250,
          child: ImpChart.trading(candles: candles, controller: controller),
        ),
      ),
    ));

    final chart = find.byType(ImpChart);
    await tester.tap(chart);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(chart);
    await tester.pump(const Duration(milliseconds: 400));
    expect(controller.viewport.endIndex, candles.length);
    expect(controller.isFollowingLatest, isTrue);
  });

  testWidgets('narrow single-point chart skips labels that cannot fit',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 40,
          height: 120,
          child: ImpChart.trading(candles: buildCandles(1)),
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
  });

  testWidgets('holdOnly works on normally noninteractive minimal preset',
      (tester) async {
    final candles = buildCandles(120);
    final controller = ImpChartController(candles: candles);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 250,
          child: ImpChart.minimal(
            candles: candles,
            controller: controller,
            gestureMode: ChartGestureMode.holdOnly,
          ),
        ),
      ),
    ));

    final chartWidget = tester.widget<ImpChart>(find.byType(ImpChart));
    expect(chartWidget.style.crosshairStyle.show, isTrue);
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(ImpChart)));
    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.selection, isNotNull);
    await gesture.up();
  });

  testWidgets('trading showCrosshair false keeps navigation available',
      (tester) async {
    final candles = buildCandles(30);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 250,
          child: ImpChart.trading(
            candles: candles,
            showCrosshair: false,
          ),
        ),
      ),
    ));
    final widget = tester.widget<ImpChart>(find.byType(ImpChart));
    expect(widget.style.crosshairStyle.show, isFalse);
    final detector = tester.widget<GestureDetector>(find
        .descendant(
          of: find.byType(ImpChart),
          matching: find.byType(GestureDetector),
        )
        .first);
    expect(detector.onScaleUpdate, isNotNull);
    expect(detector.onLongPressStart, isNull);
  });

  testWidgets('offset chart pinches around local candle without panning',
      (tester) async {
    final candles = buildCandles(120);
    final controller = ImpChartController(
      candles: candles,
      defaultVisibleCount: 20,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(left: 500),
          child: SizedBox(
            width: 250,
            height: 250,
            child: ImpChart.trading(
              candles: candles,
              controller: controller,
              gestureMode: ChartGestureMode.zoomOnly,
            ),
          ),
        ),
      ),
    ));

    final chart = find.byType(ImpChart);
    final topLeft = tester.getTopLeft(chart);
    final first =
        await tester.startGesture(topLeft + const Offset(25, 100), pointer: 1);
    final second =
        await tester.startGesture(topLeft + const Offset(65, 100), pointer: 2);
    await tester.pump();
    await first.moveTo(topLeft + const Offset(5, 100));
    await second.moveTo(topLeft + const Offset(90, 100));
    await tester.pump();
    await first.moveTo(topLeft + const Offset(0, 100));
    await second.moveTo(topLeft + const Offset(100, 100));
    await tester.pump();

    expect(controller.viewport.visibleCount, lessThan(20));
    expect(controller.viewport.startIndex, 100);
    await first.up();
    await second.up();
  });
}
