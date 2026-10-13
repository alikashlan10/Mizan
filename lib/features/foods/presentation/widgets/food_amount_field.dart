import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/formatting/amount_format.dart';
import 'package:mizan/features/foods/domain/food_serving.dart';
import 'package:mizan/features/foods/presentation/food_providers.dart';

/// Enters an amount of a food as a number of grams or of one of the food's
/// serving sizes.
class FoodAmountField extends ConsumerStatefulWidget {
  const FoodAmountField({
    required this.foodId,
    required this.onChanged,
    this.initial = const FoodAmount.grams(100),
    super.key,
  });

  final int foodId;
  final FoodAmount initial;

  /// Called with the amount entered, or null while it is not a valid number.
  final ValueChanged<FoodAmount?> onChanged;

  @override
  ConsumerState<FoodAmountField> createState() => _FoodAmountFieldState();
}

class _FoodAmountFieldState extends ConsumerState<FoodAmountField> {
  late final _quantity = TextEditingController(
    text: _trimmed(widget.initial.quantity),
  );
  late FoodServing? _serving = widget.initial.serving;

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  FoodAmount? get _amount {
    final quantity = double.tryParse(_quantity.text.trim());
    return quantity == null || quantity <= 0
        ? null
        : FoodAmount(quantity: quantity, serving: _serving);
  }

  void _selectServing(FoodServing? serving) {
    setState(() {
      // Grams and servings count differently, so start from a sensible number.
      if ((serving == null) != (_serving == null)) {
        _quantity.text = serving == null ? '100' : '1';
      }
      _serving = serving;
    });
    widget.onChanged(_amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final servings =
        ref.watch(foodServingsProvider(widget.foodId)).value ?? const [];
    final amount = _amount;
    final selectedId = servings.any((s) => s.id == _serving?.id)
        ? _serving?.id
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _quantity,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Amount'),
                onChanged: (_) {
                  setState(() {});
                  widget.onChanged(_amount);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: DropdownButtonFormField<int?>(
                // Rebuilt when the servings arrive so the selection shows.
                key: ValueKey(servings.length),
                initialValue: selectedId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Unit'),
                items: [
                  const DropdownMenuItem(child: Text('grams')),
                  for (final s in servings)
                    DropdownMenuItem(
                      value: s.id,
                      child: Text(
                        '${s.label} (${formatAmount(s.grams)} g)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) => _selectServing(
                  id == null ? null : servings.firstWhere((s) => s.id == id),
                ),
              ),
            ),
          ],
        ),
        if (_serving != null && amount != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '= ${formatAmount(amount.grams)} g',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

String _trimmed(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
