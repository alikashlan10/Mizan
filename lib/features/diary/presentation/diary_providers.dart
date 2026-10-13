import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/features/diary/data/diary_repository.dart';
import 'package:mizan/features/diary/domain/diary_item.dart';
import 'package:mizan/features/diary/domain/energy_balance.dart';
import 'package:mizan/features/diary/domain/water_entry.dart';
import 'package:mizan/features/exercise/data/exercise_repository.dart';
import 'package:mizan/features/exercise/domain/exercise.dart';
import 'package:mizan/features/profile/presentation/profile_providers.dart';

/// The day the diary is showing.
class SelectedDay extends Notifier<DateTime> {
  @override
  DateTime build() => DateUtils.dateOnly(DateTime.now());

  void select(DateTime day) => state = DateUtils.dateOnly(day);

  void shift(int days) => state = DateUtils.addDaysToDate(state, days);
}

final selectedDayProvider = NotifierProvider<SelectedDay, DateTime>(
  SelectedDay.new,
);

final dayEntriesProvider = StreamProvider<List<DiaryItem>>((ref) {
  return ref
      .watch(diaryRepositoryProvider)
      .watchDayEntries(ref.watch(selectedDayProvider));
});

/// Intake for the selected day, keyed by nutrient code.
final dayTotalsProvider = StreamProvider<Map<String, double>>((ref) {
  return ref
      .watch(diaryRepositoryProvider)
      .watchDayTotals(ref.watch(selectedDayProvider));
});

final dayWaterProvider = StreamProvider<List<WaterEntry>>((ref) {
  return ref
      .watch(diaryRepositoryProvider)
      .watchDayWater(ref.watch(selectedDayProvider));
});

final dayExercisesProvider = StreamProvider<List<ExerciseEntry>>((ref) {
  return ref
      .watch(exerciseRepositoryProvider)
      .watchDay(ref.watch(selectedDayProvider));
});

/// Calories in and out for the selected day.
final energyBalanceProvider = Provider<EnergyBalance>((ref) {
  final totals = ref.watch(dayTotalsProvider).value ?? const {};
  final exercises = ref.watch(dayExercisesProvider).value ?? const [];
  return EnergyBalance(
    intakeKcal: totals[NutrientCodes.energy] ?? 0,
    exerciseKcal: exercises.fold(0, (sum, e) => sum + e.kcal),
    estimate: ref.watch(calorieEstimateProvider),
  );
});
