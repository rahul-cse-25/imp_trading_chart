import 'package:flutter/material.dart';

/// Tracks an in-progress scale gesture and emits semantic chart commands.
///
/// The chart widget delegates scale bookkeeping here so controller-oriented
/// gesture behavior stays isolated from widget composition code.
class ChartGestureSession {
  ChartGestureSession({
    this.zoomThreshold = 0.05,
  });

  final double zoomThreshold;

  double _baseScale = 1.0;
  double _accumulatedPanDelta = 0.0;
  Offset? _lastPanPosition;
  int _pointerCount = 0;

  /// Starts a new gesture session from the given focal point.
  void start(Offset localFocalPoint, {required int pointerCount}) {
    _baseScale = 1.0;
    _lastPanPosition = localFocalPoint;
    _accumulatedPanDelta = 0.0;
    _pointerCount = pointerCount;
  }

  /// Consumes a scale update and translates it into zoom or pan commands.
  void update({
    required ScaleUpdateDetails details,
    required double candleWidth,
    required int anchorIndex,
    required int totalCount,
    required bool allowPan,
    required bool allowPinchZoom,
    required VoidCallback zoomIn,
    required VoidCallback zoomOut,
    required void Function(int anchorIndex, int step) zoomAround,
    required void Function(int delta) panByCandles,
  }) {
    if (details.pointerCount != _pointerCount) {
      _pointerCount = details.pointerCount;
      _baseScale = details.scale;
      _lastPanPosition = details.localFocalPoint;
      _accumulatedPanDelta = 0.0;
      return;
    }

    if (details.pointerCount >= 2) {
      if (!allowPinchZoom) return;
      final scaleChange = (details.scale - _baseScale).abs();
      if (scaleChange <= zoomThreshold) return;

      if (anchorIndex >= 0 && anchorIndex < totalCount) {
        zoomAround(anchorIndex, (details.scale - _baseScale) > 0 ? -1 : 1);
      } else if ((details.scale - _baseScale) > 0) {
        zoomIn();
      } else {
        zoomOut();
      }
      _baseScale = details.scale;
      return;
    }

    if (!allowPan || details.pointerCount != 1) return;
    if (_lastPanPosition == null || candleWidth <= 0) {
      _lastPanPosition = details.localFocalPoint;
      return;
    }

    final delta = _lastPanPosition!.dx - details.localFocalPoint.dx;
    _accumulatedPanDelta += delta;
    final candleDelta = (_accumulatedPanDelta / candleWidth).round();
    if (candleDelta.abs() >= 1) {
      panByCandles(candleDelta);
      _accumulatedPanDelta -= candleDelta * candleWidth;
    }

    _lastPanPosition = details.localFocalPoint;
  }
}
