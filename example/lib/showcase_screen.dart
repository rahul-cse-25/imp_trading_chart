import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'showcase_charts.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CHART SHOWCASE SCREEN
/// ═══════════════════════════════════════════════════════════════════════════
///
/// A stunning gallery displaying all 5 chart variations with:
/// - Smooth page transitions
/// - Interactive dot indicators
/// - Beautiful dark theme
/// - Immersive full-screen experience
class ChartShowcaseScreen extends StatefulWidget {
  const ChartShowcaseScreen({super.key});

  @override
  State<ChartShowcaseScreen> createState() => _ChartShowcaseScreenState();
}

class _ChartShowcaseScreenState extends State<ChartShowcaseScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_ChartShowcaseItem> _showcaseItems = [
    _ChartShowcaseItem(
      title: 'Neon Cyberpunk',
      subtitle: 'Electric glow • Smooth curves • Pulsing animation',
      widget: const NeonCyberpunkChart(),
      gradientColors: [const Color(0xFF00FFFF), const Color(0xFFFF00FF)],
    ),
    _ChartShowcaseItem(
      title: 'Glassmorphism',
      subtitle: 'Frosted glass • Elegant gradients • Clean minimal',
      widget: const GlassmorphismChart(),
      gradientColors: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
    ),
    _ChartShowcaseItem(
      title: 'Aurora Borealis',
      subtitle: 'Nature-inspired • Starry night • Ethereal glow',
      widget: const AuroraBorealisChart(),
      gradientColors: [const Color(0xFF00FF88), const Color(0xFF00BFFF)],
    ),
    _ChartShowcaseItem(
      title: 'Sunset Gradient',
      subtitle: 'Warm colors • Bold style • Eye-catching',
      widget: const SunsetGradientChart(),
      gradientColors: [const Color(0xFFFF6B35), const Color(0xFF6C2478)],
    ),
    _ChartShowcaseItem(
      title: 'Professional Trading',
      subtitle: 'Bloomberg-style • Rich data • Production ready',
      widget: const DarkProfessionalChart(),
      gradientColors: [const Color(0xFF00D084), const Color(0xFF14141F)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF05070F),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF05070F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  // Logo/Title
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors:
                                    _showcaseItems[_currentPage].gradientColors,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'ImpChart',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SHOWCASE GALLERY',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Page indicator badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _showcaseItems[_currentPage]
                            .gradientColors
                            .map(
                              (c) => c.withValues(alpha: 0.2),
                            )
                            .toList(),
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _showcaseItems[_currentPage]
                            .gradientColors
                            .first
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${_currentPage + 1} / ${_showcaseItems.length}',
                      style: TextStyle(
                        color:
                            _showcaseItems[_currentPage].gradientColors.first,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Chart title with gradient
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: _showcaseItems[_currentPage].gradientColors,
                    ).createShader(bounds),
                    child: Text(
                      _showcaseItems[_currentPage].title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _showcaseItems[_currentPage].subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Page view with charts
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: _showcaseItems.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 40, horizontal: 20),
                    child: AnimatedScale(
                      scale: _currentPage == index ? 1.0 : 0.9,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: _currentPage == index ? 1.0 : 0.5,
                        duration: const Duration(milliseconds: 300),
                        child: _showcaseItems[index].widget,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Bottom navigation dots
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _showcaseItems.length,
                  (index) => GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: _currentPage == index ? 32 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _currentPage == index
                              ? _showcaseItems[index].gradientColors
                              : [
                                  Colors.white.withValues(alpha: 0.2),
                                  Colors.white.withValues(alpha: 0.2)
                                ],
                        ),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: _currentPage == index
                            ? [
                                BoxShadow(
                                  color: _showcaseItems[index]
                                      .gradientColors
                                      .first
                                      .withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartShowcaseItem {
  final String title;
  final String subtitle;
  final Widget widget;
  final List<Color> gradientColors;

  _ChartShowcaseItem({
    required this.title,
    required this.subtitle,
    required this.widget,
    required this.gradientColors,
  });
}
