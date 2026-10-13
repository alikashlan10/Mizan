import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mizan/core/theme/app_colors.dart';

class RingSegment {
  const RingSegment({required this.value, required this.color});

  final double value;
  final Color color;
}

/// A ring split into [segments], with [center] shown in the hole. Draws an
/// empty track when there is nothing to show.
class RingChart extends StatelessWidget {
  const RingChart({
    required this.segments,
    required this.center,
    this.size = 92,
    this.thickness = 10,
    super.key,
  });

  final List<RingSegment> segments;
  final Widget center;
  final double size;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final visible = [
      for (final s in segments)
        if (s.value > 0) s,
    ];
    final shown = visible.isEmpty
        ? const [RingSegment(value: 1, color: AppColors.chartTrack)]
        : visible;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: shown.length > 1 ? 2 : 0,
              centerSpaceRadius: size / 2 - thickness,
              pieTouchData: PieTouchData(enabled: false),
              sections: [
                for (final s in shown)
                  PieChartSectionData(
                    value: s.value,
                    color: s.color,
                    radius: thickness,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          center,
        ],
      ),
    );
  }
}
