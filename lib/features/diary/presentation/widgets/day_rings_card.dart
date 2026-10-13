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

/// The day at a glance: what was eaten, what was burned, what is left, and
/// progress toward the macro targets. Finer breakdowns belong to Statistics.
class DayRingsCard extends ConsumerWidget {
  const DayRingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final totals = ref.watch(dayTotalsProvider).value ?? const {};
    final balance = ref.watch(energyBalanceProvider);
    final macroTargets = ref.watch(macroTargetsProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _IntakeRing(totals: totals, balance: balance),
                ),
                Expanded(child: _ExpenditureRing(balance: balance)),
                Expanded(child: _RemainingRing(balance: balance)),
              ],
            ),
            if (balance.estimate == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Fill in your profile to see expenditure, remaining '
                  'calories and macro targets.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            _MacroBars(totals: totals, targets: macroTargets),
          ],
        ),
      ),
    );
  }
}

/// Protein, carbohydrate and fat eaten, each against its daily target.
class _MacroBars extends StatelessWidget {
  const _MacroBars({required this.totals, required this.targets});

  final Map<String, double> totals;

  /// Daily macro targets in grams; null until the user has a profile.
  final MacroValues? targets;

  @override
  Widget build(BuildContext context) {
    MeterRow macro(String label, String code, double? target, Color color) {
      final eaten = totals[code] ?? 0;
      return MeterRow(
        label: label,
        value: target == null
            ? '${eaten.round()} g'
            : '${eaten.round()} / ${target.round()} g',
        fraction: target == null || target <= 0 ? null : eaten / target,
        color: color,
      );
    }

    return Column(
      children: [
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

class _IntakeRing extends StatelessWidget {
  const _IntakeRing({required this.totals, required this.balance});

  final Map<String, double> totals;
  final EnergyBalance balance;

  @override
  Widget build(BuildContext context) {
    final macros = MacroEnergy.fromTotals(totals);

    return _RingColumn(
      title: 'Intake',
      segments: [
        RingSegment(value: macros.proteinKcal, color: AppColors.chartProtein),
        RingSegment(value: macros.carbsKcal, color: AppColors.chartCarbs),
        RingSegment(value: macros.fatKcal, color: AppColors.chartFat),
      ],
      centerValue: balance.intakeKcal.round().toString(),
      centerLabel: 'kcal',
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
    );
  }
}

class _RemainingRing extends StatelessWidget {
  const _RemainingRing({required this.balance});

  final EnergyBalance balance;

  @override
  Widget build(BuildContext context) {
    final remaining = balance.remainingKcal;
    if (remaining == null) {
      return const _RingColumn.needsProfile(title: 'Remaining');
    }
    final isOver = remaining < 0;

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
    );
  }
}

class _RingColumn extends StatelessWidget {
  const _RingColumn({
    required this.title,
    required this.segments,
    required this.centerValue,
    required this.centerLabel,
  });

  /// A ring that cannot be drawn until the user has a profile.
  const _RingColumn.needsProfile({required this.title})
    : segments = const [],
      centerValue = '—',
      centerLabel = '';

  final String title;
  final List<RingSegment> segments;
  final String centerValue;
  final String centerLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
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
                Text(
                  centerLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: theme.textTheme.labelLarge),
      ],
    );
  }
}
