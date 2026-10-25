import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/database/database_provider.dart';
import 'package:mizan/core/domain/meal.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/core/theme/app_theme.dart';
import 'package:mizan/features/diary/data/diary_repository.dart';
import 'package:mizan/features/exercise/data/exercise_repository.dart';
import 'package:mizan/features/exercise/domain/exercise.dart';
import 'package:mizan/features/foods/data/food_repository.dart';
import 'package:mizan/features/profile/domain/calorie_calculator.dart';
import 'package:mizan/features/statistics/data/statistics_repository.dart';
import 'package:mizan/features/statistics/domain/range_stats.dart';
import 'package:mizan/features/statistics/domain/stats_range.dart';
import 'package:mizan/features/statistics/presentation/statistics_screen.dart';

import '../../support/test_database.dart';

void main() {
  final oct20 = DateTime(2026, 10, 20);
  final oct21 = DateTime(2026, 10, 21);
  final oct22 = DateTime(2026, 10, 22);
  const estimate = CalorieEstimate(
    restingKcal: 1800,
    maintenanceKcal: 2500,
    targetKcal: 2000,
    raisedToMinimum: false,
  );

  group('ranges', () {
    test('presets end today and include it', () {
      final today = DateTime(2026, 10, 25, 18, 30);
      final week = StatsRange.preset(StatsPreset.lastWeek, today);
      expect(week.start, DateTime(2026, 10, 19));
      expect(week.end, DateTime(2026, 10, 25));
      expect(week.days, hasLength(7));
      expect(
        StatsRange.preset(StatsPreset.lastMonth, today).days,
        hasLength(30),
      );
      expect(StatsRange.preset(StatsPreset.today, today).isSingleDay, isTrue);
    });

    test('a range cannot end before it starts', () {
      expect(
        () => StatsRange(start: oct22, end: oct20, preset: StatsPreset.custom),
        throwsArgumentError,
      );
    });
  });

  group('range figures', () {
    final range = StatsRange(
      start: oct20,
      end: oct22,
      preset: StatsPreset.custom,
    );
    RangeStats statsWith(CalorieEstimate? estimate) => RangeStats(
      range: range,
      // Nothing logged on the 21st.
      intakeByDay: {
        oct20: {NutrientCodes.energy: 2000, NutrientCodes.protein: 100},
        oct22: {NutrientCodes.energy: 3000, NutrientCodes.protein: 50},
      },
      exerciseByDay: {oct21: 400, oct22: 300},
      estimate: estimate,
    );

    test('averages count only days with food logged', () {
      final stats = statsWith(estimate);
      expect(stats.loggedDays, [oct20, oct22]);
      expect(stats.averageOf(NutrientCodes.energy), 2500);
      expect(stats.averageOf(NutrientCodes.protein), 75);
      expect(stats.averageExerciseKcal, 150);
    });

    test('balance is eaten minus maintenance and that day\'s exercise', () {
      final days = statsWith(estimate).days;
      expect(days.map((d) => d.balanceKcal), [-500, null, 200]);
      expect(statsWith(estimate).totalBalanceKcal, -300);
      expect(statsWith(estimate).averageBalanceKcal, -150);
    });

    test('without a profile there is intake but no balance', () {
      final stats = statsWith(null);
      expect(stats.days.first.intakeKcal, 2000);
      expect(stats.days.first.expenditureKcal, isNull);
      expect(stats.totalBalanceKcal, isNull);
    });
  });

  group('repository', () {
    late AppDatabase db;
    late StatisticsRepository statistics;
    late int rice;
    late int chicken;

    setUp(() async {
      db = newTestDatabase();
      statistics = StatisticsRepository(db);
      final foods = FoodRepository(db);
      final ids = {for (final n in await foods.allNutrients()) n.code: n.id};
      rice = await foods.createCustomFood('Rice', {
        ids[NutrientCodes.energy]!: 130,
        ids[NutrientCodes.carbs]!: 28,
        ids[NutrientCodes.protein]!: 3,
      });
      chicken = await foods.createCustomFood('Chicken', {
        ids[NutrientCodes.energy]!: 165,
        ids[NutrientCodes.protein]!: 31,
      });
      final diary = DiaryRepository(db);
      await diary.addEntry(
        day: oct20,
        meal: Meal.lunch,
        foodId: rice,
        grams: 200,
      );
      await diary.addEntry(
        day: oct20,
        meal: Meal.dinner,
        foodId: chicken,
        grams: 100,
      );
      await diary.addEntry(
        day: oct22,
        meal: Meal.lunch,
        foodId: rice,
        grams: 100,
      );
      // Outside the range below.
      await diary.addEntry(
        day: DateTime(2026, 10, 25),
        meal: Meal.lunch,
        foodId: chicken,
        grams: 1000,
      );
      await ExerciseRepository(db).addEntry(
        day: oct21,
        type: ExerciseType.running,
        minutes: 30,
        kcal: 350,
      );
    });
    tearDown(() => db.close());

    final range = StatsRange(
      start: oct20,
      end: oct22,
      preset: StatsPreset.custom,
    );

    test('daily intake is summed per day and nutrient', () async {
      final intake = await statistics.watchDailyIntake(range).first;
      expect(intake.keys, unorderedEquals([oct20, oct22]));
      expect(intake[oct20]![NutrientCodes.energy], closeTo(425, 1e-9));
      expect(intake[oct20]![NutrientCodes.protein], closeTo(37, 1e-9));
      expect(intake[oct22]![NutrientCodes.carbs], closeTo(28, 1e-9));
    });

    test('exercise is summed per day', () async {
      expect(await statistics.watchDailyExercise(range).first, {oct21: 350});
    });

    test('top foods are ranked by the nutrient within the range', () async {
      final protein = await statistics
          .watchTopFoods(range, NutrientCodes.protein)
          .first;
      expect(protein.map((f) => f.name), ['Chicken', 'Rice']);
      expect(protein.first.amount, closeTo(31, 1e-9));
      expect(protein.last.amount, closeTo(9, 1e-9));

      final carbs = await statistics
          .watchTopFoods(range, NutrientCodes.carbs)
          .first;
      expect(carbs.map((f) => f.name), ['Rice']);
    });
  });

  testWidgets('opens on today with three tabs', (tester) async {
    final db = newTestDatabase();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const StatisticsScreen(),
        ),
      ),
    );
    // Database work runs on real timers, outside the test's fake clock.
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(Durations.short2));
      await tester.pump();
    }

    for (final tab in ['Overview', 'Macros', 'Nutrients']) {
      expect(find.text(tab), findsOneWidget);
    }
    final today = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Today'),
    );
    expect(today.selected, isTrue);
    expect(find.text('No food logged in this range yet.'), findsOneWidget);
    expect(find.textContaining('0 of 1 day logged'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}
