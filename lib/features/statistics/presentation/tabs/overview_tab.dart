import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/core/theme/app_colors.dart';
import 'package:mizan/core/widgets/stacked_bar.dart';
import 'package:mizan/features/settings/presentation/settings_providers.dart';
import 'package:mizan/features/statistics/domain/range_stats.dart';
import 'package:mizan/features/statistics/presentation/statistics_providers.dart';
import 'package:mizan/features/statistics/presentation/widgets/daily_charts.dart';
import 'package:mizan/features/statistics/presentation/widgets/stats_card.dart';

/// Calories over the range: the surplus or deficit, day by day charts, and
/// where the burned calories went.
class OverviewTab extends ConsumerWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(rangeStatsProvider);
    if (stats == null) return const Center(child: CircularProgressIndicator());
    if (!stats.hasData) return const NoDataMessage();
    final days = stats.days;
    final multiDay = days.length > 1;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _BalanceCard(stats: stats),
        if (multiDay)
          StatsCard(
            title: 'Calories eaten and burned',
            subtitle: 'Per day; gaps are days with nothing logged',
            child: IntakeExpenditureChart(
              days: days,
              units: ref.watch(displayUnitsProvider),
            ),
          ),
        if (multiDay && stats.estimate != null)
          StatsCard(
            title: 'Daily surplus and deficit',
            subtitle: 'Eaten minus burned',
            child: BalanceChart(
              days: days,
              units: ref.watch(displayUnitsProvider),
            ),
          ),
        if (stats.estimate != null) _BreakdownCard(stats: stats),
      ],
    );
  }
}

/// The headline: how far over or under the calories burned the range came.
class _BalanceCard extends ConsumerWidget {
  const _BalanceCard({required this.stats});

  final RangeStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(displayUnitsProvider);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final total = stats.totalBalanceKcal;
    final average = stats.averageBalanceKcal;
    final eaten = stats.averageOf(NutrientCodes.energy);
    final burned = stats.estimate == null
        ? null
        : stats.estimate!.maintenanceKcal + stats.averageExerciseKcal;
    final perDay = stats.loggedDays.length > 1;

    return StatsCard(
      title: total == null
          ? 'Calories'
          : total >= 0
          ? 'Surplus'
          : 'Deficit',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (total != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  units.energyNumber(total.abs()),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: total >= 0
                        ? AppColors.critical
                        : AppColors.primaryBright,
                  ),
                ),
                const SizedBox(width: 6),
                Text(units.energyLabel, style: theme.textTheme.titleMedium),
              ],
            ),
            Text(
              total >= 0
                  ? 'eaten above what you burned'
                  : 'eaten below what you burned',
              style: muted,
            ),
            if (perDay && average != null)
              Text(
                '${average >= 0 ? '+' : ''}${units.energy(average)} per '
                'logged day on average',
                style: muted,
              ),
            const SizedBox(height: 12),
          ],
          _Figure(
            label: perDay ? 'Eaten, average per day' : 'Eaten',
            kcal: eaten,
          ),
          if (burned != null)
            _Figure(
              label: perDay ? 'Burned, average per day' : 'Burned',
              kcal: burned,
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Fill in your profile to see calories burned and your '
                'surplus or deficit.',
                style: muted,
              ),
            ),
        ],
      ),
    );
  }
}

class _Figure extends ConsumerWidget {
  const _Figure({required this.label, required this.kcal});

  final String label;
  final double kcal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(displayUnitsProvider);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(units.energy(kcal), style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// The breakdowns moved off the Diary: what makes up calories burned, and
/// what was left of the day's budget.
class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.stats});

  final RangeStats stats;

  @override
  Widget build(BuildContext context) {
    final estimate = stats.estimate!;
    final resting = estimate.restingKcal;
    final activity = estimate.maintenanceKcal - estimate.restingKcal;
    final exercise = stats.averageExerciseKcal;
    final eaten = stats.averageOf(NutrientCodes.energy);
    final remaining = estimate.targetKcal + exercise - eaten;
    final perDay = stats.loggedDays.length > 1;

    return StatsCard(
      title: 'Energy breakdown',
      subtitle: perDay ? 'Average per logged day' : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Burned', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          StackedBar(
            segments: [
              StackedBarSegment(value: resting, color: AppColors.chartResting),
              StackedBarSegment(
                value: activity,
                color: AppColors.chartActivity,
              ),
              StackedBarSegment(
                value: exercise,
                color: AppColors.chartExercise,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _LegendFigure(
            color: AppColors.chartResting,
            label: 'Resting',
            kcal: resting,
          ),
          _LegendFigure(
            color: AppColors.chartActivity,
            label: 'Everyday activity',
            kcal: activity,
          ),
          _LegendFigure(
            color: AppColors.chartExercise,
            label: 'Exercise',
            kcal: exercise,
          ),
          const Divider(height: 24),
          Text('Budget', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          _Figure(label: 'Target', kcal: estimate.targetKcal),
          _Figure(label: '+ Exercise', kcal: exercise),
          _Figure(label: '− Eaten', kcal: eaten),
          _Figure(
            label: remaining >= 0 ? '= Left' : '= Over',
            kcal: remaining.abs(),
          ),
        ],
      ),
    );
  }
}

class _LegendFigure extends ConsumerWidget {
  const _LegendFigure({
    required this.color,
    required this.label,
    required this.kcal,
  });

  final Color color;
  final String label;
  final double kcal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(displayUnitsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          LegendDot(color: color, label: label),
          const Spacer(),
          Text(
            units.energy(kcal),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
