import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/core/formatting/amount_format.dart';
import 'package:mizan/core/theme/app_colors.dart';
import 'package:mizan/core/widgets/ring_chart.dart';
import 'package:mizan/features/diary/domain/energy_balance.dart';
import 'package:mizan/features/diary/presentation/diary_providers.dart';

/// The day at a glance: what was eaten, what was burned, and what is left.
class DayRingsCard extends ConsumerWidget {
  const DayRingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(dayTotalsProvider).value ?? const {};
    final balance = ref.watch(energyBalanceProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _IntakeRing(totals: totals, balance: balance),
            ),
            Expanded(child: _ExpenditureRing(balance: balance)),
            Expanded(child: _RemainingRing(balance: balance)),
          ],
        ),
      ),
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
    String grams(String code) => '${formatAmount(totals[code] ?? 0)} g';

    return _RingColumn(
      title: 'Intake',
      segments: [
        RingSegment(value: macros.proteinKcal, color: AppColors.chartProtein),
        RingSegment(value: macros.carbsKcal, color: AppColors.chartCarbs),
        RingSegment(value: macros.fatKcal, color: AppColors.chartFat),
      ],
      centerValue: balance.intakeKcal.round().toString(),
      centerLabel: 'kcal',
      legend: [
        _LegendRow(
          'Protein',
          grams(NutrientCodes.protein),
          color: AppColors.chartProtein,
        ),
        _LegendRow(
          'Carbs',
          grams(NutrientCodes.carbs),
          color: AppColors.chartCarbs,
        ),
        _LegendRow('Fat', grams(NutrientCodes.fat), color: AppColors.chartFat),
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
    if (resting == null || activity == null) {
      return const _RingColumn.needsProfile(title: 'Expenditure');
    }
    String kcal(double value) => value.round().toString();

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
      centerValue: kcal(balance.expenditureKcal!),
      centerLabel: 'kcal',
      legend: [
        _LegendRow('Resting', kcal(resting), color: AppColors.chartResting),
        _LegendRow('Activity', kcal(activity), color: AppColors.chartActivity),
        _LegendRow(
          'Exercise',
          kcal(balance.exerciseKcal),
          color: AppColors.chartExercise,
        ),
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
    final estimate = balance.estimate;
    if (remaining == null || estimate == null) {
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
      legend: [
        _LegendRow('Target', estimate.targetKcal.round().toString()),
        _LegendRow('Exercise', '+${balance.exerciseKcal.round()}'),
        _LegendRow('Eaten', '−${balance.intakeKcal.round()}'),
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
    required this.legend,
  });

  /// A ring that cannot be drawn until the user has a profile.
  const _RingColumn.needsProfile({required this.title})
    : segments = const [],
      centerValue = '—',
      centerLabel = '',
      legend = null;

  final String title;
  final List<RingSegment> segments;
  final String centerValue;
  final String centerLabel;

  /// Null shows a prompt to fill in the profile instead.
  final List<Widget>? legend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final legend = this.legend;

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
          if (legend == null)
            Text(
              'Fill in your profile to see this',
              style: muted,
              textAlign: TextAlign.center,
            )
          else
            ...legend,
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow(this.label, this.value, {this.color});

  final String label;
  final String value;

  /// The series colour this row explains; omitted for plain figures.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(fontSize: 11);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          if (color != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: style?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Text(value, style: style),
        ],
      ),
    );
  }
}
