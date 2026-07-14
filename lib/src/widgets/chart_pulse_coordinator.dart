import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:imp_trading_chart/src/theme/ripple_animation_style.dart';

/// Coordinates the repeating ripple animation used for the latest data point.
///
/// This helper keeps timer and animation-controller responsibilities out of the
/// chart widget state so `ImpChart` stays focused on binding and composition.
class ChartPulseCoordinator {
  ChartPulseCoordinator({
    required TickerProvider vsync,
    required VoidCallback onProgressChanged,
  })  : _onProgressChanged = onProgressChanged,
        _controller = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 1200),
        ) {
    _controller.addListener(_handleTick);
  }

  final VoidCallback _onProgressChanged;
  final AnimationController _controller;
  Timer? _timer;

  /// Current animation progress in the `[0, 1]` range.
  double get progress => _controller.value;

  /// Aligns the pulse cycle with the current ripple visibility state.
  void sync({
    required RippleAnimationStyle style,
    required bool enabled,
    required bool hasCandles,
  }) {
    if (!enabled || !hasCandles) {
      stop(resetProgress: true);
      return;
    }

    _controller.duration = Duration(milliseconds: style.animationDurationMs);
    if (_timer == null || !_timer!.isActive) {
      _startContinuous(style);
    }
  }

  /// Forces an immediate pulse while preserving the repeating cycle.
  void trigger({
    required RippleAnimationStyle style,
    required bool enabled,
    required bool hasCandles,
  }) {
    if (!enabled || !hasCandles) {
      return;
    }

    _controller.duration = Duration(milliseconds: style.animationDurationMs);
    if (_timer == null || !_timer!.isActive) {
      _startContinuous(style);
      return;
    }

    _play();
  }

  /// Stops the pulse cycle and optionally resets the visual progress.
  void stop({bool resetProgress = false}) {
    _timer?.cancel();
    _timer = null;
    _controller.stop();
    if (resetProgress) {
      _controller.value = 0.0;
      _onProgressChanged();
    }
  }

  /// Disposes the owned timer and animation resources.
  void dispose() {
    _timer?.cancel();
    _controller
      ..removeListener(_handleTick)
      ..dispose();
  }

  void _startContinuous(RippleAnimationStyle style) {
    _timer?.cancel();
    _play();

    final totalCycleMs = style.animationDurationMs + style.intervalMs;
    _timer = Timer.periodic(Duration(milliseconds: totalCycleMs), (_) {
      _play();
    });
  }

  void _play() {
    _controller
      ..reset()
      ..forward();
  }

  void _handleTick() {
    _onProgressChanged();
  }
}
