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

    test('preserves context when detached from latest during append', () {
      final controller = ImpChartController(
        candles: buildCandles(120),
        defaultVisibleCount: 20,
      );

      controller.panByCandles(-10);
      expect(controller.isFollowingLatest, isFalse);
      expect(
        controller.followLatestState,
        ChartFollowLatestState.detachedHistorical,
      );

      final beforeStart = controller.viewport.startIndex;
      controller.appendCandle(
        Candle(
          time: 1700009999,
          open: 300,
          high: 305,
          low: 295,
          close: 302,
        ),
      );

      expect(controller.viewport.startIndex, beforeStart);
      expect(controller.isFollowingLatest, isFalse);
    });

    test('auto-follows when still near latest during append', () {
      final controller = ImpChartController(
        candles: buildCandles(120),
        defaultVisibleCount: 20,
      );

      controller.panByCandles(-2);
      expect(controller.isFollowingLatest, isTrue);

      controller.appendCandle(
        Candle(
          time: 1700010000,
          open: 400,
          high: 405,
          low: 395,
          close: 403,
        ),
      );

      expect(controller.isFollowingLatest, isTrue);
      expect(controller.viewport.endIndex, controller.candles.length);
    });

    test('scroll to latest restores follow latest', () {
      final controller = ImpChartController(
        candles: buildCandles(100),
        defaultVisibleCount: 25,
      );

      controller.panByCandles(-10);
      expect(controller.isFollowingLatest, isFalse);

      controller.scrollToLatest();
      expect(controller.isFollowingLatest, isTrue);
      expect(
        controller.followLatestState,
        ChartFollowLatestState.followingLatest,
      );
      expect(controller.viewport.endIndex, controller.candles.length);
    });

    test('three candle threshold still counts as near latest', () {
      final controller = ImpChartController(
        candles: buildCandles(100),
        defaultVisibleCount: 20,
      );

      controller.panByCandles(-3);
      expect(controller.isFollowingLatest, isTrue);

      controller.panByCandles(-1);
      expect(controller.isFollowingLatest, isFalse);
      expect(
        controller.followLatestState,
        ChartFollowLatestState.detachedHistorical,
      );
    });

    test('in-place list mutation is treated as live append', () async {
      final candles = buildCandles(50);
      final controller = ImpChartController(
        candles: candles,
        defaultVisibleCount: 20,
      );
      final events = <ChartEvent>[];
      final subscription = controller.events.listen(events.add);

      candles.add(
        Candle(
          time: 1700009999,
          open: 200,
          high: 202,
          low: 198,
          close: 201,
        ),
      );
      controller.setCandles(candles);

      await Future<void>.delayed(Duration.zero);
      expect(events.last.type, ChartEventType.liveCandleAppended);
      expect(controller.viewport.endIndex, controller.candles.length);

      await subscription.cancel();
    });

    test('detached live update emits preserve-context event', () async {
      final controller = ImpChartController(
        candles: buildCandles(80),
        defaultVisibleCount: 20,
      );
      final events = <ChartEvent>[];
      final subscription = controller.events.listen(events.add);

      controller.panByCandles(-8);
      final beforeStart = controller.viewport.startIndex;
      controller.appendCandle(
        Candle(
          time: 1700011000,
          open: 250,
          high: 255,
          low: 245,
          close: 252,
        ),
      );

      await Future<void>.delayed(Duration.zero);
      expect(events.last.type, ChartEventType.liveUpdatePreservedContext);
      expect(controller.viewport.startIndex, beforeStart);

      await subscription.cancel();
    });
  });
}
