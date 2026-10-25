import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/features/foods/data/food_repository.dart';
import 'package:mizan/features/foods/domain/food_serving.dart';
import 'package:mizan/features/foods/domain/meal_ingredient.dart';
import 'package:mizan/features/foods/presentation/food_amount_dialog.dart';
import 'package:mizan/features/foods/presentation/food_providers.dart';
import 'package:mizan/features/foods/presentation/food_search_screen.dart';
import 'package:mizan/features/settings/presentation/settings_providers.dart';

/// Builds a meal out of foods, or edits [meal] when one is given.
class MealFormScreen extends ConsumerWidget {
  const MealFormScreen({this.meal, super.key});

  final Food? meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meal = this.meal;
    // A new meal starts empty; an existing one waits for its ingredients.
    final ingredients = meal == null
        ? const <MealIngredient>[]
        : ref.watch(mealIngredientsProvider(meal.id)).value;

    if (ingredients == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return _MealForm(meal: meal, ingredients: ingredients);
  }
}

class _MealForm extends ConsumerStatefulWidget {
  const _MealForm({required this.meal, required this.ingredients});

  final Food? meal;
  final List<MealIngredient> ingredients;

  @override
  ConsumerState<_MealForm> createState() => _MealFormState();
}

class _MealFormState extends ConsumerState<_MealForm> {
  late final _name = TextEditingController(text: widget.meal?.name);
  late final _ingredients = [...widget.ingredients];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty && _ingredients.isNotEmpty;

  /// Lets the user search for a food and say how much of it goes in.
  Future<void> _addIngredient() async {
    final picked = await Navigator.of(context).push<(Food, FoodAmount)>(
      MaterialPageRoute(
        builder: (_) => FoodSearchScreen(
          autofocus: true,
          onFoodSelected: (context, food) async {
            final amount = await showFoodAmountDialog(context, food);
            if (amount != null && context.mounted) {
              Navigator.of(context).pop((food, amount));
            }
          },
        ),
      ),
    );
    if (picked == null) return;
    final (food, amount) = picked;
    final kcal = await ref.read(foodRepositoryProvider).energyPer100g(food.id);
    if (!mounted) return;
    setState(
      () => _ingredients.add(
        MealIngredient(
          foodId: food.id,
          name: food.name,
          grams: amount.grams,
          kcalPer100g: kcal,
        ),
      ),
    );
  }

  Future<void> _save() async {
    await ref
        .read(foodRepositoryProvider)
        .saveMeal(
          id: widget.meal?.id,
          name: _name.text.trim(),
          ingredients: _ingredients,
        );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final grams = _ingredients.fold<double>(0, (sum, i) => sum + i.grams);
    final kcal = _ingredients.fold<double>(0, (sum, i) => sum + i.kcal);
    final units = ref.watch(displayUnitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meal == null ? 'Create meal' : 'Edit meal'),
        actions: [
          TextButton(
            onPressed: _canSave ? _save : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Meal name'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text('Ingredients', style: theme.textTheme.titleSmall),
                ),
                Text(
                  '${units.energy(kcal)} · ${units.weight(grams)}',
                  style: muted,
                ),
              ],
            ),
          ),
          if (_ingredients.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Add the foods that make up this meal.',
                style: muted,
              ),
            ),
          for (final (i, ingredient) in _ingredients.indexed)
            ListTile(
              title: Text(ingredient.name),
              subtitle: Text(
                '${units.weight(ingredient.grams)} · '
                '${units.energy(ingredient.kcal)}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Remove ingredient',
                onPressed: () => setState(() => _ingredients.removeAt(i)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add ingredient'),
                onPressed: _addIngredient,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
