import 'package:flutter/material.dart';

class ChartGestureSession {
  ChartGestureSession({
    this.zoomThreshold = 0.05,
  });

  final double zoomThreshold;

  double _baseScale = 1.0;
  double _accumulatedPanDelta = 0.0;
  Offset? _lastPanPosition;

  void start(Offset focalPoint) {
    _baseScale = 1.0;
    _lastPanPosition = focalPoint;
    _accumulatedPanDelta = 0.0;
  }

  void update({
    required ScaleUpdateDetails details,
    required double candleWidth,
    required int anchorIndex,
    required int totalCount,
    required VoidCallback zoomIn,
    required VoidCallback zoomOut,
    required void Function(int anchorIndex, int step) zoomAround,
    required void Function(int delta) panByCandles,
  }) {
    final scaleChange = (details.scale - _baseScale).abs();
    final isZoom = scaleChange > zoomThreshold;

    if (isZoom) {
      if (anchorIndex >= 0 && anchorIndex < totalCount) {
        zoomAround(
          anchorIndex,
          (details.scale - _baseScale) > 0 ? -1 : 1,
        );
      } else if ((details.scale - _baseScale) > 0) {
        zoomIn();
      } else {
        zoomOut();
      }

      _baseScale = details.scale;
      _lastPanPosition = details.focalPoint;
      _accumulatedPanDelta = 0.0;
      return;
    }

    if (_lastPanPosition == null || candleWidth <= 0) {
      _lastPanPosition = details.focalPoint;
      return;
    }

    final delta = _lastPanPosition!.dx - details.focalPoint.dx;
    _accumulatedPanDelta += delta;
    final candleDelta = (_accumulatedPanDelta / candleWidth).round();
    if (candleDelta.abs() >= 1) {
      panByCandles(candleDelta);
      _accumulatedPanDelta -= candleDelta * candleWidth;
    }

    _lastPanPosition = details.focalPoint;
  }
}
