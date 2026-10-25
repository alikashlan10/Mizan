import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mizan/core/domain/meal.dart';
import 'package:mizan/core/formatting/amount_format.dart';
import 'package:mizan/features/diary/data/diary_repository.dart';
import 'package:mizan/features/diary/domain/diary_item.dart';
import 'package:mizan/features/diary/presentation/add_entry_dialog.dart';
import 'package:mizan/features/diary/presentation/add_water_sheet.dart';
import 'package:mizan/features/diary/presentation/diary_providers.dart';
import 'package:mizan/features/diary/presentation/meal_labels.dart';
import 'package:mizan/features/diary/presentation/widgets/day_rings_card.dart';
import 'package:mizan/features/diary/presentation/widgets/diary_section.dart';
import 'package:mizan/features/exercise/data/exercise_repository.dart';
import 'package:mizan/features/exercise/presentation/add_exercise_dialog.dart';
import 'package:mizan/features/exercise/presentation/exercise_labels.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDayProvider);
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
        padding: const EdgeInsets.only(bottom: 24),
        children: const [
          DayRingsCard(),
          _MealSection(Meal.breakfast),
          _MealSection(Meal.lunch),
          _MealSection(Meal.dinner),
          _WaterSection(),
          _MealSection(Meal.snacks),
          _MealSection(Meal.other),
          _ExerciseSection(),
        ],
      ),
    );
  }
}

class _MealSection extends ConsumerWidget {
  const _MealSection(this.meal);

  final Meal meal;

  void _addFood(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => FoodSearchScreen(
          autofocus: true,
          onFoodSelected: (context, food) async {
            final added = await showAddEntryDialog(context, food, meal: meal);
            if (added && context.mounted) Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(dayEntriesProvider).value ?? const [];
    final items = [
      for (final e in entries)
        if (e.meal == meal) e,
    ];
    final kcal = items.fold<double>(0, (sum, e) => sum + (e.kcal ?? 0));

    return DiarySection(
      title: meal.label,
      summary: '${kcal.round()} kcal',
      addTooltip: 'Add food to ${meal.label.toLowerCase()}',
      onAdd: () => _addFood(context),
      children: [
        for (final item in items)
          DiaryEntryTile(
            entryKey: item.entryId,
            title: item.foodName,
            subtitle: _amountLabel(item),
            trailing: item.kcal == null ? '—' : '${item.kcal!.round()} kcal',
            onDelete: () =>
                ref.read(diaryRepositoryProvider).deleteEntry(item.entryId),
          ),
      ],
    );
  }
}

class _WaterSection extends ConsumerWidget {
  const _WaterSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(dayWaterProvider).value ?? const [];
    final total = entries.fold<double>(0, (sum, e) => sum + e.ml);

    return DiarySection(
      title: 'Water',
      summary: '${total.round()} ml',
      addTooltip: 'Add water',
      onAdd: () => showAddWaterSheet(context, ref.read(selectedDayProvider)),
      children: [
        for (final entry in entries)
          DiaryEntryTile(
            entryKey: entry.id,
            title: '${entry.ml.round()} ml',
            onDelete: () =>
                ref.read(diaryRepositoryProvider).deleteWater(entry.id),
          ),
      ],
    );
  }
}

class _ExerciseSection extends ConsumerWidget {
  const _ExerciseSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(dayExercisesProvider).value ?? const [];
    final total = entries.fold<double>(0, (sum, e) => sum + e.kcal);

    return DiarySection(
      title: 'Exercise',
      summary: '${total.round()} kcal',
      addTooltip: 'Add exercise',
      onAdd: () =>
          showAddExerciseDialog(context, ref.read(selectedDayProvider)),
      children: [
        for (final entry in entries)
          DiaryEntryTile(
            entryKey: entry.id,
            title: entry.type.label,
            subtitle: '${formatAmount(entry.minutes)} min',
            trailing: '${entry.kcal.round()} kcal',
            onDelete: () =>
                ref.read(exerciseRepositoryProvider).deleteEntry(entry.id),
          ),
      ],
    );
  }
}

/// How much was logged: the serving as entered, with its weight, or just the
/// weight. For example "2 × 1 tbsp · 42.0 g" or "150 g".
String _amountLabel(DiaryItem item) {
  final grams = '${formatAmount(item.grams)} g';
  final label = item.servingLabel;
  final quantity = item.servingQuantity;
  if (label == null || quantity == null) return grams;
  final count = quantity == quantity.roundToDouble()
      ? quantity.toInt().toString()
      : formatAmount(quantity);
  return quantity == 1 ? '$label · $grams' : '$count × $label · $grams';
}
