import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/domain/macro_energy.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/core/formatting/amount_format.dart';
import 'package:mizan/core/theme/app_colors.dart';
import 'package:mizan/core/widgets/meter_row.dart';
import 'package:mizan/core/widgets/stacked_bar.dart';
import 'package:mizan/features/profile/presentation/profile_providers.dart';
import 'package:mizan/features/statistics/domain/range_stats.dart';
import 'package:mizan/features/statistics/presentation/statistics_providers.dart';
import 'package:mizan/features/statistics/presentation/widgets/stats_card.dart';

/// One macronutrient as this tab presents it.
typedef _Macro = ({String code, String name, double kcalPerGram, Color color});

const List<_Macro> _macros = [
  (
    code: NutrientCodes.protein,
    name: 'Protein',
    kcalPerGram: kcalPerGramProtein,
    color: AppColors.chartProtein,
  ),
  (
    code: NutrientCodes.carbs,
    name: 'Carbs',
    kcalPerGram: kcalPerGramCarbs,
    color: AppColors.chartCarbs,
  ),
  (
    code: NutrientCodes.fat,
    name: 'Fat',
    kcalPerGram: kcalPerGramFat,
    color: AppColors.chartFat,
  ),
];

/// Protein, carbohydrate and fat over the range: against targets, as a share
/// of calories, and which foods supplied them.
class MacrosTab extends ConsumerWidget {
  const MacrosTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(rangeStatsProvider);
    if (stats == null) return const Center(child: CircularProgressIndicator());
    if (!stats.hasData) return const NoDataMessage();
    final targets = ref.watch(macroTargetsProvider);
    final perDay = stats.loggedDays.length > 1;

    double? targetOf(String code) => switch (code) {
      NutrientCodes.protein => targets?.protein,
      NutrientCodes.carbs => targets?.carbs,
      _ => targets?.fat,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StatsCard(
          title: 'Against your targets',
          subtitle: [
            if (perDay) 'Average per logged day',
            if (targets == null) 'fill in your profile to set targets',
          ].join('; '),
          child: Column(
            children: [
              for (final m in _macros)
                MeterRow(
                  label: m.name,
                  value: targetOf(m.code) == null
                      ? '${formatAmount(stats.averageOf(m.code))} g'
                      : '${formatAmount(stats.averageOf(m.code))} / '
                            '${targetOf(m.code)!.round()} g',
                  fraction: targetOf(m.code) == null
                      ? null
                      : stats.averageOf(m.code) / targetOf(m.code)!,
                  color: m.color,
                ),
            ],
          ),
        ),
        _CalorieSplitCard(
          stats: stats,
          targetGrams: targets == null
              ? null
              : {for (final m in _macros) m.code: targetOf(m.code)!},
        ),
        for (final m in _macros) _TopFoodsCard(macro: m, stats: stats),
      ],
    );
  }
}

/// Where the calories came from, next to where the targets say they should.
class _CalorieSplitCard extends StatelessWidget {
  const _CalorieSplitCard({required this.stats, required this.targetGrams});

  final RangeStats stats;

  /// Daily target grams by macro code; null without a profile.
  final Map<String, double>? targetGrams;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actual = {
      for (final m in _macros) m.code: stats.averageOf(m.code) * m.kcalPerGram,
    };
    final target = targetGrams == null
        ? null
        : {
            for (final m in _macros)
              m.code: targetGrams![m.code]! * m.kcalPerGram,
          };

    String percent(Map<String, double> kcal, String code) {
      final total = kcal.values.fold<double>(0, (a, b) => a + b);
      return total <= 0 ? '—' : '${(kcal[code]! / total * 100).round()}%';
    }

    Widget bar(String label, Map<String, double> kcal) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        StackedBar(
          segments: [
            for (final m in _macros)
              StackedBarSegment(value: kcal[m.code]!, color: m.color),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 16,
          children: [
            for (final m in _macros)
              LegendDot(
                color: m.color,
                label: '${m.name} ${percent(kcal, m.code)}',
              ),
          ],
        ),
      ],
    );

    return StatsCard(
      title: 'Calories by macronutrient',
      child: Column(
        children: [
          bar('Eaten', actual),
          if (target != null) ...[
            const SizedBox(height: 16),
            bar('Target', target),
          ],
        ],
      ),
    );
  }
}

/// The foods that supplied the most of one macro over the range.
class _TopFoodsCard extends ConsumerWidget {
  const _TopFoodsCard({required this.macro, required this.stats});

  final _Macro macro;
  final RangeStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final foods = ref.watch(topFoodsProvider(macro.code)).value;
    // Everything eaten of this macro over the range, for each food's share.
    final total = stats.averageOf(macro.code) * stats.loggedDays.length;

    return StatsCard(
      title: 'Top ${macro.name.toLowerCase()} sources',
      child: foods == null
          ? const Center(child: CircularProgressIndicator())
          : foods.isEmpty
          ? Text(
              'None of the foods logged contain any.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              children: [
                for (final food in foods)
                  MeterRow(
                    label: food.name,
                    value:
                        '${formatAmount(food.amount)} g · '
                        '${total <= 0 ? 0 : (food.amount / total * 100).round()}%',
                    fraction: total <= 0 ? 0 : food.amount / total,
                    color: macro.color,
                  ),
              ],
            ),
    );
  }
}
