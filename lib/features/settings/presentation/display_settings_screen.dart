import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/domain/display_units.dart';
import 'package:mizan/features/settings/data/settings_repository.dart';
import 'package:mizan/features/settings/presentation/settings_providers.dart';

/// Units and default amounts. Changes apply immediately.
class DisplaySettingsScreen extends ConsumerWidget {
  const DisplaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final units = ref.watch(displayUnitsProvider);
    void save(DisplayUnits changed) =>
        ref.read(settingsRepositoryProvider).saveDisplayUnits(changed);

    Widget section<T>({
      required String title,
      required String help,
      required List<(T, String)> options,
      required T selected,
      required void Function(T) onSelected,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            help,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<T>(
            segments: [
              for (final (value, label) in options)
                ButtonSegment(value: value, label: Text(label)),
            ],
            selected: {selected},
            onSelectionChanged: (s) => onSelected(s.single),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Display')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          section(
            title: 'Energy',
            help: 'Calories (kcal) or kilojoules (kJ).',
            options: const [(EnergyUnit.kcal, 'kcal'), (EnergyUnit.kj, 'kJ')],
            selected: units.energyUnit,
            onSelected: (u) => save(units.copyWith(energyUnit: u)),
          ),
          section(
            title: 'Food weight',
            help:
                'How amounts of food are shown and entered. Nutrients such as '
                'protein stay in grams.',
            options: const [
              (WeightUnit.grams, 'Grams'),
              (WeightUnit.ounces, 'Ounces'),
            ],
            selected: units.weightUnit,
            onSelected: (u) => save(units.copyWith(weightUnit: u)),
          ),
          section(
            title: 'Water',
            help: 'How water is shown and logged.',
            options: const [
              (VolumeUnit.ml, 'Millilitres'),
              (VolumeUnit.flOz, 'Fluid ounces'),
            ],
            selected: units.volumeUnit,
            onSelected: (u) => save(units.copyWith(volumeUnit: u)),
          ),
          section(
            title: 'Starting amount',
            help:
                'What a food\'s nutrition facts and the add-to-diary amount '
                'start at. Foods without serving sizes always start at 100 g.',
            options: const [
              (DefaultAmount.per100g, '100 g'),
              (DefaultAmount.perServing, 'One serving'),
            ],
            selected: units.defaultAmount,
            onSelected: (a) => save(units.copyWith(defaultAmount: a)),
          ),
        ],
      ),
    );
  }
}
