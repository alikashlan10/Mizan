import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/core/formatting/amount_format.dart';
import 'package:mizan/core/theme/app_colors.dart';
import 'package:mizan/features/comparison/domain/comparison.dart';
import 'package:mizan/features/comparison/presentation/comparison_providers.dart';
import 'package:mizan/features/foods/presentation/food_providers.dart';
import 'package:mizan/features/foods/presentation/food_search_screen.dart';

/// Compares up to [maxComparedFoods] foods nutrient by nutrient, either at
/// the same weight or at the weights that supply the same amount of one
/// nutrient.
class ComparisonScreen extends ConsumerStatefulWidget {
  const ComparisonScreen({super.key});

  @override
  ConsumerState<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends ConsumerState<ComparisonScreen> {
  bool _byNutrient = false;
  final _grams = TextEditingController(text: '100');
  final _amount = TextEditingController(text: '10');
  String _nutrientCode = NutrientCodes.carbs;

  @override
  void dispose() {
    _grams.dispose();
    _amount.dispose();
    super.dispose();
  }

  /// The match as currently entered, or null while the number is invalid.
  ComparisonMatch? get _match {
    final value = double.tryParse((_byNutrient ? _amount : _grams).text.trim());
    if (value == null || value <= 0) return null;
    return _byNutrient
        ? MatchByNutrient(code: _nutrientCode, amount: value)
        : MatchByWeight(value);
  }

  Future<void> _addFood() async {
    final food = await Navigator.of(context).push<Food>(
      MaterialPageRoute(
        builder: (_) => FoodSearchScreen(
          autofocus: true,
          onFoodSelected: (context, food) async =>
              Navigator.of(context).pop(food),
        ),
      ),
    );
    if (food != null) ref.read(comparedFoodsProvider.notifier).add(food);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final foods = ref.watch(comparedFoodsProvider);
    final nutrients = ref.watch(nutrientsProvider).value ?? const [];
    final match = _match;

    // Each food's facts per 100 g by nutrient code; null while loading.
    final facts = [
      for (final food in foods) ref.watch(foodNutrientsProvider(food.id)).value,
    ];
    final compared = [
      for (final f in facts)
        if (f != null && match != null)
          () {
            final per100g = {for (final n in f) n.code: n.amountPer100g};
            return ComparedFood(
              grams: gramsFor(per100g, match),
              per100g: per100g,
            );
          }(),
    ];
    final ready = foods.length >= 2 && compared.length == foods.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Compare foods')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (i, food) in foods.indexed)
            _FoodRow(
              index: i,
              food: food,
              grams: ready ? compared[i].grams : null,
              showGrams: ready,
              onRemove: () =>
                  ref.read(comparedFoodsProvider.notifier).remove(food),
            ),
          if (foods.length < maxComparedFoods)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add food'),
                onPressed: _addFood,
              ),
            ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Same weight')),
              ButtonSegment(value: true, label: Text('Same nutrient')),
            ],
            selected: {_byNutrient},
            onSelectionChanged: (s) => setState(() => _byNutrient = s.single),
          ),
          const SizedBox(height: 8),
          if (_byNutrient)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amount,
                    keyboardType: _decimalKeyboard,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      suffixText: _unitOf(nutrients, _nutrientCode),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    // Rebuilt once the nutrient list has loaded.
                    key: ValueKey(nutrients.length),
                    initialValue: nutrients.any((n) => n.code == _nutrientCode)
                        ? _nutrientCode
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Of'),
                    items: [
                      for (final n in nutrients)
                        DropdownMenuItem(value: n.code, child: Text(n.name)),
                    ],
                    onChanged: (code) => setState(() => _nutrientCode = code!),
                  ),
                ),
              ],
            )
          else
            TextField(
              controller: _grams,
              keyboardType: _decimalKeyboard,
              decoration: const InputDecoration(
                labelText: 'Weight of each food',
                suffixText: 'g',
              ),
              onChanged: (_) => setState(() {}),
            ),
          const SizedBox(height: 16),
          if (foods.length < 2)
            Text('Add at least two foods to compare them.', style: muted)
          else if (match == null)
            Text('Enter an amount above zero.', style: muted)
          else if (!ready)
            const Center(child: CircularProgressIndicator())
          else
            for (final nutrient in nutrients)
              _NutrientCard(
                title: nutrient.name,
                unit: nutrient.unit,
                wholeNumbers: nutrient.code == NutrientCodes.energy,
                values: [
                  for (final food in compared) food.amountOf(nutrient.code),
                ],
              ),
        ],
      ),
    );
  }
}

/// The letter that stands for the food at [index] throughout the screen.
String _letter(int index) => String.fromCharCode('A'.codeUnitAt(0) + index);

String? _unitOf(List<Nutrient> nutrients, String code) {
  for (final n in nutrients) {
    if (n.code == code) return n.unit;
  }
  return null;
}

class _Badge extends StatelessWidget {
  const _Badge(this.index);

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primaryMuted,
        shape: BoxShape.circle,
      ),
      child: Text(
        _letter(index),
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// One compared food: its letter, name, and the weight being compared.
class _FoodRow extends StatelessWidget {
  const _FoodRow({
    required this.index,
    required this.food,
    required this.grams,
    required this.showGrams,
    required this.onRemove,
  });

  final int index;
  final Food food;

  /// Null when the food cannot supply the matched nutrient.
  final double? grams;

  /// False until the comparison has been worked out.
  final bool showGrams;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grams = this.grams;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          children: [
            _Badge(index),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(food.name, style: theme.textTheme.bodyLarge),
                    if (showGrams)
                      Text(
                        grams == null
                            ? 'Has none of this nutrient'
                            : '${formatAmount(grams)} g',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Remove ${food.name}',
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

/// One nutrient across the compared foods: a bar per food, scaled to the
/// largest value among them.
class _NutrientCard extends StatelessWidget {
  const _NutrientCard({
    required this.title,
    required this.unit,
    required this.values,
    required this.wholeNumbers,
  });

  final String title;
  final String unit;

  /// One per food, in order; null where the food has no value.
  final List<double?> values;
  final bool wholeNumbers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final largest = values.fold<double>(
      0,
      (max, v) => v != null && v > max ? v : max,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            for (final (i, value) in values.indexed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    _Badge(i),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 8,
                          child: ColoredBox(
                            color: AppColors.chartTrack,
                            child: FractionallySizedBox(
                              alignment: AlignmentDirectional.centerStart,
                              widthFactor: value == null || largest <= 0
                                  ? 0
                                  : (value / largest).clamp(0.0, 1.0),
                              child: const ColoredBox(
                                color: AppColors.primaryBright,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 84,
                      child: Text(
                        value == null
                            ? '—'
                            : '${wholeNumbers ? value.round() : formatAmount(value)} '
                                  '$unit',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const _decimalKeyboard = TextInputType.numberWithOptions(decimal: true);
