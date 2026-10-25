import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/domain/display_units.dart';
import 'package:mizan/core/domain/macro_energy.dart';
import 'package:mizan/core/domain/nutrient_catalog.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/core/formatting/amount_format.dart';
import 'package:mizan/core/theme/app_colors.dart';
import 'package:mizan/core/widgets/stacked_bar.dart';
import 'package:mizan/features/foods/data/food_repository.dart';
import 'package:mizan/features/foods/domain/daily_targets.dart';
import 'package:mizan/features/foods/domain/daily_values.dart';
import 'package:mizan/features/foods/domain/food_categories.dart';
import 'package:mizan/features/foods/domain/food_nutrient_amount.dart';
import 'package:mizan/features/foods/domain/food_serving.dart';
import 'package:mizan/features/foods/domain/food_sources.dart';
import 'package:mizan/features/foods/domain/meal_ingredient.dart';
import 'package:mizan/features/foods/presentation/food_form_screen.dart';
import 'package:mizan/features/foods/presentation/food_providers.dart';
import 'package:mizan/features/foods/presentation/meal_form_screen.dart';
import 'package:mizan/features/foods/presentation/widgets/food_amount_field.dart';
import 'package:mizan/features/settings/presentation/settings_providers.dart';

/// A food's nutrition facts for an amount the user can change, each measured
/// against a daily target.
class FoodDetailScreen extends ConsumerStatefulWidget {
  const FoodDetailScreen({
    required this.food,
    this.targets = const DailyTargets.reference(),
    this.onAddToDiary,
    this.onCompare,
    super.key,
  });

  /// Shows a "Compare" button when set.
  final void Function(BuildContext context)? onCompare;

  final Food food;
  final DailyTargets targets;

  /// Shows an "Add to diary" button when set; called with the amount entered.
  final Future<void> Function(BuildContext context, FoodAmount amount)?
  onAddToDiary;

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  /// Null while the amount field does not hold a valid number.
  FoodAmount? _amount = const FoodAmount.grams(100);

  /// Opens the form for this food or meal. This screen closes afterwards,
  /// because it would otherwise keep showing the values from before the edit.
  Future<void> _edit() async {
    final food = widget.food;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => food.source == FoodSources.meal
            ? MealFormScreen(meal: food)
            : FoodFormScreen(food: food),
      ),
    );
    if (saved == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${widget.food.name}?'),
        content: const Text(
          'It will no longer appear in search. Diary entries and meals that '
          'already use it are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(foodRepositoryProvider).deleteFood(widget.food.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final facts = ref.watch(foodNutrientsProvider(widget.food.id)).value;
    final amount = _amount;
    final grams = amount?.grams ?? 0;
    final targets = widget.targets;
    final onAddToDiary = widget.onAddToDiary;
    final units = ref.watch(displayUnitsProvider);
    final measuredAgainst = targets.isPersonal
        ? 'Calories and macronutrients are measured against your daily '
              'targets; other nutrients against general daily values.'
        : 'Calories and macronutrients are measured against a general '
              '${units.energy(referenceDailyKcal)} diet; fill in your profile '
              'to use your own targets.';

    /// Amount of the nutrient with [code] in the entered quantity of food.
    double? of(String code) {
      for (final fact in facts ?? const <FoodNutrientAmount>[]) {
        if (fact.code == code) return fact.amountIn(grams);
      }
      return null;
    }

    final food = widget.food;
    final isUserCreated = FoodSources.userCreated.contains(food.source);
    final isMeal = food.source == FoodSources.meal;
    final ingredients = isMeal
        ? ref.watch(mealIngredientsProvider(food.id)).value
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition facts'),
        actions: [
          if (widget.onCompare case final onCompare?)
            IconButton(
              icon: const Icon(Icons.compare_arrows),
              tooltip: 'Compare with other foods',
              onPressed: () => onCompare(context),
            ),
          if (isUserCreated) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: _edit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: _delete,
            ),
          ],
        ],
      ),
      bottomNavigationBar: onAddToDiary == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add to diary'),
                  onPressed: amount == null
                      ? null
                      : () => onAddToDiary(context, amount),
                ),
              ),
            ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.food.name, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(foodOriginLabel(widget.food), style: muted),
          const SizedBox(height: 16),
          FoodAmountField(
            foodId: widget.food.id,
            onChanged: (amount) => setState(() => _amount = amount),
          ),
          const SizedBox(height: 16),
          if (facts == null)
            const Center(child: CircularProgressIndicator())
          else if (facts.isEmpty)
            const Text('No nutrition facts recorded for this food.')
          else ...[
            _EnergyCard(
              kcal: of(NutrientCodes.energy),
              targetKcal: targets.kcal,
              units: units,
              proteinG: of(NutrientCodes.protein) ?? 0,
              carbsG: of(NutrientCodes.carbs) ?? 0,
              fatG: of(NutrientCodes.fat) ?? 0,
            ),
            const SizedBox(height: 12),
            _FactsCard(
              title: 'Macronutrients',
              rows: [
                _Fact(
                  'Protein',
                  of(NutrientCodes.protein),
                  'g',
                  daily: targets.proteinG,
                  color: AppColors.chartProtein,
                ),
                _Fact(
                  'Carbohydrates',
                  of(NutrientCodes.carbs),
                  'g',
                  daily: targets.carbsG,
                  color: AppColors.chartCarbs,
                ),
                _Fact(
                  'Fat',
                  of(NutrientCodes.fat),
                  'g',
                  daily: targets.fatG,
                  color: AppColors.chartFat,
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final group in NutrientGroup.values)
              if (_detailRows(group, of) case final rows when rows.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _FactsCard(title: _groupTitle(group), rows: rows),
                ),
            if (ingredients != null && ingredients.isNotEmpty) ...[
              const SizedBox(height: 12),
              _IngredientsCard(ingredients: ingredients, units: units),
            ],
            const SizedBox(height: 12),
            Text(
              '$measuredAgainst Nutrients this food has no data for are '
              'not shown.',
              style: muted,
            ),
          ],
        ],
      ),
    );
  }
}

