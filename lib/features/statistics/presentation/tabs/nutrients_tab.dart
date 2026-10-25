import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/domain/nutrient_catalog.dart';
import 'package:mizan/core/formatting/amount_format.dart';
import 'package:mizan/core/theme/app_colors.dart';
import 'package:mizan/features/settings/presentation/settings_providers.dart';
import 'package:mizan/features/statistics/domain/range_stats.dart';
import 'package:mizan/features/statistics/presentation/statistics_providers.dart';
import 'package:mizan/features/statistics/presentation/widgets/stats_card.dart';

/// Every tracked nutrient over the range, against general daily values.
class NutrientsTab extends ConsumerWidget {
  const NutrientsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(rangeStatsProvider);
    if (stats == null) return const Center(child: CircularProgressIndicator());
    if (!stats.hasData) return const NoDataMessage();
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${stats.loggedDays.length > 1 ? 'Average per logged day, against' : 'Against'} '
            'general daily values. Sodium, saturated fat and cholesterol are '
            'limits: their bars turn red past 100%. Values only cover foods '
            'that have data for each nutrient.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final group in NutrientGroup.values)
          if (_rows(group, stats) case final rows when rows.isNotEmpty)
            StatsCard(
              title: _groupTitle(group),
              child: Column(children: rows),
            ),
      ],
    );
  }
}

List<Widget> _rows(NutrientGroup group, RangeStats stats) => [
  for (final n in nutrientCatalog)
    if (n.group == group && stats.hasAny(n.code))
      _NutrientRow(nutrient: n, average: stats.averageOf(n.code)),
];

String _groupTitle(NutrientGroup group) => switch (group) {
  NutrientGroup.general => 'General',
  NutrientGroup.carbohydrates => 'Carbohydrates',
  NutrientGroup.lipids => 'Fats',
  NutrientGroup.protein => 'Protein and amino acids',
  NutrientGroup.vitamins => 'Vitamins',
  NutrientGroup.minerals => 'Minerals',
};

class _NutrientRow extends ConsumerWidget {
  const _NutrientRow({required this.nutrient, required this.average});

  final NutrientDefinition nutrient;
  final double average;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final daily = nutrient.dailyValue;
    final share = daily == null ? null : average / daily;
    final over = nutrient.isLimit && share != null && share > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(nutrient.name, style: theme.textTheme.bodyLarge),
              ),
              Text(
                nutrient.unit == 'kcal'
                    ? ref.watch(displayUnitsProvider).energy(average)
                    : '${formatAmount(average)} ${nutrient.unit}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  share == null ? '' : '${(share * 100).round()}%',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: over
                        ? AppColors.critical
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (share != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: double.infinity,
                height: 8,
                child: ColoredBox(
                  color: AppColors.chartTrack,
                  child: FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: share.clamp(0.0, 1.0),
                    child: ColoredBox(
                      color: over
                          ? AppColors.critical
                          : AppColors.primaryBright,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
