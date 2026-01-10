import 'package:flutter/material.dart';

import 'chart_example.dart';

/// Beautiful example showcasing all ImpChart factory methods.
///
/// This example demonstrates:
/// - All 6 factory methods (minimal, simple, trading, dark, light, compact)
/// - Beautiful modern UI with cards and tabs
/// - Live updates simulation
/// - Multiple chart instances
void main() {
  runApp(const ChartExampleApp());
}

class ChartExampleApp extends StatelessWidget {
  const ChartExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chart Factory Methods Showcase',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.cyan,
        scaffoldBackgroundColor: const Color(0xFF0A0E27),
        cardColor: const Color(0xFF1A1F3A),
        dividerColor: Colors.white24,
      ),
      home: const ChartExampleScreen(),
    );
  }
}