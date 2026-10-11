import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../providers.dart';

/// Creates a custom food. Pops with `true` once the food is saved.
class FoodFormScreen extends ConsumerStatefulWidget {
  const FoodFormScreen({super.key});

  @override
  ConsumerState<FoodFormScreen> createState() => _FoodFormScreenState();
}

class _FoodFormScreenState extends ConsumerState<FoodFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amounts = <int, TextEditingController>{};
  late final Future<List<Nutrient>> _nutrients = ref
      .read(dbProvider)
      .allNutrients();

  @override
  void dispose() {
    _name.dispose();
    for (final c in _amounts.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amounts = <int, double>{
      for (final e in _amounts.entries)
        if (e.value.text.trim().isNotEmpty)
          e.key: double.parse(e.value.text.trim()),
    };
    await ref.read(dbProvider).createCustomFood(_name.text.trim(), amounts);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create food'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: FutureBuilder<List<Nutrient>>(
        future: _nutrients,
        builder: (context, snapshot) {
          final nutrients = snapshot.data;
          if (nutrients == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 24),
                Text(
                  'Nutrients per 100 g',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (final n in nutrients)
                  TextFormField(
                    controller: _amounts.putIfAbsent(
                      n.id,
                      TextEditingController.new,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: n.name,
                      suffixText: n.unit,
                    ),
                    validator: (v) {
                      final text = v?.trim() ?? '';
                      if (text.isEmpty) return null;
                      final value = double.tryParse(text);
                      return value == null || value < 0
                          ? 'Enter a valid amount'
                          : null;
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
