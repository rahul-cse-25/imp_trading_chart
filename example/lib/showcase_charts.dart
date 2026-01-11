import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SHOWCASE EXAMPLE 1: NEON CYBERPUNK THEME
/// ═══════════════════════════════════════════════════════════════════════════
///
/// A futuristic, cyberpunk-inspired trading chart with:
/// - Electric neon glow effects
/// - Dark gradient backgrounds
/// - Cyan/Magenta color accents
/// - Smooth curves with pulsing animation
class NeonCyberpunkChart extends StatelessWidget {
  const NeonCyberpunkChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D0D1A),
            const Color(0xFF1A0A2E),
            const Color(0xFF0D0D1A),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00FFFF).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FFFF).withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: -5,
          ),
          BoxShadow(
            color: const Color(0xFFFF00FF).withValues(alpha: 0.1),
            blurRadius: 60,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FFFF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF00FFFF).withValues(alpha: 0.8),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'CYBER//FLUX',
                      style: TextStyle(
                        color: Color(0xFF00FFFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 6,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00FFFF).withValues(alpha: 0.2),
                            const Color(0xFFFF00FF).withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF00FFFF).withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Text(
                        '+24.7%',
                        style: TextStyle(
                          color: Color(0xFF00FFFF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF00FFFF), Color(0xFFFF00FF)],
                  ).createShader(bounds),
                  child: const Text(
                    '\$2,847.93',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Chart
          Expanded(
            child: ImpChart(
              candles: _generateVolatileData(75),
              style: ChartStyle(
                backgroundColor: Colors.transparent,
                lineStyle: const LineChartStyle(
                  color: Color(0xFF00FFFF),
                  width: 2.5,
                  smooth: true,
                  curveTension: 0.8,
                  showGlow: true,
                  glowWidth: 2,
                ),
                currentPriceStyle: CurrentPriceIndicatorStyle.dotted(
                  lineColor: const Color(0xFFFF00FF),
                  bullishColor: const Color(0xFF00FFFF),
                  bearishColor: const Color(0xFFFF00FF),
                ).copyWith(labelFontSize: 11),
                rippleStyle: RippleAnimationStyle.prominent(
                    color: const Color(0xFF00FFFF)),
                priceLabelStyle: const PriceLabelStyle(
                  show: true,
                  color: Color(0xFF00FFFF),
                  fontSize: 10,
                ),
                timeLabelStyle: const TimeLabelStyle(
                  show: true,
                  color: Color(0xFFFF00FF),
                  fontSize: 10,
                ),
                axisStyle: AxisStyle(showGrid: false),
                crosshairStyle: CrosshairStyle.dotted(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// SHOWCASE EXAMPLE 2: MINIMAL GLASSMORPHISM
/// ═══════════════════════════════════════════════════════════════════════════
///
/// A clean, modern glassmorphism design with:
/// - Frosted glass effect
/// - Subtle gradients
/// - Minimal UI elements
/// - Elegant typography
class GlassmorphismChart extends StatelessWidget {
  const GlassmorphismChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667EEA).withValues(alpha: 0.8),
            const Color(0xFF764BA2).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.25),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Portfolio Value',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '\$128,459.00',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_upward_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          '12.4%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Chart container with glass effect
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  // padding: const EdgeInsets.all(12),
                  child: ImpChart(
                    candles: _generateSmoothData(35),
                    style: ChartStyle.minimal(
                      backgroundColor: Colors.transparent,
                      lineColor: Colors.white,
                      lineWidth: 2.5,
                      showLineGlow: true,
                    ).copyWith(
                      lineStyle: const LineChartStyle(
                        color: Colors.white,
                        width: 2.5,
                        smooth: true,
                        curveTension: 1.0,
                        showGlow: true,
                        glowWidth: 3,
                      ),
                      rippleStyle: const RippleAnimationStyle(
                        color: Colors.white,
                        maxRadius: 24,
                        show: true,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Bottom stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildGlassStat('24h High', '\$132,400'),
                  Container(
                      height: 30,
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.2)),
                  _buildGlassStat('24h Low', '\$125,200'),
                  Container(
                      height: 30,
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.2)),
                  _buildGlassStat('Volume', '2.4M'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// SHOWCASE EXAMPLE 3: AURORA BOREALIS THEME
/// ═══════════════════════════════════════════════════════════════════════════
///
/// An ethereal, nature-inspired design with:
/// - Aurora color gradients
/// - Dark starry background
/// - Organic flowing line
/// - Mystical atmosphere
class AuroraBorealisChart extends StatelessWidget {
  const AuroraBorealisChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B1426),
            Color(0xFF0D2137),
            Color(0xFF0B1426),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00FF88).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Simulated stars background
          ...List.generate(20, (index) {
            final random = math.Random(index);
            return Positioned(
              left: random.nextDouble() * 350,
              top: random.nextDouble() * 250,
              child: Container(
                width: random.nextDouble() * 2 + 1,
                height: random.nextDouble() * 2 + 1,
                decoration: BoxDecoration(
                  color: Colors.white
                      .withValues(alpha: random.nextDouble() * 0.5 + 0.2),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
          // Aurora glow at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 150,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF00FF88).withValues(alpha: 0.15),
                    const Color(0xFF00BFFF).withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF00FF88), Color(0xFF00BFFF)],
                          ).createShader(bounds),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'AURORA ASSET',
                          style: TextStyle(
                            color: Color(0xFF00FF88),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF00FF88),
                          Color(0xFF00BFFF),
                          Color(0xFFAA88FF)
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        '\$9,847.32',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF00FF88).withValues(alpha: 0.3),
                                const Color(0xFF00BFFF).withValues(alpha: 0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '↑ +5.82%',
                            style: TextStyle(
                              color: Color(0xFF00FF88),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Past 7 days',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              // Chart
              Expanded(
                child: ImpChart(
                  candles: _generateWavyData(100),
                  defaultVisibleCount: 10,
                  style: ChartStyle(
                      backgroundColor: Colors.transparent,
                      lineStyle: const LineChartStyle(
                        color: Color(0xFF00FF88),
                        width: 3,
                        smooth: true,
                        curveTension: 0.7,
                        showGlow: false,
                        // showPoints: true,
                        // pointRadius: 5
                      ),
                      currentPriceStyle: CurrentPriceIndicatorStyle.dashed(
                        lineColor: const Color(0xFF00BFFF),
                        bullishColor: const Color(0xFF00FF88),
                        bearishColor: const Color(0xFFFF6B6B),
                      ).copyWith(labelFontSize: 10),
                      rippleStyle: const RippleAnimationStyle(
                        color: Color(0xFF00FF88),
                        maxRadius: 30,
                        show: true,
                      ),
                      priceLabelStyle: const PriceLabelStyle(
                        show: true,
                        color: Color(0xFF00BFFF),
                        fontSize: 10,
                      ),
                      timeLabelStyle: TimeLabelStyle(
                        show: true,
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                      axisStyle: AxisStyle(
                        showGrid: true,
                        gridColor:
                            const Color(0xFF00FF88).withValues(alpha: 0.08),
                      ),
                      crosshairStyle: const CrosshairStyle(show: false)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// SHOWCASE EXAMPLE 4: SUNSET GRADIENT THEME
/// ═══════════════════════════════════════════════════════════════════════════
///
/// A warm, sunset-inspired design with:
/// - Orange to purple gradient
/// - Warm color palette
/// - Neumorphic elements
/// - Soft shadows
class SunsetGradientChart extends StatelessWidget {
  const SunsetGradientChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B35),
            Color(0xFFFF8E72),
            Color(0xFFE84A5F),
            Color(0xFF6C2478),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE84A5F).withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.currency_bitcoin,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Bitcoin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BTC',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '\$67,234.89',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.show_chart,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        '+8.34%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Chart
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(4),
                child: ImpChart(
                  candles: _generateTrendingData(20),
                  style: ChartStyle(
                    backgroundColor: Colors.transparent,
                    lineStyle: const LineChartStyle(
                      color: Colors.white,
                      width: 3,
                      smooth: true,
                      curveTension: 0.6,
                      showGlow: true,
                      glowWidth: 5,
                    ),
                    currentPriceStyle: CurrentPriceIndicatorStyle.hidden(),
                    rippleStyle: const RippleAnimationStyle(
                      color: Colors.white,
                      maxRadius: 16,
                      show: true,
                    ),
                    priceLabelStyle: const PriceLabelStyle(
                      show: true,
                      color: Color.fromRGBO(255, 255, 255, 0.9),
                      fontSize: 10,
                    ),
                    timeLabelStyle: const TimeLabelStyle(
                      show: true,
                      color: Color.fromRGBO(255, 255, 255, 0.7),
                      fontSize: 10,
                    ),
                    axisStyle: const AxisStyle(
                      showGrid: true,
                      gridColor: Color.fromRGBO(255, 255, 255, 0.1),
                    ),
                    crosshairStyle: const CrosshairStyle(
                      show: true,
                      // lineColor: Colors.white.withValues(alpha: 0.6),
                      labelBackgroundColor: Colors.white,
                      labelTextColor: Color(0xFFE84A5F),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Time period selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPeriodButton('1H', false),
                _buildPeriodButton('24H', false),
                _buildPeriodButton('7D', true),
                _buildPeriodButton('1M', false),
                _buildPeriodButton('1Y', false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String text, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: isSelected ? 1 : 0.6),
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// SHOWCASE EXAMPLE 5: DARK PROFESSIONAL TRADING
/// ═══════════════════════════════════════════════════════════════════════════
///
/// A professional trading platform interface with:
/// - Bloomberg-style dark theme
/// - Rich data displays
/// - Multiple indicators
/// - Professional aesthetics
class DarkProfessionalChart extends StatelessWidget {
  const DarkProfessionalChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF14141F),
            Color(0xFF0E0E16),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A3E)),
      ),
      child: Column(
        children: [
          // Top bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: const Color(0xFF2A2A3E)),
              ),
            ),
            child: Row(
              children: [
                // Trading pair
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFA44C), Color(0xFFFF6B4C)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('E',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ETH/USDT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Ethereum',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // Price info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '\$3,421.67',
                      style: TextStyle(
                        color: Color(0xFF00D084),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF00D084).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '+2.45%',
                            style: TextStyle(
                              color: Color(0xFF00D084),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '24h',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A28),
              border: Border(
                bottom: BorderSide(color: const Color(0xFF2A2A3E)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                    '24h High', '\$3,512.40', const Color(0xFF00D084)),
                _buildStatItem(
                    '24h Low', '\$3,298.20', const Color(0xFFFF6B6B)),
                _buildStatItem(
                    'Volume', '892.4K', Colors.white.withValues(alpha: 0.8)),
                _buildStatItem('Market Cap', '\$411.2B',
                    Colors.white.withValues(alpha: 0.8)),
              ],
            ),
          ),
          // Chart
          Expanded(
            child: ImpChart(
              defaultVisibleCount: 30,
              candles: _generateProfessionalData(25),
              style: ChartStyle.trading(
                backgroundColor: Colors.transparent,
                lineColor: const Color(0xFF00D084),
                pulseColor: const Color(0xFF00D084),
                showCrosshair: true,
              ).copyWith(
                lineStyle: const LineChartStyle(
                  color: Color(0xFF00D084),
                  width: 3,
                  smooth: false,
                  showGlow: false,
                ),
                currentPriceStyle: CurrentPriceIndicatorStyle.dashed(
                  lineColor: const Color(0xFF00D084),
                  bullishColor: const Color(0xFF00D084),
                  bearishColor: const Color(0xFFFF6B6B),
                ).copyWith(
                  labelFontSize: 10,
                  // labelBackgroundColor: const Color(0xFF00D084),
                  // labelTextColor: Colors.white,
                ),
                rippleStyle: const RippleAnimationStyle(
                  color: Color(0xFF00D084),
                  maxRadius: 12,
                  show: true,
                ),
                priceLabelStyle: PriceLabelStyle(
                  show: true,
                  color: const Color.fromRGBO(255, 255, 255, 0.6),
                  fontSize: 10,
                  labelCount: 6,
                ),
                timeLabelStyle: TimeLabelStyle(
                  show: true,
                  color: const Color.fromRGBO(255, 255, 255, 0.5),
                  fontSize: 10,
                  labelCount: 5,
                ),
                axisStyle: AxisStyle(
                  showGrid: true,
                  gridColor: const Color(0xFF2A2A3E),
                  gridLineWidth: 0.5,
                  horizontalGridLines: 6,
                ),
                crosshairStyle: CrosshairStyle.dashed(
                  lineColor: Colors.white.withValues(alpha: 0.5),
                ).copyWith(
                  labelBackgroundColor: const Color(0xFF2A2A3E),
                  labelTextColor: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          )
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA GENERATORS
// ═══════════════════════════════════════════════════════════════════════════

/// Generate volatile/noisy data for cyberpunk theme
List<Candle> _generateVolatileData(int count) {
  final random = math.Random(42);
  final now = DateTime.now();
  double price = 2500 + random.nextDouble() * 500;

  return List.generate(count, (i) {
    final volatility = 20 + random.nextDouble() * 60;
    final direction = random.nextBool() ? 1 : -1;
    price += direction * random.nextDouble() * volatility;
    price = price.clamp(2200.0, 3200.0);

    final open = price;
    final close = price + (random.nextDouble() - 0.5) * 30;
    final high = math.max(open, close) + random.nextDouble() * 15;
    final low = math.min(open, close) - random.nextDouble() * 15;

    return Candle(
      time: _unixSeconds(now.subtract(Duration(hours: count - i))),
      open: open,
      high: high,
      low: low,
      close: close,
    );
  });
}

/// Generate smooth uptrend data for glassmorphism theme
List<Candle> _generateSmoothData(int count) {
  final random = math.Random(123);
  final now = DateTime.now();
  double price = 120000;

  return List.generate(count, (i) {
    final trend = math.sin(i / 10) * 2000 + i * 50;
    price = 120000 + trend + (random.nextDouble() - 0.3) * 1500;

    final open = price;
    final close = price + (random.nextDouble() - 0.4) * 500;
    final high = math.max(open, close) + random.nextDouble() * 300;
    final low = math.min(open, close) - random.nextDouble() * 200;

    return Candle(
      time: _unixSeconds(now.subtract(Duration(days: count - i))),
      open: open,
      high: high,
      low: low,
      close: close,
    );
  });
}

/// Generate wavy organic data for aurora theme
List<Candle> _generateWavyData(int count) {
  final random = math.Random(789);
  final now = DateTime.now();

  return List.generate(count, (i) {
    final wave1 = math.sin(i / 8) * 500;
    final wave2 = math.cos(i / 15) * 300;
    final noise = (random.nextDouble() - 0.5) * 200;
    final price = 9500 + wave1 + wave2 + noise;

    final open = price;
    final close = price + (random.nextDouble() - 0.45) * 100;
    final high = math.max(open, close) + random.nextDouble() * 50;
    final low = math.min(open, close) - random.nextDouble() * 50;

    return Candle(
      time: _unixSeconds(now.subtract(Duration(hours: (count - i) * 4))),
      open: open,
      high: high,
      low: low,
      close: close,
    );
  });
}

/// Generate trending bullish data for sunset theme
List<Candle> _generateTrendingData(int count) {
  final random = math.Random(456);
  final now = DateTime.now();
  double price = 60000;

  return List.generate(count, (i) {
    final trend = i * 130;
    final volatility = (random.nextDouble() - 0.3) * 800;
    price = 60000 + trend + volatility;

    final open = price;
    final close = price + (random.nextDouble() - 0.35) * 400;
    final high = math.max(open, close) + random.nextDouble() * 250;
    final low = math.min(open, close) - random.nextDouble() * 200;

    return Candle(
      time: _unixSeconds(now.subtract(Duration(hours: (count - i) * 6))),
      open: open,
      high: high,
      low: low,
      close: close,
    );
  });
}

/// Generate professional realistic data for trading theme
List<Candle> _generateProfessionalData(int count) {
  final random = math.Random(999);
  final now = DateTime.now();
  double price = 3300;

  return List.generate(count, (i) {
    final momentum = math.sin(i / 20) * 0.02;
    final noise = (random.nextDouble() - 0.5) * 0.015;
    final change = 1 + momentum + noise;
    price *= change;
    price = price.clamp(3100.0, 3600.0);

    final open = price;
    final close = price * (1 + (random.nextDouble() - 0.5) * 0.01);
    final high = math.max(open, close) * (1 + random.nextDouble() * 0.005);
    final low = math.min(open, close) * (1 - random.nextDouble() * 0.005);

    return Candle(
      time: _unixSeconds(now.subtract(Duration(minutes: (count - i) * 15))),
      open: open,
      high: high,
      low: low,
      close: close,
    );
  });
}

int _unixSeconds(DateTime time) => time.millisecondsSinceEpoch ~/ 1000;
