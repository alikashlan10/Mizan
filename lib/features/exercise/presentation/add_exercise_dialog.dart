import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/features/exercise/data/exercise_repository.dart';
import 'package:mizan/features/exercise/domain/exercise.dart';
import 'package:mizan/features/exercise/presentation/exercise_labels.dart';
import 'package:mizan/features/profile/presentation/profile_providers.dart';
import 'package:mizan/features/settings/presentation/settings_providers.dart';

/// Logs an exercise on [day], estimating calories from the profile's weight.
Future<void> showAddExerciseDialog(BuildContext context, DateTime day) {
  return showDialog<void>(
    context: context,
    builder: (_) => _AddExerciseDialog(day: day),
  );
}

class _AddExerciseDialog extends ConsumerStatefulWidget {
  const _AddExerciseDialog({required this.day});

  final DateTime day;

  @override
  ConsumerState<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends ConsumerState<_AddExerciseDialog> {
  final _minutes = TextEditingController(text: '30');
  ExerciseType _type = ExerciseType.walking;

  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  /// Session length, or null while the entered duration is invalid.
  double? get _duration {
    final fixed = _type.fixedMinutes;
    if (fixed != null) return fixed;
    final minutes = double.tryParse(_minutes.text.trim());
    return minutes == null || minutes <= 0 ? null : minutes;
  }

  Future<void> _save(double minutes, double kcal) async {
    await ref
        .read(exerciseRepositoryProvider)
        .addEntry(day: widget.day, type: _type, minutes: minutes, kcal: kcal);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final weightKg = ref.watch(profileProvider).value?.weightKg;
    if (weightKg == null) {
      return AlertDialog(
        title: const Text('Add exercise'),
        content: const Text(
          'Save your weight in the Profile tab first, so the calories burned '
          'can be estimated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    }

    final minutes = _duration;
    final kcal = minutes == null
        ? null
        : exerciseKcal(_type, weightKg: weightKg, minutes: minutes);

    return AlertDialog(
      title: const Text('Add exercise'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<ExerciseType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Exercise'),
            items: [
              for (final type in ExerciseType.values)
                DropdownMenuItem(value: type, child: Text(type.label)),
            ],
            onChanged: (type) => setState(() => _type = type!),
          ),
          if (_type.fixedMinutes == null)
            TextField(
              controller: _minutes,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Duration',
                suffixText: 'min',
              ),
              onChanged: (_) => setState(() {}),
            ),
          const SizedBox(height: 16),
          Text(
            kcal == null
                ? 'Enter a duration'
                : 'About ${ref.watch(displayUnitsProvider).energy(kcal)} burned',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: kcal == null ? null : () => _save(minutes!, kcal),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
