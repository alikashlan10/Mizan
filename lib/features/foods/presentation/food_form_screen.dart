import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/domain/nutrient_catalog.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/features/foods/data/food_repository.dart';
import 'package:mizan/features/foods/domain/food_nutrient_amount.dart';
import 'package:mizan/features/foods/domain/food_serving.dart';
import 'package:mizan/features/foods/presentation/food_providers.dart';

/// Creates a custom food from nutrition facts entered by hand, or edits
/// [food] when one is given.
class FoodFormScreen extends ConsumerWidget {
  const FoodFormScreen({this.food, super.key});

  final Food? food;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final food = this.food;
    final nutrients = ref.watch(nutrientsProvider).value;
    // A new food starts empty; an existing one waits for its saved values.
    final facts = food == null
        ? const <FoodNutrientAmount>[]
        : ref.watch(foodNutrientsProvider(food.id)).value;
    final servings = food == null
        ? const <FoodServing>[]
        : ref.watch(foodServingsProvider(food.id)).value;

    if (nutrients == null || facts == null || servings == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return _FoodForm(
      food: food,
      nutrients: nutrients,
      facts: facts,
      servings: servings,
    );
  }
}

class _ServingFields {
  _ServingFields({String label = '', String grams = ''})
    : label = TextEditingController(text: label),
      grams = TextEditingController(text: grams);

  final TextEditingController label;
  final TextEditingController grams;

  void dispose() {
    label.dispose();
    grams.dispose();
  }
}

class _FoodForm extends ConsumerStatefulWidget {
  const _FoodForm({
    required this.food,
    required this.nutrients,
    required this.facts,
    required this.servings,
  });

  final Food? food;
  final List<Nutrient> nutrients;
  final List<FoodNutrientAmount> facts;
  final List<FoodServing> servings;

  @override
  ConsumerState<_FoodForm> createState() => _FoodFormState();
}

class _FoodFormState extends ConsumerState<_FoodForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.food?.name);
  late final _amounts = {
    for (final n in widget.nutrients)
      n.id: TextEditingController(text: _savedAmount(n.code)),
  };
  late final _servings = [
    for (final s in widget.servings)
      _ServingFields(label: s.label, grams: _trimmed(s.grams)),
  ];

  String _savedAmount(String code) {
    for (final fact in widget.facts) {
      if (fact.code == code) return _trimmed(fact.amountPer100g);
    }
    return '';
  }

  @override
  void dispose() {
    _name.dispose();
    for (final c in _amounts.values) {
      c.dispose();
    }
    for (final s in _servings) {
      s.dispose();
    }
    super.dispose();
  }

  /// Tracked nutrients of [group] other than the headline ones, in order.
  List<Nutrient> _inGroup(NutrientGroup group) => [
    for (final n in widget.nutrients)
      if (!_headlineCodes.contains(n.code) &&
          nutrientDefinition(n.code)?.group == group)
        n,
  ];

  Widget _amountField(Nutrient n) => TextFormField(
    controller: _amounts[n.id],
    keyboardType: _decimalKeyboard,
    decoration: InputDecoration(labelText: n.name, suffixText: n.unit),
    validator: _validateAmount,
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _name.text.trim();
    final amounts = <int, double>{
      for (final e in _amounts.entries)
        // Fields in groups never opened skip validation, so parse safely.
        e.key: ?_parseAmount(e.value.text),
    };
    final servings = [
      for (final s in _servings)
        ServingDraft(
          label: s.label.text.trim(),
          grams: double.parse(s.grams.text.trim()),
        ),
    ];
    final foods = ref.read(foodRepositoryProvider);
    final food = widget.food;
    if (food == null) {
      await foods.createCustomFood(name, amounts, servings: servings);
    } else {
      await foods.updateCustomFood(food.id, name, amounts, servings: servings);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.food == null ? 'Create food' : 'Edit food'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 24),
            Text('Nutrients per 100 g', style: theme.textTheme.titleSmall),
            for (final n in widget.nutrients)
              if (_headlineCodes.contains(n.code)) _amountField(n),
            const SizedBox(height: 8),
            // The rest in collapsible groups, opened where values exist.
            for (final group in NutrientGroup.values)
              if (_inGroup(group) case final members when members.isNotEmpty)
                ExpansionTile(
                  title: Text(_groupTitle(group)),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  // Fields stay alive once opened, so they are validated.
                  maintainState: true,
                  initiallyExpanded: members.any(
                    (n) => _amounts[n.id]!.text.isNotEmpty,
                  ),
                  children: [for (final n in members) _amountField(n)],
                ),
            const SizedBox(height: 24),
            Text('Serving sizes', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Optional. For example "1 bar" weighing 60 g.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            for (final serving in _servings)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: serving.label,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Enter a name' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: serving.grams,
                      keyboardType: _decimalKeyboard,
                      decoration: const InputDecoration(
                        labelText: 'Weight',
                        suffixText: 'g',
                      ),
                      validator: _validateWeight,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Remove serving',
                    onPressed: () => setState(() {
                      _servings.remove(serving);
                      serving.dispose();
                    }),
                  ),
                ],
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add serving size'),
                onPressed: () =>
                    setState(() => _servings.add(_ServingFields())),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _decimalKeyboard = TextInputType.numberWithOptions(decimal: true);

/// Always visible at the top; the rest are grouped below.
const _headlineCodes = {
  NutrientCodes.energy,
  NutrientCodes.protein,
  NutrientCodes.carbs,
  NutrientCodes.fat,
};

String _groupTitle(NutrientGroup group) => switch (group) {
  NutrientGroup.general => 'Water, alcohol, caffeine',
  NutrientGroup.carbohydrates => 'Carbohydrate details',
  NutrientGroup.lipids => 'Fat details',
  NutrientGroup.protein => 'Amino acids',
  NutrientGroup.vitamins => 'Vitamins',
  NutrientGroup.minerals => 'Minerals',
};

/// A valid amount, or null for a blank or invalid entry.
double? _parseAmount(String text) {
  final value = double.tryParse(text.trim());
  return value == null || value < 0 ? null : value;
}

String _trimmed(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

String? _validateAmount(String? input) {
  final text = input?.trim() ?? '';
  if (text.isEmpty) return null;
  final value = double.tryParse(text);
  return value == null || value < 0 ? 'Enter a valid amount' : null;
}

String? _validateWeight(String? input) {
  final value = double.tryParse(input?.trim() ?? '');
  return value == null || value <= 0 ? 'Enter a weight' : null;
}
