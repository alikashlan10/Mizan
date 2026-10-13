import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mizan/core/domain/meal.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/core/formatting/amount_format.dart';
import 'package:mizan/features/diary/data/diary_repository.dart';
import 'package:mizan/features/diary/domain/diary_item.dart';
import 'package:mizan/features/diary/presentation/add_entry_dialog.dart';
import 'package:mizan/features/diary/presentation/diary_providers.dart';
import 'package:mizan/features/diary/presentation/meal_labels.dart';
import 'package:mizan/features/foods/presentation/food_search_screen.dart';

class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  Future<void> _pickDay(BuildContext context, WidgetRef ref) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: ref.read(selectedDayProvider),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) ref.read(selectedDayProvider.notifier).select(picked);
  }

  void _addFood(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => FoodSearchScreen(
          autofocus: true,
          onFoodSelected: (context, food) async {
            final added = await showAddEntryDialog(context, food);
            if (added && context.mounted) Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDayProvider);
    final entries = ref.watch(dayEntriesProvider).value ?? const [];
    final totals = ref.watch(dayTotalsProvider).value ?? const {};
    final isToday = DateUtils.isSameDay(day, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous day',
          onPressed: () => ref.read(selectedDayProvider.notifier).shift(-1),
        ),
        title: TextButton(
          onPressed: () => _pickDay(context, ref),
          child: Text(
            isToday ? 'Today' : DateFormat.yMMMEd().format(day),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next day',
            onPressed: () => ref.read(selectedDayProvider.notifier).shift(1),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          _SummaryCard(totals: totals),
          for (final meal in Meal.values)
            _MealSection(
              meal: meal,
              items: entries.where((e) => e.meal == meal).toList(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add food'),
        onPressed: () => _addFood(context),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totals});

  final Map<String, double> totals;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget macro(String label, String code) => Column(
      children: [
        Text('${formatAmount(totals[code] ?? 0)} g', style: text.titleMedium),
        Text(label, style: text.bodySmall),
      ],
    );

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '${(totals[NutrientCodes.energy] ?? 0).round()} kcal',
              style: text.headlineMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                macro('Protein', NutrientCodes.protein),
                macro('Carbs', NutrientCodes.carbs),
                macro('Fat', NutrientCodes.fat),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MealSection extends ConsumerWidget {
  const _MealSection({required this.meal, required this.items});

  final Meal meal;
  final List<DiaryItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kcal = items.fold<double>(0, (sum, e) => sum + (e.kcal ?? 0));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(meal.label, style: Theme.of(context).textTheme.titleMedium),
              Text('${kcal.round()} kcal'),
            ],
          ),
        ),
        for (final item in items)
          Dismissible(
            key: ValueKey(item.entryId),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Theme.of(context).colorScheme.errorContainer,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.delete),
            ),
            onDismissed: (_) =>
                ref.read(diaryRepositoryProvider).deleteEntry(item.entryId),
            child: ListTile(
              title: Text(item.foodName),
              subtitle: Text('${formatAmount(item.grams)} g'),
              trailing: Text(
                item.kcal == null ? '—' : '${item.kcal!.round()} kcal',
              ),
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }
}
