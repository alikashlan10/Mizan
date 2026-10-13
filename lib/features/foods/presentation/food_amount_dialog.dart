import 'package:flutter/material.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/features/foods/domain/food_serving.dart';
import 'package:mizan/features/foods/presentation/widgets/food_amount_field.dart';

/// Asks how much of [food]; returns null when cancelled.
Future<FoodAmount?> showFoodAmountDialog(BuildContext context, Food food) {
  return showDialog<FoodAmount>(
    context: context,
    builder: (_) => _FoodAmountDialog(food: food),
  );
}

class _FoodAmountDialog extends StatefulWidget {
  const _FoodAmountDialog({required this.food});

  final Food food;

  @override
  State<_FoodAmountDialog> createState() => _FoodAmountDialogState();
}

class _FoodAmountDialogState extends State<_FoodAmountDialog> {
  /// Null while the amount field does not hold a valid number.
  FoodAmount? _amount = const FoodAmount.grams(100);

  @override
  Widget build(BuildContext context) {
    final amount = _amount;

    return AlertDialog(
      title: Text(widget.food.name),
      content: SizedBox(
        width: double.maxFinite,
        child: FoodAmountField(
          foodId: widget.food.id,
          onChanged: (amount) => setState(() => _amount = amount),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: amount == null
              ? null
              : () => Navigator.of(context).pop(amount),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
