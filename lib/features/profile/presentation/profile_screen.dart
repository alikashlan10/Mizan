import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/domain/display_units.dart';
import 'package:mizan/features/backup/presentation/backup_screen.dart';
import 'package:mizan/features/profile/data/profile_repository.dart';
import 'package:mizan/features/profile/domain/calorie_calculator.dart';
import 'package:mizan/features/profile/domain/macro_targets.dart';
import 'package:mizan/features/profile/domain/profile.dart';
import 'package:mizan/features/profile/presentation/profile_labels.dart';
import 'package:mizan/features/profile/presentation/profile_providers.dart';
import 'package:mizan/features/settings/presentation/display_settings_screen.dart';
import 'package:mizan/features/settings/presentation/settings_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_backup_restore),
            tooltip: 'Backup',
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const BackupScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Display settings',
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const DisplaySettingsScreen()),
            ),
          ),
        ],
      ),
      body: profile.hasValue
          ? _ProfileForm(initial: profile.value)
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.initial});

  final Profile? initial;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _age = TextEditingController(text: widget.initial?.age.toString());
  late final _height = _numberController(widget.initial?.heightCm);
  late final _weight = _numberController(widget.initial?.weightKg);

  /// Energy is entered in the user's unit and stored in kcal.
  late final DisplayUnits _units = ref.read(displayUnitsProvider);
  late final _customTarget = _numberController(
    switch (widget.initial?.customTargetKcal) {
      final kcal? => _units.energyValue(kcal).roundToDouble(),
      null => null,
    },
  );
  late Sex _sex = widget.initial?.sex ?? Sex.male;
  late ActivityLevel _activity =
      widget.initial?.activity ?? ActivityLevel.sedentary;
  late Goal _goal = widget.initial?.goal ?? Goal.maintain;
  late MacroTargetMode _macroMode =
      widget.initial?.macros.mode ?? MacroTargetMode.standard;
  late final _protein = _numberController(
    widget.initial?.macros.values?.protein,
  );
  late final _carbs = _numberController(widget.initial?.macros.values?.carbs);
  late final _fat = _numberController(widget.initial?.macros.values?.fat);

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _customTarget.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  /// The three macro fields as numbers, or null while one is invalid.
  MacroValues? get _macroValues {
    final protein = double.tryParse(_protein.text.trim());
    final carbs = double.tryParse(_carbs.text.trim());
    final fat = double.tryParse(_fat.text.trim());
    if (protein == null || carbs == null || fat == null) return null;
    if (protein < 0 || carbs < 0 || fat < 0) return null;
    return MacroValues(protein: protein, carbs: carbs, fat: fat);
  }

  bool get _percentsAddUp {
    final v = _macroValues;
    return v != null && (v.protein + v.carbs + v.fat - 100).abs() < 0.5;
  }

  /// The macro targets as currently entered, or null while they are invalid.
  MacroSetting? get _macroDraft {
    final values = _macroValues;
    return switch (_macroMode) {
      MacroTargetMode.standard => const MacroSetting.standard(),
      MacroTargetMode.percent =>
        values == null || !_percentsAddUp ? null : MacroSetting.percent(values),
      MacroTargetMode.grams =>
        values == null ? null : MacroSetting.grams(values),
    };
  }

  /// Switches how macro targets are set, pre-filling the fields so the user
  /// starts from sensible numbers.
  void _setMacroMode(MacroTargetMode mode) {
    final draft = _draft;
    final grams = draft == null
        ? null
        : macroTargetGrams(
            draft.macros,
            targetKcal: estimateCalories(draft).targetKcal,
          );
    final prefill = switch (mode) {
      MacroTargetMode.standard => null,
      MacroTargetMode.percent => standardMacroPercents,
      MacroTargetMode.grams => grams,
    };
    setState(() {
      _macroMode = mode;
      if (prefill != null) {
        _protein.text = prefill.protein.round().toString();
        _carbs.text = prefill.carbs.round().toString();
        _fat.text = prefill.fat.round().toString();
      }
    });
  }

  String? _validateMacro(String? input) {
    final value = double.tryParse(input?.trim() ?? '');
    return value == null || value < 0 ? 'Enter an amount' : null;
  }

  /// The profile as currently entered, or null while a field is invalid.
  /// Invalid macro fields fall back to the standard split so the calorie
  /// figures can still be shown.
  Profile? get _draft {
    final age = int.tryParse(_age.text.trim());
    final height = double.tryParse(_height.text.trim());
    final weight = double.tryParse(_weight.text.trim());
    final customText = _customTarget.text.trim();
    final custom = double.tryParse(customText);
    if (_validateAge(_age.text) != null ||
        _validateHeight(_height.text) != null ||
        _validateWeight(_weight.text) != null ||
        _validateCustomTarget(customText, _units) != null) {
      return null;
    }
    return Profile(
      sex: _sex,
      age: age!,
      heightCm: height!,
      weightKg: weight!,
      activity: _activity,
      goal: _goal,
      customTargetKcal: customText.isEmpty || custom == null
          ? null
          : _units.kcalFrom(custom),
      macros: _macroDraft ?? const MacroSetting.standard(),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _macroDraft == null) return;
    await ref.read(profileRepositoryProvider).saveProfile(_draft!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Profile saved')));
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    void refresh(String _) => setState(() {});

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _EstimateCard(
            estimate: draft == null ? null : estimateCalories(draft),
            isCustom: draft?.customTargetKcal != null,
            units: _units,
          ),
          const SizedBox(height: 16),
          SegmentedButton<Sex>(
            segments: [
              for (final sex in Sex.values)
                ButtonSegment(value: sex, label: Text(sex.label)),
            ],
            selected: {_sex},
            onSelectionChanged: (s) => setState(() => _sex = s.single),
          ),
          TextFormField(
            controller: _age,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Age',
              suffixText: 'years',
            ),
            validator: _validateAge,
            onChanged: refresh,
          ),
          TextFormField(
            controller: _height,
            keyboardType: _decimalKeyboard,
            decoration: const InputDecoration(
              labelText: 'Height',
              suffixText: 'cm',
            ),
            validator: _validateHeight,
            onChanged: refresh,
          ),
          TextFormField(
            controller: _weight,
            keyboardType: _decimalKeyboard,
            decoration: const InputDecoration(
              labelText: 'Weight',
              suffixText: 'kg',
            ),
            validator: _validateWeight,
            onChanged: refresh,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ActivityLevel>(
            initialValue: _activity,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Activity level',
              helperText: _activity.description,
            ),
            items: [
              for (final level in ActivityLevel.values)
                DropdownMenuItem(value: level, child: Text(level.label)),
            ],
            onChanged: (level) => setState(() => _activity = level!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Goal>(
            initialValue: _goal,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Goal',
              helperText:
                  '${_goal.offsetLabel(_units)} per day from maintenance',
            ),
            items: [
              for (final goal in Goal.values)
                DropdownMenuItem(value: goal, child: Text(goal.label)),
            ],
            onChanged: (goal) => setState(() => _goal = goal!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _customTarget,
            keyboardType: _decimalKeyboard,
            decoration: InputDecoration(
              labelText: 'Custom daily target (optional)',
              helperText: 'Replaces the calculated target',
              suffixText: _units.energyLabel,
            ),
            validator: (v) => _validateCustomTarget(v, _units),
            onChanged: refresh,
          ),
          const SizedBox(height: 24),
          Text('Macro targets', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<MacroTargetMode>(
            segments: [
              for (final mode in MacroTargetMode.values)
                ButtonSegment(value: mode, label: Text(mode.label)),
            ],
            selected: {_macroMode},
            onSelectionChanged: (s) => _setMacroMode(s.single),
          ),
          if (_macroMode != MacroTargetMode.standard)
            for (final (label, controller) in [
              ('Protein', _protein),
              ('Carbohydrates', _carbs),
              ('Fat', _fat),
            ])
              TextFormField(
                controller: controller,
                keyboardType: _decimalKeyboard,
                decoration: InputDecoration(
                  labelText: label,
                  suffixText: _macroMode == MacroTargetMode.percent ? '%' : 'g',
                ),
                validator: _validateMacro,
                onChanged: refresh,
              ),
          const SizedBox(height: 8),
          _MacroSummary(
            mode: _macroMode,
            values: _macroValues,
            percentsAddUp: _percentsAddUp,
            targets: draft == null || _macroDraft == null
                ? null
                : macroTargetGrams(
                    draft.macros,
                    targetKcal: estimateCalories(draft).targetKcal,
                  ),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}

/// Explains the macro targets that the current entries produce.
class _MacroSummary extends StatelessWidget {
  const _MacroSummary({
    required this.mode,
    required this.values,
    required this.percentsAddUp,
    required this.targets,
  });

  final MacroTargetMode mode;
  final MacroValues? values;
  final bool percentsAddUp;

  /// Resulting daily targets in grams; null while they cannot be worked out.
  final MacroValues? targets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values = this.values;
    final targets = this.targets;

    if (mode == MacroTargetMode.percent && values != null && !percentsAddUp) {
      final total = (values.protein + values.carbs + values.fat).round();
      return Text(
        'Percentages must add up to 100% (now $total%)',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }
    return Text(
      targets == null
          ? 'Enter your details above to see your macro targets.'
          : 'Daily targets: protein ${targets.protein.round()} g · '
                'carbs ${targets.carbs.round()} g · '
                'fat ${targets.fat.round()} g',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({
    required this.estimate,
    required this.isCustom,
    required this.units,
  });

  final DisplayUnits units;

  final CalorieEstimate? estimate;
  final bool isCustom;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final estimate = this.estimate;

    Widget figure(String label, double kcal) => Column(
      children: [
        Text(units.energy(kcal), style: text.titleMedium),
        Text(label, style: text.bodySmall),
      ],
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: estimate == null
            ? const Text(
                'Enter your details to calculate your daily calories.',
                textAlign: TextAlign.center,
              )
            : Column(
                children: [
                  Text(
                    units.energy(estimate.targetKcal),
                    style: text.headlineMedium,
                  ),
                  Text(
                    isCustom ? 'Custom daily target' : 'Daily target',
                    style: text.bodySmall,
                  ),
                  if (estimate.raisedToMinimum)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Raised to the ${units.energy(minimumTargetKcal)} '
                        'minimum',
                        style: text.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      figure('Resting', estimate.restingKcal),
                      figure('Maintenance', estimate.maintenanceKcal),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

const _decimalKeyboard = TextInputType.numberWithOptions(decimal: true);

TextEditingController _numberController(double? value) {
  if (value == null) return TextEditingController();
  final isWhole = value == value.roundToDouble();
  return TextEditingController(
    text: isWhole ? value.toInt().toString() : value.toString(),
  );
}

String? _validateRange(String? input, num min, num max, {bool whole = false}) {
  final text = input?.trim() ?? '';
  final value = whole ? int.tryParse(text) : double.tryParse(text);
  return value == null || value < min || value > max
      ? 'Enter a value from $min to $max'
      : null;
}

String? _validateAge(String? input) =>
    _validateRange(input, 10, 120, whole: true);

String? _validateHeight(String? input) => _validateRange(input, 80, 250);

String? _validateWeight(String? input) => _validateRange(input, 20, 400);

/// Between 500 and 10,000 kcal, checked in the unit the user types in.
String? _validateCustomTarget(String? input, DisplayUnits units) =>
    (input?.trim() ?? '').isEmpty
    ? null
    : _validateRange(
        input,
        units.energyValue(500).round(),
        units.energyValue(10000).round(),
      );
