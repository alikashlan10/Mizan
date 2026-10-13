import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/domain/meal.dart';
import 'package:mizan/features/diary/data/diary_repository.dart';
import 'package:mizan/features/diary/presentation/diary_providers.dart';
import 'package:mizan/features/diary/presentation/meal_labels.dart';

/// Asks for an amount and meal, then logs [food] on the selected day.
/// [meal] is the section offered first. Returns whether an entry was added.
Future<bool> showAddEntryDialog(
  BuildContext context,
  Food food, {
  Meal meal = Meal.breakfast,
}) async {
  final added = await showDialog<bool>(
    context: context,
    builder: (_) => _AddEntryDialog(food: food, meal: meal),
  );
  return added ?? false;
}

class _AddEntryDialog extends ConsumerStatefulWidget {
  const _AddEntryDialog({required this.food, required this.meal});

  final Food food;
  final Meal meal;

  @override
  ConsumerState<_AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends ConsumerState<_AddEntryDialog> {
  final _grams = TextEditingController(text: '100');
  late Meal _meal = widget.meal;

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final grams = double.tryParse(_grams.text);
    if (grams == null || grams <= 0) return;
    await ref
        .read(diaryRepositoryProvider)
        .addEntry(
          day: ref.read(selectedDayProvider),
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
                DropdownMenuItem(value: meal, child: Text(meal.label)),
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
