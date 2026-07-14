import 'package:flutter/material.dart';

/// Compact in-chart affordance for returning to the latest candle.
///
/// The indicator is intentionally placed just above the X-axis band so it feels
/// attached to the charted data without overlapping axis labels.
class ChartLiveUpdateIndicator extends StatelessWidget {
  const ChartLiveUpdateIndicator({
    super.key,
    required this.onTap,
    required this.newCandleCount,
    required this.bottomInset,
  });

  final VoidCallback onTap;

  /// Number of newly appended candles received while detached from latest.
  final int newCandleCount;

  /// Distance from the bottom edge used to float the control above the X-axis.
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final label = 'Go to live (+$newCandleCount)';

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2FD67B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
