import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/features/diary/data/diary_repository.dart';
import 'package:mizan/features/settings/presentation/settings_providers.dart';

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
    final value = double.tryParse(_custom.text.trim());
    if (value != null && value > 0) {
      _add(ref.read(displayUnitsProvider).mlFrom(value));
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(displayUnitsProvider);
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
              for (final ml in units.quickWaterMl)
                ActionChip(
                  label: Text(units.volume(ml)),
                  onPressed: () => _add(ml),
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
                  decoration: InputDecoration(
                    labelText: 'Other amount',
                    suffixText: units.volumeLabel,
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
