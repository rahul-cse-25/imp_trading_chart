import 'package:flutter_test/flutter_test.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart';

void main() {
  test('public controller and snapshot types are exported', () {
    final controller = ImpChartController();

    expect(controller.events, isA<Stream<ChartEvent>>());
    expect(controller.viewport, isA<ChartViewportSnapshot>());
    expect(controller.visibleRange, isA<ChartVisibleRange>());
    expect(controller.snapshot, isA<ChartRenderSnapshot>());
  });
}
