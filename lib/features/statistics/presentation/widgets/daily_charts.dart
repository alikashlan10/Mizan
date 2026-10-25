import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mizan/core/domain/display_units.dart';
import 'package:mizan/core/formatting/amount_format.dart';
import 'package:mizan/core/theme/app_colors.dart';
import 'package:mizan/features/statistics/domain/range_stats.dart';

/// A round step for about four gridlines across [span]: 50, 100, 250, 500,
/// 1,000 and so on.
double _niceStep(double span) {
  final rough = span / 4;
  for (final step in const [50.0, 100.0, 250.0, 500.0, 1000.0, 2500.0]) {
    if (rough <= step) return step;
  }
  return 5000;
}

/// Shared axes, grid and touch styling for the day-by-day charts. [step] is
/// the gap between gridlines, so labels never crowd each other.
FlTitlesData _titles(List<DayBalance> days, double step) {
  // About six date labels whatever the range length.
  final every = max(1, (days.length / 6).ceil());
  Widget dateLabel(double value, TitleMeta meta) {
    final i = value.round();
    if (i < 0 || i >= days.length || i % every != 0) {
      return const SizedBox.shrink();
    }
    return SideTitleWidget(
      meta: meta,
      child: Text(
        DateFormat.Md().format(days[i].day),
        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
      ),
    );
  }

  Widget kcalLabel(double value, TitleMeta meta) => SideTitleWidget(
    meta: meta,
    child: Text(
      formatWhole(value),
      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
    ),
  );

  const none = AxisTitles(sideTitles: SideTitles());
  return FlTitlesData(
    topTitles: none,
    rightTitles: none,
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        interval: 1,
        reservedSize: 24,
        getTitlesWidget: dateLabel,
      ),
    ),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 44,
        interval: step,
        getTitlesWidget: kcalLabel,
      ),
    ),
  );
}

FlGridData _grid(double step) => FlGridData(
  drawVerticalLine: false,
  horizontalInterval: step,
  getDrawingHorizontalLine: (_) =>
      const FlLine(color: AppColors.outline, strokeWidth: 1),
);

LineTouchData _touch(
  List<DayBalance> days,
  List<String> seriesNames,
  DisplayUnits units,
) {
  return LineTouchData(
    touchTooltipData: LineTouchTooltipData(
      getTooltipColor: (_) => AppColors.surface,
      getTooltipItems: (spots) => [
        for (final (i, spot) in spots.indexed)
          LineTooltipItem(
            '${i == 0 ? '${DateFormat.MMMd().format(days[spot.x.round()].day)}\n' : ''}'
            '${seriesNames[spot.barIndex]}: ${formatWhole(spot.y)} ${units.energyLabel}',
            const TextStyle(color: AppColors.textPrimary, fontSize: 12),
          ),
      ],
    ),
  );
}

/// One point per day in the user's energy unit, with gaps on days that have
/// no value.
List<FlSpot> _spots(
  List<DayBalance> days,
  double? Function(DayBalance) kcal,
  DisplayUnits units,
) => [
  for (final (i, d) in days.indexed)
    if (kcal(d) case final value?)
      FlSpot(i.toDouble(), units.energyValue(value))
    else
      FlSpot.nullSpot,
];

/// Daily calories eaten against daily calories burned.
class IntakeExpenditureChart extends StatelessWidget {
  const IntakeExpenditureChart({
    required this.days,
    required this.units,
    super.key,
  });

  final List<DayBalance> days;
  final DisplayUnits units;

  @override
  Widget build(BuildContext context) {
    final hasExpenditure = days.any((d) => d.expenditureKcal != null);
    final highest = [
      for (final d in days) ...[?d.intakeKcal, ?d.expenditureKcal],
    ].map(units.energyValue).fold<double>(0, max);
    final step = _niceStep(max(highest, 100));
    final top = (highest / step).ceil() * step;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          children: [
            const _LegendLine(color: AppColors.primary, label: 'Eaten'),
            if (hasExpenditure)
              const _LegendLine(
                color: AppColors.textSecondary,
                label: 'Burned',
                dashed: true,
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (days.length - 1).toDouble(),
              minY: 0,
              maxY: max(top, step),
              gridData: _grid(step),
              borderData: FlBorderData(show: false),
              titlesData: _titles(days, step),
              lineTouchData: _touch(days, ['Eaten', 'Burned'], units),
              lineBarsData: [
                LineChartBarData(
                  spots: _spots(days, (d) => d.intakeKcal, units),
                  color: AppColors.primary,
                  barWidth: 2,
                  dotData: FlDotData(show: days.length <= 31),
                ),
                if (hasExpenditure)
                  LineChartBarData(
                    spots: _spots(days, (d) => d.expenditureKcal, units),
                    color: AppColors.textSecondary,
                    barWidth: 2,
                    dashArray: const [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Each day's surplus (above zero) or deficit (below zero).
class BalanceChart extends StatelessWidget {
  const BalanceChart({required this.days, required this.units, super.key});

  final List<DayBalance> days;
  final DisplayUnits units;

  @override
  Widget build(BuildContext context) {
    final values = [
      for (final d in days)
        if (d.balanceKcal case final kcal?) units.energyValue(kcal),
    ];
    // Keep zero in view, with whole gridlines above and below it.
    final highest = max(100.0, values.fold<double>(0, max));
    final lowest = min(-100.0, values.fold<double>(0, min));
    final step = _niceStep(highest - lowest);
    final top = (highest / step).ceil() * step;
    final bottom = (lowest / step).floor() * step;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          spacing: 16,
          children: [
            _LegendLine(color: AppColors.critical, label: 'Surplus'),
            _LegendLine(color: AppColors.primaryBright, label: 'Deficit'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (days.length - 1).toDouble(),
              minY: bottom,
              maxY: top,
              gridData: _grid(step),
              borderData: FlBorderData(show: false),
              titlesData: _titles(days, step),
              lineTouchData: _touch(days, ['Balance'], units),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 0,
                    color: AppColors.textMuted,
                    strokeWidth: 1,
                  ),
                ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: _spots(days, (d) => d.balanceKcal, units),
                  color: AppColors.textSecondary,
                  barWidth: 2,
                  dotData: FlDotData(show: days.length <= 31),
                  // Between the line and zero: above it is a surplus,
                  // below it a deficit.
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.critical.withValues(alpha: 0.35),
                    cutOffY: 0,
                    applyCutOffY: true,
                  ),
                  aboveBarData: BarAreaData(
                    show: true,
                    color: AppColors.primaryBright.withValues(alpha: 0.35),
                    cutOffY: 0,
                    applyCutOffY: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendLine extends StatelessWidget {
  const _LegendLine({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 2,
          child: dashed
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: ColoredBox(color: color)),
                    const SizedBox(width: 3),
                    Expanded(child: ColoredBox(color: color)),
                  ],
                )
              : ColoredBox(color: color),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
