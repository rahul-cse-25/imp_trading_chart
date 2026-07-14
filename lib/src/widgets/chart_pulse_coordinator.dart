import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:imp_trading_chart/src/theme/ripple_animation_style.dart';

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

  double get progress => _controller.value;

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

  void stop({bool resetProgress = false}) {
    _timer?.cancel();
    _timer = null;
    _controller.stop();
    if (resetProgress) {
      _controller.value = 0.0;
      _onProgressChanged();
    }
  }

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
