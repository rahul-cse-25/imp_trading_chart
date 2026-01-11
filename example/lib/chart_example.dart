import 'dart:math' as math;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart' show Candle, ImpChart;

/// Simulation modes used to stress-test the chart engine.
///
/// Each mode targets a different numerical domain:
/// - [low]    → extreme precision (very small floating-point values)
/// - [medium] → standard trading ranges
/// - [high]   → very large values (millions to billions)
/// - [mixed]  → worst-case scenario with range switching
enum SimulationMode {
  /// 0.00000000000000000000001 → 0.1
  low,

  /// $0 → $100,000
  medium,

  /// $0 → $1,000,000,000
  high,

  /// Mixed ranges (low + medium + high)
  mixed,
}

/// Main example screen showcasing ImpChart factory constructors.
///
/// This widget demonstrates:
/// - Live OHLC candle generation
/// - Real-time updates
/// - Multiple chart styles via factory methods
/// - Handling of extreme numeric ranges
class ChartExampleScreen extends StatefulWidget {
  const ChartExampleScreen({super.key});

  @override
  State<ChartExampleScreen> createState() => _ChartExampleScreenState();
}

class _ChartExampleScreenState extends State<ChartExampleScreen>
    with SingleTickerProviderStateMixin {
  // ===========================================================================
  // STATE & CONTROLLERS
  // ===========================================================================

  /// Current candle data rendered by the charts
  List<Candle> _candles = [];

  /// Random generator used for deterministic price simulation
  final Random _random = Random();

  /// Currently active simulation mode
  SimulationMode? _simulationMode;

  /// Live update flags (mutually exclusive)
  bool _isLiveLow = false;
  bool _isLiveMedium = false;
  bool _isLiveHigh = false;
  bool _isLiveMixed = false;

  /// Controls the chart-style tabs
  late TabController _tabController;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    /// Four tabs:
    /// Trading | Simple | Compact | Minimal
    _tabController = TabController(length: 4, vsync: this);

    /// Rebuild UI when switching chart style
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    /// ❗ No candles are generated initially
    /// User must explicitly select a simulation mode
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // INITIAL CANDLE GENERATION
  // ===========================================================================

  /// Generates an initial candle set for the selected simulation mode.
  ///
  /// Characteristics:
  /// - Generates exactly **500 candles**
  /// - Uses **percentage-based volatility**
  /// - Produces realistic OHLC relationships
  /// - Uses **integer timestamps only (seconds)**
  void _generateCandlesForMode(SimulationMode mode) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final candles = <Candle>[];

    double minPrice;
    double maxPrice;
    double startPrice;
    double volatilityPercent;

    switch (mode) {
      case SimulationMode.low:
        minPrice = 0.00000000000000000000001;
        maxPrice = 0.1;
        startPrice = 0.01;
        volatilityPercent = 0.05;
        break;

      case SimulationMode.medium:
        minPrice = 0.01;
        maxPrice = 100000.0;
        startPrice = 1000.0;
        volatilityPercent = 0.02;
        break;

      case SimulationMode.high:
        minPrice = 0.01;
        maxPrice = 1000000000.0;
        startPrice = 10000000.0;
        volatilityPercent = 0.015;
        break;

      case SimulationMode.mixed:
        minPrice = 0.00000000000000000000001;
        maxPrice = 1000000000.0;
        startPrice = 100.0;
        volatilityPercent = 0.03;
        break;
    }

    double price = startPrice;
    final bool isMixedMode = mode == SimulationMode.mixed;

    for (int i = 0; i < 500; i++) {
      final time = now - (500 - i) * 60; // 1-minute candles

      /// Mixed mode periodically jumps between ranges
      if (isMixedMode && i > 0 && i % 100 == 0) {
        switch (_random.nextInt(3)) {
          case 0:
            price = _random.nextDouble() * 0.1 + 0.0001;
            break;
          case 1:
            price = _random.nextDouble() * 100000 + 100;
            break;
          case 2:
            price = _random.nextDouble() * 1000000000 + 1000000;
            break;
        }
        price = price.clamp(minPrice, maxPrice * 1.1);
      }

      /// Percentage-based random walk
      final changePercent =
          (_random.nextDouble() - 0.5) * 2 * volatilityPercent;

      final open = price;
      final close =
          (price + price * changePercent).clamp(minPrice, maxPrice * 1.1);

      /// Ensure realistic wick sizes
      final candleRange =
          math.max((close - open).abs(), price * volatilityPercent * 0.5);

      final high =
          math.max(open, close) + _random.nextDouble() * candleRange * 0.5;
      final low =
          math.min(open, close) - _random.nextDouble() * candleRange * 0.5;

      candles.add(Candle(
        time: time,
        open: open,
        high: high,
        low: low,
        close: close,
      ));

      price = close;
    }

    setState(() {
      _candles = candles;
      _simulationMode = mode;
    });
  }

  // ===========================================================================
  // LIVE SIMULATION CONTROL
  // ===========================================================================

  /// Resets chart state and stops all simulations.
  void _resetChart() {
    setState(() {
      _candles = [];
      _simulationMode = null;
      _isLiveLow = false;
      _isLiveMedium = false;
      _isLiveHigh = false;
      _isLiveMixed = false;
    });
  }

  /// Latest candle close price (used by charts & stats bar)
  double? get _currentPrice => _candles.isNotEmpty ? _candles.last.close : null;

  /// Toggles live updates for the selected simulation mode.
  ///
  /// - Ensures only ONE live mode is active
  /// - Generates candles if switching modes
  void _toggleLive(SimulationMode mode) {
    setState(() {
      _isLiveLow = false;
      _isLiveMedium = false;
      _isLiveHigh = false;
      _isLiveMixed = false;

      switch (mode) {
        case SimulationMode.low:
          _isLiveLow = !_isLiveLow;
          break;
        case SimulationMode.medium:
          _isLiveMedium = !_isLiveMedium;
          break;
        case SimulationMode.high:
          _isLiveHigh = !_isLiveHigh;
          break;
        case SimulationMode.mixed:
          _isLiveMixed = !_isLiveMixed;
          break;
      }

      if (_candles.isEmpty || _simulationMode != mode) {
        _generateCandlesForMode(mode);
      }
    });

    final isLive = (mode == SimulationMode.low && _isLiveLow) ||
        (mode == SimulationMode.medium && _isLiveMedium) ||
        (mode == SimulationMode.high && _isLiveHigh);

    if (isLive) {
      _startLiveUpdates(mode);
    }
  }

  /// Performs recursive live price updates.
  ///
  /// Behavior:
  /// - Runs every 500ms
  /// - Updates current candle if timestamp matches
  /// - Creates a new candle otherwise
  /// - Preserves OHLC integrity
  void _startLiveUpdates(SimulationMode mode) {
    Future.delayed(const Duration(milliseconds: 500), () {
      final isLive = (mode == SimulationMode.low && _isLiveLow) ||
          (mode == SimulationMode.medium && _isLiveMedium) ||
          (mode == SimulationMode.high && _isLiveHigh) ||
          (mode == SimulationMode.mixed && _isLiveMixed);

      if (!mounted || !isLive || _candles.isEmpty) return;

      final lastCandle = _candles.last;
      final newTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      setState(() {
        final currentPrice = lastCandle.close;
        double volatilityPercent;
        double maxPrice;

        switch (mode) {
          case SimulationMode.low:
            volatilityPercent = 0.05;
            maxPrice = 0.1;
            break;
          case SimulationMode.medium:
            volatilityPercent = 0.02;
            maxPrice = 100000.0;
            break;
          case SimulationMode.high:
            volatilityPercent = 0.015;
            maxPrice = 1000000000.0;
            break;
          case SimulationMode.mixed:
            if (currentPrice < 1) {
              volatilityPercent = 0.05;
              maxPrice = 0.1;
            } else if (currentPrice < 10000) {
              volatilityPercent = 0.03;
              maxPrice = 100000;
            } else {
              volatilityPercent = 0.02;
              maxPrice = 1000000000;
            }
            break;
        }

        final changePercent =
            (_random.nextDouble() - 0.5) * 2 * volatilityPercent;
        final newPrice = (currentPrice + currentPrice * changePercent).clamp(
          mode == SimulationMode.low || mode == SimulationMode.mixed
              ? 0.00000000000000000000001
              : 0.01,
          maxPrice * 1.1,
        );

        if (lastCandle.time == newTime) {
          _candles[_candles.length - 1] = Candle(
            time: lastCandle.time,
            open: lastCandle.open,
            high: math.max(lastCandle.high, newPrice),
            low: math.min(lastCandle.low, newPrice),
            close: newPrice,
          );
        } else {
          _candles.add(Candle(
            time: newTime,
            open: lastCandle.close,
            high: math.max(lastCandle.close, newPrice),
            low: math.min(lastCandle.close, newPrice),
            close: newPrice,
          ));
        }
      });

      _startLiveUpdates(mode);
    });
  }

  /// Formats a price value for display in the stats bar.
  ///
  /// Uses compact, human-readable notation for large numbers:
  /// - ≥ 1B → Billion (B)
  /// - ≥ 1M → Million (M)
  /// - ≥ 1K → Thousand (K)
  /// - Otherwise → fixed decimal currency
  ///
  /// Examples:
  /// - 1250        → $1.25K
  /// - 2500000     → $2.50M
  /// - 9876543210  → $9.88B
  String _formatPriceForDisplay(double price) {
    final absPrice = price.abs();
    final sign = price < 0 ? '-' : '';

    if (absPrice >= 1e9) {
      return '$sign\$${(absPrice / 1e9).toStringAsFixed(2)}B';
    } else if (absPrice >= 1e6) {
      return '$sign\$${(absPrice / 1e6).toStringAsFixed(2)}M';
    } else if (absPrice >= 1e3) {
      return '$sign\$${(absPrice / 1e3).toStringAsFixed(2)}K';
    } else {
      return '$sign\$${absPrice.toStringAsFixed(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF05070F).withValues(alpha: 0.9),
                const Color(0xFF05070F).withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.hub_outlined, color: Colors.cyan, size: 20),
            SizedBox(width: 10),
            Text(
              'Chart Playground',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F3A).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: BoxDecoration(
                color: Colors.cyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyan.withValues(alpha: 0.5)),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.cyan,
              unselectedLabelColor: Colors.white38,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: const [
                Tab(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      Icon(Icons.candlestick_chart, size: 16),
                      SizedBox(width: 8),
                      Text('Trading')
                    ]),
                  ),
                ),
                Tab(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      Icon(Icons.show_chart, size: 16),
                      SizedBox(width: 8),
                      Text('Simple')
                    ]),
                  ),
                ),
                Tab(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      Icon(Icons.compress, size: 16),
                      SizedBox(width: 8),
                      Text('Compact')
                    ]),
                  ),
                ),
                Tab(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      Icon(Icons.minimize, size: 16),
                      SizedBox(width: 8),
                      Text('Minimal')
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (_isLiveLow || _isLiveMedium || _isLiveHigh || _isLiveMixed)
            Container(
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'LIVE ${_getModeLabel()}',
                    style: const TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Color(0xFF10142C),
              Color(0xFF05070F),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ---------------------------------------------------------------------
              // STATS BAR (LIVE METRICS)
              // ---------------------------------------------------------------------
              _buildStatsBar(),

              // ---------------------------------------------------------------------
              // SIMULATION CONTROLS PANEL
              // ---------------------------------------------------------------------
              _buildControlPanel(),

              // ---------------------------------------------------------------------
              // CHART CONTENT AREA
              // ---------------------------------------------------------------------
              Expanded(
                child: _candles.isEmpty
                    ? _buildEmptyState()
                    : Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildTradingChart(),
                            _buildSimpleChart(),
                            _buildCompactChart(),
                            _buildMinimalChart(),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      width: double.maxFinite,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatItem(
              icon: Icons.candlestick_chart,
              label: 'SAMPLES',
              value: '${_candles.length}',
              color: Colors.cyan,
            ),
            _buildStatDivider(),
            _buildStatItem(
              icon: Icons.attach_money,
              label: 'PRICE',
              value: _currentPrice != null
                  ? _formatPriceForDisplay(_currentPrice!)
                  : '---',
              color: Colors.white,
            ),
            if (_candles.isNotEmpty) ...[
              _buildStatDivider(),
              _buildStatItem(
                icon: Icons.arrow_upward,
                label: 'HIGH',
                value: _formatPriceForDisplay(_candles.last.high),
                color: const Color(0xFF00D084),
              ),
              _buildStatDivider(),
              _buildStatItem(
                icon: Icons.arrow_downward,
                label: 'LOW',
                value: _formatPriceForDisplay(_candles.last.low),
                color: const Color(0xFFFF6B6B),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 20,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'SIMULATION MODE',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildSimulationButton(
                  'Micro',
                  'Precision',
                  SimulationMode.low,
                  const Color(0xFF667EEA),
                  _isLiveLow,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSimulationButton(
                  'Standard',
                  'Trading',
                  SimulationMode.medium,
                  const Color(0xFF00D084),
                  _isLiveMedium,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSimulationButton(
                  'Macro',
                  'Billions',
                  SimulationMode.high,
                  const Color(0xFFFFA44C),
                  _isLiveHigh,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSimulationButton(
                  'Chaos',
                  'Mixed',
                  SimulationMode.mixed,
                  const Color(0xFFFF6B6B),
                  _isLiveMixed,
                ),
              ),
              const SizedBox(width: 8),
              _buildResetButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3A).withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a Mode',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'to start simulation',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the active simulation mode label for the LIVE indicator.
  String _getModeLabel() {
    if (_isLiveLow) return 'LOW';
    if (_isLiveMedium) return 'MED';
    if (_isLiveHigh) return 'HIGH';
    if (_isLiveMixed) return 'MIX';
    return '';
  }

  Widget _buildSimulationButton(
    String title,
    String subtitle,
    SimulationMode mode,
    Color color,
    bool isActive,
  ) {
    final isSelected = _simulationMode == mode;
    final isLive = (mode == SimulationMode.low && _isLiveLow) ||
        (mode == SimulationMode.medium && _isLiveMedium) ||
        (mode == SimulationMode.high && _isLiveHigh) ||
        (mode == SimulationMode.mixed && _isLiveMixed);

    return InkWell(
      onTap: () => _toggleLive(mode),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isLive
              ? color.withValues(alpha: 0.2)
              : (isSelected
                  ? color.withValues(alpha: 0.1)
                  : const Color(0xFF1A1F3A).withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLive
                ? color
                : (isSelected
                    ? color.withValues(alpha: 0.3)
                    : Colors.transparent),
            width: isLive ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLive
                  ? Icons.pause_circle_filled
                  : (isSelected
                      ? Icons.play_circle_outline
                      : Icons.radio_button_unchecked),
              color: isLive ? color : (isSelected ? color : Colors.white24),
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isLive || isSelected ? Colors.white : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: (isLive || isSelected ? Colors.white : Colors.white54)
                    .withValues(alpha: 0.5),
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return InkWell(
      onTap: _resetChart,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3A).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.refresh_rounded,
              color: Colors.white54,
              size: 20,
            ),
            SizedBox(height: 6),
            Text(
              'Reset',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              ' ',
              style: TextStyle(fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, color: color.withValues(alpha: 0.7), size: 10),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildTradingChart() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F11),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.cyan.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withValues(alpha: 0.05),
            blurRadius: 40,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.cyan.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.cyan.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.candlestick_chart,
                      color: Colors.cyan, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'PRO TRADER VIEW',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'M1',
                      style: TextStyle(
                        color: Colors.cyan,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ImpChart.trading(
                candles: _candles,
                currentPrice: _currentPrice,
                showCrosshair: true,
                defaultVisibleCount: 200,
              ),
            ),
            const SizedBox(
              height: 10,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleChart() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F11),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00D084).withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D084).withValues(alpha: 0.05),
            blurRadius: 40,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF00D084).withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF00D084).withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.show_chart,
                      color: Color(0xFF00D084), size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'SIMPLE LINE',
                    style: TextStyle(
                      color: Color(0xFF00D084),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: ImpChart.simple(
                candles: _candles,
                currentPrice: _currentPrice,
                lineColor: const Color(0xFF00D084),
              ),
            ),
            const SizedBox(
              height: 10,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCompactChart() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F11),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFA44C).withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA44C).withValues(alpha: 0.05),
            blurRadius: 40,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA44C).withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFFFA44C).withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.compress,
                      color: Color(0xFFFFA44C), size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'COMPACT OVERVIEW',
                    style: TextStyle(
                      color: Color(0xFFFFA44C),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ImpChart.compact(
                candles: _candles,
                currentPrice: _currentPrice,
                lineColor: const Color(0xFFFFA44C),
                defaultVisibleCount: 75,
              ),
            ),
            const SizedBox(
              height: 10,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalChart() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F11),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.05),
            blurRadius: 40,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.minimize,
                      color: Color(0xFFFF6B6B), size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'MINIMAL SPARK',
                    style: TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ImpChart.minimal(
                candles: _candles,
                defaultVisibleCount: 50,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