/// Calories in the amount, against the daily target, and where they come from.
class _EnergyCard extends StatelessWidget {
  const _EnergyCard({
    required this.kcal,
    required this.units,
    required this.targetKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final double? kcal;
  final DisplayUnits units;
  final double targetKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final kcal = this.kcal;
    final sources = [
      ('Protein', proteinG * kcalPerGramProtein, AppColors.chartProtein),
      ('Carbs', carbsG * kcalPerGramCarbs, AppColors.chartCarbs),
      ('Fat', fatG * kcalPerGramFat, AppColors.chartFat),
    ];
    final macroKcal = sources.fold<double>(0, (sum, s) => sum + s.$2);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  kcal == null ? '—' : units.energyNumber(kcal),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Text(units.energyLabel, style: theme.textTheme.titleMedium),
                const Spacer(),
                if (kcal != null)
                  Text('${_percent(kcal / targetKcal)} of daily', style: muted),
              ],
            ),
            const SizedBox(height: 8),
            _Bar(
              fraction: kcal == null ? 0 : kcal / targetKcal,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text('Calories from', style: muted),
            const SizedBox(height: 6),
            StackedBar(
              segments: [
                for (final (_, value, color) in sources)
                  StackedBarSegment(value: value, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final (label, value, color) in sources)
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '$label '
                            '${macroKcal <= 0 ? '—' : _percent(value / macroKcal)}',
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Nutrients shown above the group cards, in the calorie and macro cards.
const _headlineCodes = {
  NutrientCodes.energy,
  NutrientCodes.protein,
  NutrientCodes.carbs,
  NutrientCodes.fat,
};

/// The rows for [group]: each tracked nutrient the food has a value for,
/// measured against its general daily value where there is one.
List<_Fact> _detailRows(
  NutrientGroup group,
  double? Function(String code) amountOf,
) => [
  for (final n in nutrientCatalog)
    if (n.group == group && !_headlineCodes.contains(n.code))
      if (amountOf(n.code) case final amount?)
        _Fact(n.name, amount, n.unit, daily: n.dailyValue),
];

String _groupTitle(NutrientGroup group) => switch (group) {
  NutrientGroup.general => 'General',
  NutrientGroup.carbohydrates => 'Carbohydrates',
  NutrientGroup.lipids => 'Fats',
  NutrientGroup.protein => 'Amino acids',
  NutrientGroup.vitamins => 'Vitamins',
  NutrientGroup.minerals => 'Minerals',
};

/// What a meal is made of.
class _IngredientsCard extends StatelessWidget {
  const _IngredientsCard({required this.ingredients, required this.units});

  final List<MealIngredient> ingredients;
  final DisplayUnits units;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ingredients', style: theme.textTheme.titleSmall),
            for (final ingredient in ingredients) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ingredient.name,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(units.weight(ingredient.grams), style: muted),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One nutrient line of a [_FactsCard].
class _Fact {
  const _Fact(
    this.label,
    this.amount,
    this.unit, {
    this.daily,
    this.color = AppColors.primaryBright,
  });

  final String label;

  /// Null when the food has no value recorded for this nutrient.
  final double? amount;
  final String unit;

  /// The daily amount the bar is measured against; no bar without one.
  final double? daily;
  final Color color;
}

class _FactsCard extends StatelessWidget {
  const _FactsCard({required this.title, required this.rows});

  final String title;
  final List<_Fact> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            for (final fact in rows) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(fact.label, style: theme.textTheme.bodyLarge),
                  ),
                  Text(
                    fact.amount == null
                        ? '—'
                        : '${formatAmount(fact.amount!)} ${fact.unit}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      fact.amount == null || fact.daily == null
                          ? ''
                          : _percent(fact.amount! / fact.daily!),
                      style: muted,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              if (fact.daily != null) ...[
                const SizedBox(height: 6),
                _Bar(
                  fraction: (fact.amount ?? 0) / fact.daily!,
                  color: fact.color,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// A horizontal bar filled to [fraction] of its width; values over 1 are full.
class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        // Full width, so the unfilled track shows wherever the bar is placed.
        width: double.infinity,
        height: 8,
        child: ColoredBox(
          color: AppColors.chartTrack,
          child: FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: fraction.clamp(0.0, 1.0),
            child: ColoredBox(color: color),
          ),
        ),
      ),
    );
  }
}

String _percent(double fraction) => '${(fraction * 100).round()}%';
