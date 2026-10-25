import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/domain/display_units.dart';
import 'package:mizan/core/domain/meal.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/features/backup/data/backup_repository.dart';
import 'package:mizan/features/diary/data/diary_repository.dart';
import 'package:mizan/features/exercise/data/exercise_repository.dart';
import 'package:mizan/features/exercise/domain/exercise.dart';
import 'package:mizan/features/foods/data/food_repository.dart';
import 'package:mizan/features/foods/domain/food_serving.dart';
import 'package:mizan/features/foods/domain/food_sources.dart';
import 'package:mizan/features/foods/domain/meal_ingredient.dart';
import 'package:mizan/features/foods/domain/seed_food.dart';
import 'package:mizan/features/settings/data/settings_repository.dart';

import '../../support/test_database.dart';

void main() {
  final day = DateTime(2026, 10, 25);
  const egg = SeedFood(
    sourceId: '1123',
    name: 'Egg, whole, raw',
    amounts: {NutrientCodes.energy: 143},
  );

  late AppDatabase source;
  late AppDatabase target;
  setUp(() {
    source = newTestDatabase();
    target = newTestDatabase();
  });
  tearDown(() async {
    await source.close();
    await target.close();
  });

  /// A diary with a bundled food, a custom food logged as a serving, a meal
  /// of both, water, exercise and a setting.
  Future<void> fillSource() async {
    final foods = FoodRepository(source);
    final diary = DiaryRepository(source);
    await foods.importFoods(FoodSources.usda, const [egg]);
    final eggId = (await source.select(source.foods).getSingle()).id;
    final energy = (await foods.allNutrients())
        .firstWhere((n) => n.code == NutrientCodes.energy)
        .id;
    final honey = await foods.createCustomFood(
      'Honey',
      {energy: 304},
      servings: const [ServingDraft(label: '1 tbsp', grams: 21)],
    );
    final breakfast = await foods.saveMeal(
      name: 'Egg and honey',
      ingredients: [
        MealIngredient(foodId: eggId, name: egg.name, grams: 50),
        MealIngredient(foodId: honey, name: 'Honey', grams: 21),
      ],
    );
    await diary.addEntry(
      day: day,
      meal: Meal.breakfast,
      foodId: eggId,
      grams: 100,
    );
    await diary.addEntry(
      day: day,
      meal: Meal.snacks,
      foodId: honey,
      grams: 42,
      servingQuantity: 2,
      servingLabel: '1 tbsp',
    );
    await diary.addEntry(
      day: day,
      meal: Meal.lunch,
      foodId: breakfast,
      grams: 71,
    );
    await diary.addWater(day: day, ml: 500);
    await ExerciseRepository(source)
        .addEntry(day: day, type: ExerciseType.walking, minutes: 30, kcal: 120);
    await SettingsRepository(source)
        .saveDisplayUnits(const DisplayUnits(energyUnit: EnergyUnit.kj));
  }

  /// The export without file-local ids, which differ between installs.
  Object? withoutIds(Object? json) => switch (json) {
    final Map<String, Object?> map => {
      for (final MapEntry(:key, :value) in map.entries)
        if (key != 'id') key: withoutIds(value),
    },
    final List<Object?> list => list.map(withoutIds).toList(),
    _ => json,
  };

  test('restores a backup on another install', () async {
    await fillSource();
    final json = await BackupRepository(source).exportJson();

    // The target has the same bundled food under a different id, and a
    // diary entry of its own that the restore replaces.
    final targetFoods = FoodRepository(target);
    await targetFoods.importFoods(FoodSources.usda, const [
      SeedFood(sourceId: '1', name: 'Apple', amounts: {}),
      egg,
    ]);
    final apple = (await target.select(target.foods).get()).first.id;
    await DiaryRepository(target)
        .addEntry(day: day, meal: Meal.dinner, foodId: apple, grams: 150);

    final summary = await BackupRepository(target).importJson(json);
    expect(summary.foods, 2);
    expect(summary.diaryEntries, 3);
    expect(summary.waterEntries, 1);
    expect(summary.exerciseEntries, 1);
    expect(summary.skipped, 0);

    final restored = await BackupRepository(target).exportJson();
    final a = withoutIds(jsonDecode(json)) as Map<String, Object?>;
    final b = withoutIds(jsonDecode(restored)) as Map<String, Object?>;
    a.remove('exportedAt');
    b.remove('exportedAt');
    expect(b, a);

    final units = await SettingsRepository(target).watchDisplayUnits().first;
    expect(units.energyUnit, EnergyUnit.kj);
  });

  test('leaves out entries for bundled foods this install lacks', () async {
    await fillSource();
    final json = await BackupRepository(source).exportJson();

    final summary = await BackupRepository(target).importJson(json);
    // The egg diary entry and the egg in the meal.
    expect(summary.skipped, 2);
    expect(summary.diaryEntries, 2);
  });

  test('rejects files that are not backups, and keeps the data', () async {
    await fillSource();
    final backup = BackupRepository(source);

    for (final bad in [
      'not json',
      '[]',
      '{"app": "other"}',
      '{"app": "mizan", "format": 99}',
      '{"app": "mizan", "format": 1, "diary": [{"day": 3}]}',
    ]) {
      await expectLater(
        backup.importJson(bad),
        throwsA(isA<BackupFormatException>()),
        reason: bad,
      );
    }
    expect(await source.select(source.diaryEntries).get(), hasLength(3));
  });
}
