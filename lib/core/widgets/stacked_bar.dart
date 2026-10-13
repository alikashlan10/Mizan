import 'package:flutter/material.dart';
import 'package:mizan/core/theme/app_colors.dart';

class StackedBarSegment {
  const StackedBarSegment({required this.value, required this.color});

  final double value;
  final Color color;
}

/// One horizontal bar divided into [segments] by their share of the total.
/// Shows an empty track when there is nothing to divide.
class StackedBar extends StatelessWidget {
  const StackedBar({required this.segments, this.height = 10, super.key});

  final List<StackedBarSegment> segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    // Slivers under half a percent would only read as a rendering glitch.
    final visible = [
      for (final s in segments)
        if (s.value > 0 && s.value / total >= 0.005) s,
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: visible.isEmpty
            ? const ColoredBox(color: AppColors.chartTrack)
            : Row(
                spacing: 2,
                children: [
                  for (final s in visible)
                    Expanded(
                      // Flex must be a positive whole number.
                      flex: (s.value * 1000).round().clamp(1, 1 << 30),
                      child: ColoredBox(
                        color: s.color,
                        child: const SizedBox.expand(),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
