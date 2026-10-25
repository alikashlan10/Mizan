import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/domain/display_units.dart';
import 'package:mizan/features/foods/domain/food_serving.dart';
import 'package:mizan/features/foods/presentation/food_providers.dart';
import 'package:mizan/features/settings/presentation/settings_providers.dart';

/// Enters an amount of a food as a weight (in the user's weight unit) or as
/// a number of one of the food's serving sizes.
class FoodAmountField extends ConsumerStatefulWidget {
  const FoodAmountField({
    required this.foodId,
    required this.onChanged,
    this.initial,
    super.key,
  });

  final int foodId;

  /// The amount to start from; null starts from the user's preferred
  /// starting amount, reported through [onChanged] once it is known.
  final FoodAmount? initial;

  /// Called with the amount entered, or null while it is not a valid number.
  final ValueChanged<FoodAmount?> onChanged;

  @override
  ConsumerState<FoodAmountField> createState() => _FoodAmountFieldState();
}

class _FoodAmountFieldState extends ConsumerState<FoodAmountField> {
  late final DisplayUnits _units = ref.read(displayUnitsProvider);
  late final _quantity = TextEditingController(text: _initialQuantity());
  late FoodServing? _serving = widget.initial?.serving;

  /// Whether the starting amount still needs choosing from the preference,
  /// once the servings are known.
  late bool _awaitingDefault = widget.initial == null;

  String _initialQuantity() {
    final initial = widget.initial;
    if (initial == null) return _trimmed(_units.weightValue(100));
    if (initial.serving != null) return _trimmed(initial.quantity);
    return _trimmed(_units.weightValue(initial.grams));
  }

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  FoodAmount? get _amount {
    final quantity = double.tryParse(_quantity.text.trim());
    if (quantity == null || quantity <= 0) return null;
    final serving = _serving;
    return serving == null
        // A weight, entered in the user's unit.
        ? FoodAmount.grams(
            _units.weightUnit == WeightUnit.grams
                ? quantity
                : quantity * gramsPerOunce,
          )
        : FoodAmount(quantity: quantity, serving: serving);
  }

  void _selectServing(FoodServing? serving) {
    _awaitingDefault = false;
    setState(() {
      // Weights and servings count differently, so start from a sensible
      // number.
      if ((serving == null) != (_serving == null)) {
        _quantity.text = serving == null
            ? _trimmed(_units.weightValue(100))
            : '1';
      }
      _serving = serving;
    });
    widget.onChanged(_amount);
  }

  /// Starts at one serving when the user prefers that and the food has one.
  void _applyDefault(List<FoodServing> servings) {
    _awaitingDefault = false;
    if (_units.defaultAmount != DefaultAmount.perServing || servings.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _serving = servings.first;
        _quantity.text = '1';
      });
      widget.onChanged(_amount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final servingsValue = ref.watch(foodServingsProvider(widget.foodId));
    final servings = servingsValue.value ?? const [];
    if (_awaitingDefault && servingsValue.hasValue) _applyDefault(servings);
    final amount = _amount;
    final selectedId = servings.any((s) => s.id == _serving?.id)
        ? _serving?.id
        : null;

    return Column(
      // Only as tall as its content, so it does not stretch a dialog.
      mainAxisSize: MainAxisSize.min,
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
                  _awaitingDefault = false;
                  setState(() {});
                  widget.onChanged(_amount);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: DropdownButtonFormField<int?>(
                // Rebuilt when the servings arrive or the starting serving is
                // chosen, so the selection shows.
                key: ValueKey('${servings.length}-$selectedId'),
                initialValue: selectedId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Unit'),
                items: [
                  DropdownMenuItem(
                    child: Text(
                      _units.weightUnit == WeightUnit.grams
                          ? 'grams'
                          : 'ounces',
                    ),
                  ),
                  for (final s in servings)
                    DropdownMenuItem(
                      value: s.id,
                      child: Text(
                        '${s.label} (${_units.weight(s.grams)})',
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
              '= ${_units.weight(amount.grams)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

String _trimmed(double value) {
  final rounded = (value * 10).round() / 10;
  return rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toString();
}
