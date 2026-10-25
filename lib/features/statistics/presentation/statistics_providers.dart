import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/features/profile/presentation/profile_providers.dart';
import 'package:mizan/features/statistics/data/statistics_repository.dart';
import 'package:mizan/features/statistics/domain/range_stats.dart';
import 'package:mizan/features/statistics/domain/stats_range.dart';

/// The range every statistics tab shows; today until the user picks another.
class SelectedStatsRange extends Notifier<StatsRange> {
  @override
  StatsRange build() => StatsRange.preset(StatsPreset.today, DateTime.now());

  void selectPreset(StatsPreset preset) =>
      state = StatsRange.preset(preset, DateTime.now());

  void selectCustom(DateTime start, DateTime end) =>
      state = StatsRange(start: start, end: end, preset: StatsPreset.custom);
}

final statsRangeProvider = NotifierProvider<SelectedStatsRange, StatsRange>(
  SelectedStatsRange.new,
);

final _dailyIntakeProvider = StreamProvider<Map<DateTime, Map<String, double>>>(
  (ref) => ref
      .watch(statisticsRepositoryProvider)
      .watchDailyIntake(ref.watch(statsRangeProvider)),
);

final _dailyExerciseProvider = StreamProvider<Map<DateTime, double>>(
  (ref) => ref
      .watch(statisticsRepositoryProvider)
      .watchDailyExercise(ref.watch(statsRangeProvider)),
);

/// Everything eaten and burned over the selected range; null while loading.
final rangeStatsProvider = Provider<RangeStats?>((ref) {
  final intake = ref.watch(_dailyIntakeProvider).value;
  final exercise = ref.watch(_dailyExerciseProvider).value;
  if (intake == null || exercise == null) return null;
  return RangeStats(
    range: ref.watch(statsRangeProvider),
    intakeByDay: intake,
    exerciseByDay: exercise,
    estimate: ref.watch(calorieEstimateProvider),
  );
});

/// The foods that supplied the most of a nutrient over the selected range.
final topFoodsProvider = StreamProvider.autoDispose
    .family<List<FoodContribution>, String>(
      (ref, code) => ref
          .watch(statisticsRepositoryProvider)
          .watchTopFoods(ref.watch(statsRangeProvider), code),
    );
