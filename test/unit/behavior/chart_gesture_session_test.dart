import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imp_trading_chart/src/widgets/chart_gesture_session.dart';

void main() {
  test('one pointer pans while two pointers only zoom', () {
    final session = ChartGestureSession();
    var pan = 0;
    var zoom = 0;
    int? zoomAnchor;

    void update({
      required int pointers,
      required Offset local,
      required double scale,
      required bool allowPan,
      required bool allowZoom,
    }) {
      session.update(
        details: ScaleUpdateDetails(
          pointerCount: pointers,
          localFocalPoint: local,
          scale: scale,
        ),
        candleWidth: 20,
        anchorIndex: 7,
        totalCount: 100,
        allowPan: allowPan,
        allowPinchZoom: allowZoom,
        zoomIn: () => zoom++,
        zoomOut: () => zoom++,
        zoomAround: (anchor, _) {
          zoomAnchor = anchor;
          zoom++;
        },
        panByCandles: (delta) => pan += delta,
      );
    }

    session.start(const Offset(100, 50), pointerCount: 1);
    update(
      pointers: 1,
      local: const Offset(60, 50),
      scale: 1,
      allowPan: true,
      allowZoom: true,
    );
    expect(pan, 2);

    update(
      pointers: 2,
      local: const Offset(30, 50),
      scale: 1,
      allowPan: true,
      allowZoom: true,
    );
    update(
      pointers: 2,
      local: const Offset(20, 50),
      scale: 1.2,
      allowPan: true,
      allowZoom: true,
    );
    expect(pan, 2);
    expect(zoom, 1);
    expect(zoomAnchor, 7);

    update(
      pointers: 2,
      local: const Offset(10, 50),
      scale: 1.4,
      allowPan: true,
      allowZoom: false,
    );
    expect(pan, 2);
    expect(zoom, 1);
  });
}
