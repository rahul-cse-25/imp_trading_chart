import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart';

/// Interactive controller showcase for `ImpChartController`.
///
/// This screen is intentionally designed as a proof-oriented example for
/// package users. It demonstrates:
/// - one shared external controller as the single source of truth
/// - two synchronized chart widgets powered by the same controller
/// - a draggable primary chart and a locked secondary mirror chart
/// - programmatic pan, zoom, fit-all, reset, and scroll-to-latest actions
/// - direct controller-driven append/update flows without parent/widget hacks
class ControllerLabScreen extends StatefulWidget {
  const ControllerLabScreen({super.key});

  @override
  State<ControllerLabScreen> createState() => _ControllerLabScreenState();
}

class _ControllerLabScreenState extends State<ControllerLabScreen> {
  final math.Random _random = math.Random();
  late final ImpChartController _controller;
  Timer? _liveTimer;
  bool _isLive = false;

  @override
  void initState() {
    super.initState();
    _controller = ImpChartController(
      candles: _buildInitialCandles(),
      defaultVisibleCount: 60,
    );
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final snapshot = _controller.snapshot;
        final candles = _controller.candles;
        final currentPrice = candles.isEmpty ? null : candles.last.close;

        return Scaffold(
          backgroundColor: const Color(0xFF04060D),
          body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.6,
                colors: [
                  Color(0xFF13243F),
                  Color(0xFF04060D),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    Row(
                      spacing: 4,
                      children: [
                        IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.arrow_back)),
                        Expanded(
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Controller Lab',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'One controller • two synchronized views',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _LiveBadge(isLive: _isLive),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildHeroStatus(snapshot),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 8,
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: _ChartPanel(
                                    title: 'Primary View',
                                    subtitle:
                                        'Same controller, gestures locked',
                                    accent: const Color(0xFF35D48A),
                                    child: ImpChart.trading(
                                      candles: candles,
                                      controller: _controller,
                                      currentPrice: currentPrice,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Expanded(
                                  flex: 4,
                                  child: _ChartPanel(
                                    title: 'Mirror View',
                                    subtitle:
                                        'Drag horizontally to inspect history',
                                    accent: const Color(0xFF4EA1FF),
                                    child: ImpChart.compact(
                                      candles: candles,
                                      controller: _controller,
                                      currentPrice: currentPrice,
                                      enableGestures: true,
                                      showGrid: true,
                                      showPriceLabels: true,
                                      showTimeLabels: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 5,
                            child: _buildCommandSidebar(snapshot),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroStatus(ChartRenderSnapshot snapshot) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF111A2B),
            Color(0xFF0A0F1C),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _StatusCard(
            label: 'Candles',
            value: '${snapshot.candles.length}',
            accent: const Color(0xFF35D48A),
          ),
          _StatusCard(
            label: 'Viewport',
            value:
                '${snapshot.viewport.startIndex}-${snapshot.viewport.endIndex}',
            accent: const Color(0xFF4EA1FF),
          ),
          _StatusCard(
            label: 'Follow State',
            value: snapshot.followLatestState.name,
            accent: const Color(0xFFFFB454),
          ),
          _StatusCard(
            label: 'Latest Price',
            value: snapshot.latestPrice?.toStringAsFixed(2) ?? '--',
            accent: const Color(0xFFFF6B8A),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandSidebar(ChartRenderSnapshot snapshot) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B111D).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Controller Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Both charts consume the same controller state. Only the primary view accepts gestures.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            _SidebarSection(
              title: 'Viewport',
              children: [
                _ActionButton(
                  label: 'Pan Left',
                  subtitle: 'Move 10 candles into older history',
                  accent: const Color(0xFF4EA1FF),
                  onPressed: () => _controller.panByCandles(-10),
                ),
                _ActionButton(
                  label: 'Pan Right',
                  subtitle: 'Move 10 candles toward latest',
                  accent: const Color(0xFF4EA1FF),
                  onPressed: () => _controller.panByCandles(10),
                ),
                _ActionButton(
                  label: 'Zoom In',
                  subtitle: 'Show fewer candles',
                  accent: const Color(0xFFFFB454),
                  onPressed: _controller.zoomIn,
                ),
                _ActionButton(
                  label: 'Zoom Out',
                  subtitle: 'Show more candles',
                  accent: const Color(0xFFFFB454),
                  onPressed: _controller.zoomOut,
                ),
                _ActionButton(
                  label: 'Fit All',
                  subtitle: 'Reveal the full dataset',
                  accent: const Color(0xFF35D48A),
                  onPressed: _controller.fitAll,
                ),
                _ActionButton(
                  label: 'Reset View',
                  subtitle: 'Restore default latest-aligned viewport',
                  accent: const Color(0xFF35D48A),
                  onPressed: _controller.resetViewport,
                ),
                _ActionButton(
                  label: 'Go To Latest',
                  subtitle: 'Re-enable follow-latest behavior',
                  accent: const Color(0xFFFF6B8A),
                  onPressed: _controller.scrollToLatest,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SidebarSection(
              title: 'Data Flow',
              children: [
                _ActionButton(
                  label: 'Append Candle',
                  subtitle: 'Create a new candle through the controller',
                  accent: const Color(0xFF35D48A),
                  onPressed: _appendNewCandle,
                ),
                _ActionButton(
                  label: 'Update Last Candle',
                  subtitle: 'Mutate only the latest candle',
                  accent: const Color(0xFF4EA1FF),
                  onPressed: _updateLastCandle,
                ),
                _ActionButton(
                  label: _isLive ? 'Stop Live Feed' : 'Start Live Feed',
                  subtitle: _isLive
                      ? 'Pause timed appends'
                      : 'Append one candle every second',
                  accent: _isLive
                      ? const Color(0xFFFF6B6B)
                      : const Color(0xFF35D48A),
                  onPressed: _toggleLive,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                'Selected follow mode: ${snapshot.followLatestState.name}. If you drag the primary chart far enough left and then append candles, the live-update pill should appear without yanking the viewport.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLive() {
    if (_isLive) {
      _liveTimer?.cancel();
      setState(() {
        _isLive = false;
      });
      return;
    }

    _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _appendNewCandle();
    });
    setState(() {
      _isLive = true;
    });
  }

  void _appendNewCandle() {
    final previous = _controller.candles.last;
    final nextClose = previous.close + ((_random.nextDouble() - 0.5) * 6.0);
    final candle = Candle(
      time: previous.time + 60,
      open: previous.close,
      high: math.max(previous.close, nextClose) + _random.nextDouble() * 1.5,
      low: math.min(previous.close, nextClose) - _random.nextDouble() * 1.5,
      close: nextClose,
    );
    _controller.appendCandle(candle);
  }

  void _updateLastCandle() {
    final last = _controller.candles.last;
    final nextClose = last.close + ((_random.nextDouble() - 0.5) * 3.0);
    final updated = Candle(
      time: last.time,
      open: last.open,
      high: math.max(last.high, nextClose),
      low: math.min(last.low, nextClose),
      close: nextClose,
    );
    _controller.updateLastCandle(updated);
  }

  List<Candle> _buildInitialCandles() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var price = 142.0;

    return List.generate(180, (index) {
      final drift = (_random.nextDouble() - 0.5) * 4.5;
      final open = price;
      final close = price + drift;
      final high = math.max(open, close) + _random.nextDouble() * 2.2;
      final low = math.min(open, close) - _random.nextDouble() * 2.2;
      price = close;

      return Candle(
        time: now - ((180 - index) * 60),
        open: open,
        high: high,
        low: low,
        close: close,
      );
    });
  }
}

/// Decorative chart container used by the controller lab.
class _ChartPanel extends StatelessWidget {
  const _ChartPanel({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D131F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
              border: Border(
                bottom: BorderSide(color: accent.withValues(alpha: 0.18)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Top-right live state badge for the controller lab screen.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge({
    required this.isLive,
  });

  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final accent = isLive ? const Color(0xFF35D48A) : Colors.white54;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B111D).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isLive ? 'Live feed active' : 'Manual control',
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact summary tile used in the lab header.
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sidebar section wrapper for grouping related controller actions.
class _SidebarSection extends StatelessWidget {
  const _SidebarSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        ...children.map(
          (child) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Button tile used in the controller action sidebar.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.subtitle,
    required this.onPressed,
    required this.accent,
  });

  final String label;
  final String subtitle;
  final VoidCallback onPressed;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
