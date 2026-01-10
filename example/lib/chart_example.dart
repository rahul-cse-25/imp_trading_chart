import 'dart:math' as math;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart'
    show Candle, dummy, parseCandlesFromPayload, ImpChart;

class ChartExampleScreen extends StatefulWidget {
  const ChartExampleScreen({super.key});

  @override
  State<ChartExampleScreen> createState() => _ChartExampleScreenState();
}

enum SimulationMode {
  low, // 0.00000000000000000000001 - 0.1
  medium, // $0 - $100K
  high, // $0 - $1B
  mixed, // Mixed: any type of data (very low, normal, extreme high)
}

class _ChartExampleScreenState extends State<ChartExampleScreen>
    with SingleTickerProviderStateMixin {
  List<Candle> _candles = [];
  final Random _random = Random();
  SimulationMode? _simulationMode;
  bool _isLiveLow = false;
  bool _isLiveMedium = false;
  bool _isLiveHigh = false;
  bool _isLiveMixed = false;
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    // Don't generate initial candles - start empty
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _generateCandlesForMode(SimulationMode mode) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final candles = <Candle>[];

    // Generate 500 candles based on simulation mode
    double maxPrice;
    double startPrice;
    double volatilityPercent;
    double minPrice;

    switch (mode) {
      case SimulationMode.low:
        minPrice = 0.00000000000000000000001; // Very small starting point
        maxPrice = 0.1;
        startPrice = 0.01; // Start at 0.01 (1 cent equivalent)
        volatilityPercent = 0.05; // 5% volatility for small values
        break;
      case SimulationMode.medium:
        minPrice = 0.01;
        maxPrice = 100000.0; // $100K
        startPrice = 1000.0;
        volatilityPercent = 0.02; // 2% volatility
        break;
      case SimulationMode.high:
        minPrice = 0.01;
        maxPrice = 1000000000.0; // $1B
        startPrice = 10000000.0; // $10M
        volatilityPercent = 0.015; // 1.5% volatility
        break;
      case SimulationMode.mixed:
        // Mixed mode: randomly switches between low, medium, and high ranges
        minPrice = 0.00000000000000000000001;
        maxPrice = 1000000000.0; // Can go up to $1B
        startPrice = 100.0; // Start in middle range
        volatilityPercent = 0.03; // Moderate volatility
        break;
    }

    double price = startPrice;

    // For mixed mode, we'll randomly jump between different ranges
    bool inMixedMode = mode == SimulationMode.mixed;

    for (int i = 0; i < 500; i++) {
      final time = now - (500 - i) * 60; // 1 minute intervals

      // For mixed mode, occasionally jump to a different price range
      if (inMixedMode && i > 0 && i % 100 == 0) {
        final segment = _random.nextInt(3);
        switch (segment) {
          case 0: // Low range
            price = _random.nextDouble() * 0.1 + 0.0001;
            break;
          case 1: // Medium range
            price = _random.nextDouble() * 100000.0 + 100.0;
            break;
          case 2: // High range
            price = _random.nextDouble() * 1000000000.0 + 1000000.0;
            break;
        }
        price = price.clamp(minPrice, maxPrice * 1.1);
      }

      // Random walk with percentage-based volatility
      final changePercent =
          (_random.nextDouble() - 0.5) * 2.0 * volatilityPercent;
      final change = price * changePercent;

      final open = price;
      final close = (price + change).clamp(minPrice, maxPrice * 1.1);

      // Generate realistic high/low that are above/below open and close
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

  /// Load dummy data from candle.dart and display it in the chart
  void _loadDummyData() {
    try {
      debugPrint('Starting to load dummy data...');

      // Cast dummy to proper type for access
      final dummyMap = dummy as Map<String, dynamic>;

      // Verify dummy data structure
      if (dummyMap['data'] == null ||
          (dummyMap['data'] as Map<String, dynamic>)['chart_data'] == null) {
        debugPrint(
            'Error: Dummy data structure is invalid - missing data.chart_data');
        return;
      }

      final chartDataList =
          (dummyMap['data'] as Map<String, dynamic>)['chart_data'] as List;
      debugPrint('Found ${chartDataList.length} items in chart_data');

      if (chartDataList.isEmpty) {
        debugPrint('Warning: chart_data is empty');
        return;
      }

      // Parse the dummy data payload into List<Candle>
      final candles = parseCandlesFromPayload(dummyMap);

      // Validate that we got candles
      if (candles.isEmpty) {
        debugPrint('Warning: Dummy data parsed but resulted in empty list');
        return;
      }

      // Sort candles by time (ascending) to ensure proper chart rendering
      // Charts expect data to be sorted chronologically
      final sortedCandles = List<Candle>.from(candles)
        ..sort((a, b) => a.time.compareTo(b.time));

      debugPrint(
          '✓ Successfully loaded ${sortedCandles.length} candles from dummy data');
      debugPrint(
          '  First candle: time=${sortedCandles.first.time}, close=${sortedCandles.first.close}');
      debugPrint(
          '  Last candle: time=${sortedCandles.last.time}, close=${sortedCandles.last.close}');

      final minPrice =
          sortedCandles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
      final maxPrice =
          sortedCandles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
      debugPrint('  Price range: $minPrice - $maxPrice');

      setState(() {
        _candles = sortedCandles;
        _simulationMode = null; // Clear simulation mode since this is real data
        // Stop any live updates
        _isLiveLow = false;
        _isLiveMedium = false;
        _isLiveHigh = false;
        _isLiveMixed = false;
      });
    } catch (e, stackTrace) {
      // Handle any parsing errors gracefully with full error details
      debugPrint('✗ Error loading dummy data: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  double? get _currentPrice => _candles.isNotEmpty ? _candles.last.close : null;

  void _toggleLive(SimulationMode mode) {
    setState(() {
      // Turn off all other live modes
      _isLiveLow = false;
      _isLiveMedium = false;
      _isLiveHigh = false;
      _isLiveMixed = false;

      // Toggle the selected mode
      switch (mode) {
        case SimulationMode.low:
          _isLiveLow = !_isLiveLow;
          if (_candles.isEmpty || _simulationMode != mode) {
            _generateCandlesForMode(mode);
          }
          break;
        case SimulationMode.medium:
          _isLiveMedium = !_isLiveMedium;
          if (_candles.isEmpty || _simulationMode != mode) {
            _generateCandlesForMode(mode);
          }
          break;
        case SimulationMode.high:
          _isLiveHigh = !_isLiveHigh;
          if (_candles.isEmpty || _simulationMode != mode) {
            _generateCandlesForMode(mode);
          }
          break;
        case SimulationMode.mixed:
          _isLiveMixed = !_isLiveMixed;
          if (_candles.isEmpty || _simulationMode != mode) {
            _generateCandlesForMode(mode);
          }
          break;
      }
    });

    final isLive = (mode == SimulationMode.low && _isLiveLow) ||
        (mode == SimulationMode.medium && _isLiveMedium) ||
        (mode == SimulationMode.high && _isLiveHigh);

    if (isLive) {
      _startLiveUpdates(mode);
    }
  }

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
            // Mixed mode uses adaptive volatility based on current price
            if (currentPrice < 1.0) {
              volatilityPercent = 0.05; // High volatility for small values
              maxPrice = 0.1;
            } else if (currentPrice < 10000.0) {
              volatilityPercent = 0.03; // Moderate volatility for medium values
              maxPrice = 100000.0;
            } else {
              volatilityPercent = 0.02; // Lower volatility for large values
              maxPrice = 1000000000.0;
            }
            break;
        }

        final changePercent =
            (_random.nextDouble() - 0.5) * 2.0 * volatilityPercent;
        final priceChange = currentPrice * changePercent;
        double minPriceValue =
            mode == SimulationMode.low || mode == SimulationMode.mixed
                ? 0.00000000000000000000001
                : 0.01;
        final newPrice =
            (currentPrice + priceChange).clamp(minPriceValue, maxPrice * 1.1);

        // For mixed mode, occasionally jump to a completely different range
        if (mode == SimulationMode.mixed && _random.nextDouble() < 0.02) {
          // 2% chance
          final segment = _random.nextInt(3);
          double jumpPrice;
          switch (segment) {
            case 0: // Jump to low range
              jumpPrice = _random.nextDouble() * 0.09 + 0.001;
              break;
            case 1: // Jump to medium range
              jumpPrice = _random.nextDouble() * 90000.0 + 100.0;
              break;
            case 2: // Jump to high range
              jumpPrice = _random.nextDouble() * 900000000.0 + 1000000.0;
              break;
            default:
              jumpPrice = newPrice;
          }
          // Use the jump price if it's significantly different
          if ((jumpPrice - newPrice).abs() / math.max(newPrice, 1.0) > 0.5) {
            // Keep using newPrice but this gives us the option to jump in future updates
          }
        }

        if (lastCandle.time == newTime) {
          // Update existing candle - properly update high/low
          final updatedHigh = math.max(lastCandle.high, newPrice);
          final updatedLow = math.min(lastCandle.low, newPrice);

          _candles[_candles.length - 1] = Candle(
            time: lastCandle.time,
            open: lastCandle.open,
            high: updatedHigh,
            low: updatedLow,
            close: newPrice,
          );
        } else {
          // New candle - create with proper high/low
          final candleRange = math.max((newPrice - lastCandle.close).abs(),
              currentPrice * volatilityPercent * 0.5);
          final high = math.max(lastCandle.close, newPrice) +
              _random.nextDouble() * candleRange * 0.3;
          final low = math.min(lastCandle.close, newPrice) -
              _random.nextDouble() * candleRange * 0.3;

          _candles.add(Candle(
            time: newTime,
            open: lastCandle.close,
            high: high,
            low: low,
            close: newPrice,
          ));
        }
      });

      if (isLive) {
        _startLiveUpdates(mode);
      }
    });
  }

  /// Format price for display in stats bar (uses compact format for large values)
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
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text(
          'Chart Factory Methods',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1F3A),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.cyan,
          labelColor: Colors.cyan,
          unselectedLabelColor: Colors.white54,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: '🎯 Trading'),
            Tab(text: '📊 Simple'),
            Tab(text: '📦 Compact'),
            Tab(text: '⚡ Minimal'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Simulation Controls Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F3A),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Simulation Controls',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSimulationButton(
                        'Low Range\n0.000...01 - 0.1',
                        SimulationMode.low,
                        Colors.blue,
                        _isLiveLow,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSimulationButton(
                        'Medium\n\$0 - \$100K',
                        SimulationMode.medium,
                        Colors.green,
                        _isLiveMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSimulationButton(
                        'High Range\n\$0 - \$1B',
                        SimulationMode.high,
                        Colors.orange,
                        _isLiveHigh,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSimulationButton(
                        'Mixed\nAny Type',
                        SimulationMode.mixed,
                        Colors.purple,
                        _isLiveMixed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      spacing: 8,
                      children: [
                        GestureDetector(
                          onTap: _loadDummyData,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.new_releases_outlined,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                        ),
                        _buildResetButton(),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F3A),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatItem(
                          icon: Icons.candlestick_chart,
                          label: 'Candles',
                          value: '${_candles.length}',
                          color: Colors.cyan,
                        ),
                        const SizedBox(width: 20),
                        _buildStatItem(
                          icon: Icons.trending_up,
                          label: 'Price',
                          value: _currentPrice != null
                              ? _formatPriceForDisplay(_currentPrice!)
                              : 'N/A',
                          color: Colors.green,
                        ),
                        if (_candles.isNotEmpty) ...[
                          const SizedBox(width: 20),
                          _buildStatItem(
                            icon: Icons.arrow_upward,
                            label: 'High',
                            value: _formatPriceForDisplay(_candles.last.high),
                            color: Colors.green,
                          ),
                          const SizedBox(width: 20),
                          _buildStatItem(
                            icon: Icons.arrow_downward,
                            label: 'Low',
                            value: _formatPriceForDisplay(_candles.last.low),
                            color: Colors.red,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_isLiveLow || _isLiveMedium || _isLiveHigh || _isLiveMixed)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE ${_getModeLabel()}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Chart Content
          Expanded(
            child: _candles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a simulation mode to start',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose Low, Medium, or High range simulation',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTradingChart(),
                      _buildSimpleChart(),
                      _buildCompactChart(),
                      _buildMinimalChart(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _getModeLabel() {
    if (_isLiveLow) return 'LOW';
    if (_isLiveMedium) return 'MEDIUM';
    if (_isLiveHigh) return 'HIGH';
    if (_isLiveMixed) return 'MIXED';
    return '';
  }

  Widget _buildSimulationButton(
      String label, SimulationMode mode, Color color, bool isActive) {
    final isLive = (mode == SimulationMode.low && _isLiveLow) ||
        (mode == SimulationMode.medium && _isLiveMedium) ||
        (mode == SimulationMode.high && _isLiveHigh);

    return InkWell(
      onTap: () => _toggleLive(mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isLive
              ? color.withValues(alpha: 0.3)
              : (_simulationMode == mode
                  ? color.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLive ? color : color.withValues(alpha: 0.3),
            width: isLive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLive ? Icons.pause_circle : Icons.play_circle,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isLive ? color : Colors.white70,
                fontSize: 11,
                fontWeight: isLive ? FontWeight.bold : FontWeight.normal,
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.refresh,
          color: Colors.red,
          size: 24,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 9,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTradingChart() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F11),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_graph, color: Colors.cyan, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Trading Chart',
                        style: TextStyle(
                          color: Colors.cyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Text(
                  'Full-featured with all bells & whistles',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
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
        ],
      ),
    );
  }

  Widget _buildSimpleChart() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F11),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.green.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.show_chart, color: Colors.green, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Simple Chart',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Text(
                  'Basic chart with labels',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          Expanded(
            child: ImpChart.simple(
              candles: _candles,
              currentPrice: _currentPrice,
              lineColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactChart() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F11),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.compress, color: Colors.orange, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Compact Chart',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Text(
                  'Perfect for dashboards',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          Expanded(
            child: ImpChart.compact(
              candles: _candles,
              currentPrice: _currentPrice,
              lineColor: Colors.orange,
              defaultVisibleCount: 75,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalChart() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F11),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pink.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.pink.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.minimize, color: Colors.pink, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Minimal Chart',
                        style: TextStyle(
                          color: Colors.pink,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Text(
                  'Ultra-minimal, just the line',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
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
    );
  }
}
