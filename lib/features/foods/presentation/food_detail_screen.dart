import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/core/formatting/amount_format.dart';
import 'package:mizan/features/foods/domain/food_nutrient_amount.dart';
import 'package:mizan/features/foods/domain/food_sources.dart';
import 'package:mizan/features/foods/presentation/food_providers.dart';

/// A food's nutrition facts for an amount the user can change.
class FoodDetailScreen extends ConsumerStatefulWidget {
  const FoodDetailScreen({required this.food, this.onAddToDiary, super.key});

  final Food food;

  /// Shows an "Add to diary" button when set.
  final Future<void> Function(BuildContext context)? onAddToDiary;

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  final _grams = TextEditingController(text: '100');

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nutrients = ref.watch(foodNutrientsProvider(widget.food.id)).value;
    final entered = double.tryParse(_grams.text.trim());
    final grams = entered == null || entered < 0 ? 0.0 : entered;
    final onAddToDiary = widget.onAddToDiary;

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition facts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.food.name, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            FoodSources.label(widget.food.source),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _grams,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              suffixText: 'g',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (nutrients == null)
            const Center(child: CircularProgressIndicator())
          else if (nutrients.isEmpty)
            const Text('No nutrition facts recorded for this food.')
          else
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, nutrient) in nutrients.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    _NutrientRow(nutrient: nutrient, grams: grams),
                  ],
                ],
              ),
            ),
          if (onAddToDiary != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add to diary'),
              onPressed: () => onAddToDiary(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _NutrientRow extends StatelessWidget {
  const _NutrientRow({required this.nutrient, required this.grams});

  final FoodNutrientAmount nutrient;
  final double grams;

  @override
  Widget build(BuildContext context) {
    final isEnergy = nutrient.code == NutrientCodes.energy;
    final amount = nutrient.amountIn(grams);
    final style = isEnergy
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyLarge;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(nutrient.name, style: style)),
          Text(
            '${isEnergy ? amount.round() : formatAmount(amount)} '
            '${nutrient.unit}',
            style: style,
          ),
        ],
      ),
    );
  }
}
