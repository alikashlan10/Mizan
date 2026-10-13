import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/core/theme/app_colors.dart';
import 'package:mizan/core/widgets/meter_row.dart';
import 'package:mizan/core/widgets/ring_chart.dart';
import 'package:mizan/features/diary/domain/energy_balance.dart';
import 'package:mizan/features/diary/presentation/diary_providers.dart';
import 'package:mizan/features/profile/domain/macro_targets.dart';
import 'package:mizan/features/profile/presentation/profile_providers.dart';

/// The day at a glance: what was eaten, what was burned, and what is left.
class DayRingsCard extends ConsumerWidget {
  const DayRingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(dayTotalsProvider).value ?? const {};
    final balance = ref.watch(energyBalanceProvider);
    final macroTargets = ref.watch(macroTargetsProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _IntakeRing(
                totals: totals,
                balance: balance,
                targets: macroTargets,
              ),
            ),
            Expanded(child: _ExpenditureRing(balance: balance)),
            Expanded(child: _RemainingRing(balance: balance)),
          ],
        ),
      ),
    );
  }
}

/// Share of [whole] that [part] makes up, or null when there is no whole.
double? _share(double part, double? whole) =>
    whole == null || whole <= 0 ? null : part / whole;

class _IntakeRing extends StatelessWidget {
  const _IntakeRing({
    required this.totals,
    required this.balance,
    required this.targets,
  });

  final Map<String, double> totals;
  final EnergyBalance balance;

  /// Daily macro targets in grams; null until the user has a profile.
  final MacroValues? targets;

  @override
  Widget build(BuildContext context) {
    final macros = MacroEnergy.fromTotals(totals);

    MeterRow macro(String label, String code, double? target, Color color) {
      final eaten = totals[code] ?? 0;
      return MeterRow(
        label: label,
        value: target == null
            ? '${eaten.round()} g'
            : '${eaten.round()}/${target.round()} g',
        fraction: _share(eaten, target),
        color: color,
      );
    }

    return _RingColumn(
      title: 'Intake',
      segments: [
        RingSegment(value: macros.proteinKcal, color: AppColors.chartProtein),
        RingSegment(value: macros.carbsKcal, color: AppColors.chartCarbs),
        RingSegment(value: macros.fatKcal, color: AppColors.chartFat),
      ],
      centerValue: balance.intakeKcal.round().toString(),
      centerLabel: 'kcal',
      details: [
        macro(
          'Protein',
          NutrientCodes.protein,
          targets?.protein,
          AppColors.chartProtein,
        ),
        macro(
          'Carbs',
          NutrientCodes.carbs,
          targets?.carbs,
          AppColors.chartCarbs,
        ),
        macro('Fat', NutrientCodes.fat, targets?.fat, AppColors.chartFat),
      ],
    );
  }
}

class _ExpenditureRing extends StatelessWidget {
  const _ExpenditureRing({required this.balance});

  final EnergyBalance balance;

  @override
  Widget build(BuildContext context) {
    final resting = balance.restingKcal;
    final activity = balance.activityKcal;
    final total = balance.expenditureKcal;
    if (resting == null || activity == null || total == null) {
      return const _RingColumn.needsProfile(title: 'Expenditure');
    }

    // These have no target, so each bar shows its share of the day's total.
    MeterRow part(String label, double kcal, Color color) => MeterRow(
      label: label,
      value: kcal.round().toString(),
      fraction: _share(kcal, total),
      color: color,
    );

    return _RingColumn(
      title: 'Expenditure',
      segments: [
        RingSegment(value: resting, color: AppColors.chartResting),
        RingSegment(value: activity, color: AppColors.chartActivity),
        RingSegment(
          value: balance.exerciseKcal,
          color: AppColors.chartExercise,
        ),
      ],
      centerValue: total.round().toString(),
      centerLabel: 'kcal',
      details: [
        part('Resting', resting, AppColors.chartResting),
        part('Activity', activity, AppColors.chartActivity),
        part('Exercise', balance.exerciseKcal, AppColors.chartExercise),
      ],
    );
  }
}

class _RemainingRing extends StatelessWidget {
  const _RemainingRing({required this.balance});

  final EnergyBalance balance;

  @override
  Widget build(BuildContext context) {
    final remaining = balance.remainingKcal;
    final budget = balance.budgetKcal;
    final estimate = balance.estimate;
    if (remaining == null || budget == null || estimate == null) {
      return const _RingColumn.needsProfile(title: 'Remaining');
    }
    final isOver = remaining < 0;

    // Each bar is measured against the day's budget (target + exercise).
    return _RingColumn(
      title: 'Remaining',
      segments: isOver
          ? const [RingSegment(value: 1, color: AppColors.critical)]
          : [
              RingSegment(value: balance.intakeKcal, color: AppColors.primary),
              RingSegment(value: remaining, color: AppColors.chartTrack),
            ],
      centerValue: remaining.abs().round().toString(),
      centerLabel: isOver ? 'kcal over' : 'kcal left',
      details: [
        MeterRow(
          label: 'Target',
          value: estimate.targetKcal.round().toString(),
          fraction: _share(estimate.targetKcal, budget),
          color: AppColors.primaryBright,
        ),
        MeterRow(
          label: 'Exercise',
          value: '+${balance.exerciseKcal.round()}',
          fraction: _share(balance.exerciseKcal, budget),
          color: AppColors.chartExercise,
        ),
        MeterRow(
          label: 'Eaten',
          value: balance.intakeKcal.round().toString(),
          fraction: _share(balance.intakeKcal, budget),
          color: isOver ? AppColors.critical : AppColors.primary,
        ),
      ],
    );
  }
}

class _RingColumn extends StatelessWidget {
  const _RingColumn({
    required this.title,
    required this.segments,
    required this.centerValue,
    required this.centerLabel,
    required this.details,
  });

  /// A ring that cannot be drawn until the user has a profile.
  const _RingColumn.needsProfile({required this.title})
    : segments = const [],
      centerValue = '—',
      centerLabel = '',
      details = null;

  final String title;
  final List<RingSegment> segments;
  final String centerValue;
  final String centerLabel;

  /// The bars under the ring. Null shows a prompt to fill in the profile.
  final List<Widget>? details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final details = this.details;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          RingChart(
            segments: segments,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  centerValue,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (centerLabel.isNotEmpty)
                  Text(centerLabel, style: muted?.copyWith(fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          if (details == null)
            Text(
              'Fill in your profile to see this',
              style: muted,
              textAlign: TextAlign.center,
            )
          else
            ...details,
        ],
      ),
    );
  }
}
