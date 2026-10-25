import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/domain/meal.dart';
import 'package:mizan/features/diary/data/diary_repository.dart';
import 'package:mizan/features/diary/presentation/diary_providers.dart';
import 'package:mizan/features/diary/presentation/meal_labels.dart';
import 'package:mizan/features/foods/domain/food_serving.dart';
import 'package:mizan/features/foods/presentation/widgets/food_amount_field.dart';

/// Asks for an amount and meal, then logs [food] on the selected day.
/// [meal] and [amount] are what the dialog offers first. Returns whether an
/// entry was added.
Future<bool> showAddEntryDialog(
  BuildContext context,
  Food food, {
  Meal meal = Meal.breakfast,
  FoodAmount amount = const FoodAmount.grams(100),
}) async {
  final added = await showDialog<bool>(
    context: context,
    builder: (_) => _AddEntryDialog(food: food, meal: meal, amount: amount),
  );
  return added ?? false;
}

class _AddEntryDialog extends ConsumerStatefulWidget {
  const _AddEntryDialog({
    required this.food,
    required this.meal,
    required this.amount,
  });

  final Food food;
  final Meal meal;
  final FoodAmount amount;

  @override
  ConsumerState<_AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends ConsumerState<_AddEntryDialog> {
  /// Null while the amount field does not hold a valid number.
  late FoodAmount? _amount = widget.amount;
  late Meal _meal = widget.meal;

  Future<void> _save(FoodAmount amount) async {
    await ref
        .read(diaryRepositoryProvider)
        .addEntry(
          day: ref.read(selectedDayProvider),
          meal: _meal,
          foodId: widget.food.id,
          grams: amount.grams,
          servingQuantity: amount.serving == null ? null : amount.quantity,
          servingLabel: amount.serving?.label,
        );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amount;

    return AlertDialog(
      title: Text(widget.food.name),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FoodAmountField(
              foodId: widget.food.id,
              initial: widget.amount,
              onChanged: (amount) => setState(() => _amount = amount),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: amount == null ? null : () => _save(amount),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
