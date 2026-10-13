import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/features/profile/data/profile_repository.dart';
import 'package:mizan/features/profile/domain/calorie_calculator.dart';
import 'package:mizan/features/profile/domain/profile.dart';
import 'package:mizan/features/profile/presentation/profile_labels.dart';
import 'package:mizan/features/profile/presentation/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
  late final _customTarget = _numberController(
    widget.initial?.customTargetKcal,
  );
  late Sex _sex = widget.initial?.sex ?? Sex.male;
  late ActivityLevel _activity =
      widget.initial?.activity ?? ActivityLevel.sedentary;
  late Goal _goal = widget.initial?.goal ?? Goal.maintain;

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _customTarget.dispose();
    super.dispose();
  }

  /// The profile as currently entered, or null while a field is invalid.
  Profile? get _draft {
    final age = int.tryParse(_age.text.trim());
    final height = double.tryParse(_height.text.trim());
    final weight = double.tryParse(_weight.text.trim());
    final customText = _customTarget.text.trim();
    final custom = double.tryParse(customText);
    if (_validateAge(_age.text) != null ||
        _validateHeight(_height.text) != null ||
        _validateWeight(_weight.text) != null ||
        _validateCustomTarget(customText) != null) {
      return null;
    }
    return Profile(
      sex: _sex,
      age: age!,
      heightCm: height!,
      weightKg: weight!,
      activity: _activity,
      goal: _goal,
      customTargetKcal: customText.isEmpty ? null : custom,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
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
              helperText: '${_goal.offsetLabel} per day from maintenance',
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
            decoration: const InputDecoration(
              labelText: 'Custom daily target (optional)',
              helperText: 'Replaces the calculated target',
              suffixText: 'kcal',
            ),
            validator: _validateCustomTarget,
            onChanged: refresh,
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({required this.estimate, required this.isCustom});

  final CalorieEstimate? estimate;
  final bool isCustom;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final estimate = this.estimate;

    Widget figure(String label, double kcal) => Column(
      children: [
        Text('${kcal.round()} kcal', style: text.titleMedium),
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
                    '${estimate.targetKcal.round()} kcal',
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
                        'Raised to the ${minimumTargetKcal.round()} kcal '
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

String? _validateCustomTarget(String? input) =>
    (input?.trim() ?? '').isEmpty ? null : _validateRange(input, 500, 10000);
