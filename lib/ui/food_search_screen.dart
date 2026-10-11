import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/food_seed.dart';
import '../providers.dart';
import 'diary_screen.dart';
import 'food_form_screen.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  late Future<List<Food>> _results;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _results = ref.read(dbProvider).searchFoods(_query);
  }

  void _search(String query) {
    setState(() {
      _query = query;
      _results = ref.read(dbProvider).searchFoods(query);
    });
  }

  Future<void> _createFood() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const FoodFormScreen()),
    );
    if (created == true) _search(_query);
  }

  Future<void> _addToDiary(Food food) async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => _AddEntryDialog(food: food),
    );
    if (added == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(seedProvider, (_, seed) {
      if (!seed.isLoading) _search(_query);
    });
    if (ref.watch(seedProvider).isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add food')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparing the food database…'),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search foods',
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create food',
            onPressed: _createFood,
          ),
        ],
      ),
      body: FutureBuilder<List<Food>>(
        future: _results,
        builder: (context, snapshot) {
          final foods = snapshot.data;
          if (foods == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (foods.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No foods found'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create food'),
                    onPressed: _createFood,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: foods.length,
            itemBuilder: (context, i) => ListTile(
              title: Text(foods[i].name),
              subtitle: Text(
                foods[i].source == usdaSource ? 'USDA' : 'Custom',
              ),
              onTap: () => _addToDiary(foods[i]),
            ),
          );
        },
      ),
    );
  }
}

class _AddEntryDialog extends ConsumerStatefulWidget {
  const _AddEntryDialog({required this.food});

  final Food food;

  @override
  ConsumerState<_AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends ConsumerState<_AddEntryDialog> {
  final _grams = TextEditingController(text: '100');
  Meal _meal = Meal.breakfast;

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final grams = double.tryParse(_grams.text);
    if (grams == null || grams <= 0) return;
    await ref.read(dbProvider).addEntry(
      day: dayKey(ref.read(selectedDayProvider)),
      meal: _meal,
      foodId: widget.food.id,
      grams: grams,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.food.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _grams,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              suffixText: 'g',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Meal>(
            initialValue: _meal,
            decoration: const InputDecoration(labelText: 'Meal'),
            items: [
              for (final meal in Meal.values)
                DropdownMenuItem(value: meal, child: Text(mealLabels[meal]!)),
            ],
            onChanged: (meal) => setState(() => _meal = meal!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Add')),
      ],
    );
  }
}
