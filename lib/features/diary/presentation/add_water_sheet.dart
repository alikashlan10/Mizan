import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/features/diary/data/diary_repository.dart';

const _quickAmountsMl = [250, 330, 500, 750];

/// Logs water on [day], from a quick amount or a typed one.
Future<void> showAddWaterSheet(BuildContext context, DateTime day) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AddWaterSheet(day: day),
  );
}

class _AddWaterSheet extends ConsumerStatefulWidget {
  const _AddWaterSheet({required this.day});

  final DateTime day;

  @override
  ConsumerState<_AddWaterSheet> createState() => _AddWaterSheetState();
}

class _AddWaterSheetState extends ConsumerState<_AddWaterSheet> {
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  Future<void> _add(double ml) async {
    await ref.read(diaryRepositoryProvider).addWater(day: widget.day, ml: ml);
    if (mounted) Navigator.of(context).pop();
  }

  void _addCustom() {
    final ml = double.tryParse(_custom.text.trim());
    if (ml != null && ml > 0) _add(ml);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add water', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final ml in _quickAmountsMl)
                ActionChip(
                  label: Text('$ml ml'),
                  onPressed: () => _add(ml.toDouble()),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _custom,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Other amount',
                    suffixText: 'ml',
                  ),
                  onSubmitted: (_) => _addCustom(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(onPressed: _addCustom, child: const Text('Add')),
            ],
          ),
        ],
      ),
    );
  }
}
