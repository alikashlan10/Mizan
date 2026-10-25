import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/domain/meal.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/features/diary/data/diary_repository.dart';
import 'package:mizan/features/foods/data/food_repository.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late FoodRepository foods;
  late DiaryRepository diary;
  final today = DateTime(2026, 10, 11);
  final tomorrow = DateTime(2026, 10, 12);

  setUp(() {
    db = newTestDatabase();
    foods = FoodRepository(db);
    diary = DiaryRepository(db);
  });
  tearDown(() => db.close());

  Future<int> createFood(String name, Map<String, double> byCode) async {
    final ids = {for (final n in await foods.allNutrients()) n.code: n.id};
    return foods.createCustomFood(name, {
      for (final e in byCode.entries) ids[e.key]!: e.value,
    });
  }

  test('day totals scale nutrients by grams eaten', () async {
    final oats = await createFood('Rolled oats', {
      NutrientCodes.energy: 380,
      NutrientCodes.protein: 13,
    });
    final oil = await createFood('Olive oil', {NutrientCodes.energy: 880});
    await diary.addEntry(
      day: today,
      meal: Meal.breakfast,
      foodId: oats,
      grams: 50,
    );
    await diary.addEntry(day: today, meal: Meal.lunch, foodId: oil, grams: 10);
    await diary.addEntry(
      day: tomorrow,
      meal: Meal.lunch,
      foodId: oil,
      grams: 100,
    );

    final totals = await diary.watchDayTotals(today).first;
    expect(totals[NutrientCodes.energy], closeTo(278, 1e-9));
    expect(totals[NutrientCodes.protein], closeTo(6.5, 1e-9));
  });

  test('day entries are listed by meal with their calories', () async {
    final oil = await createFood('Olive oil', {NutrientCodes.energy: 880});
    final water = await createFood('Water', {});
    await diary.addEntry(day: today, meal: Meal.lunch, foodId: oil, grams: 10);
    await diary.addEntry(
      day: today,
      meal: Meal.breakfast,
      foodId: water,
      grams: 250,
    );

    final items = await diary.watchDayEntries(today).first;
    expect(items.map((i) => i.foodName), ['Water', 'Olive oil']);
    expect(items.first.kcal, isNull);
    expect(items.last.kcal, closeTo(88, 1e-9));
    expect(items.last.meal, Meal.lunch);
  });

  test('water is listed for its day and can be deleted', () async {
    final glass = await diary.addWater(day: today, ml: 250);
    await diary.addWater(day: today, ml: 500);
    await diary.addWater(day: tomorrow, ml: 330);

    expect((await diary.watchDayWater(today).first).map((w) => w.ml), [
      250,
      500,
    ]);

    await diary.deleteWater(glass);
    expect((await diary.watchDayWater(today).first).single.ml, 500);
  });

  test('an entry remembers the serving it was logged with', () async {
    final honey = await createFood('Honey', {NutrientCodes.energy: 304});
    await diary.addEntry(
      day: today,
      meal: Meal.breakfast,
      foodId: honey,
      grams: 42,
      servingQuantity: 2,
      servingLabel: '1 tbsp',
    );
    await diary.addEntry(
      day: today,
      meal: Meal.lunch,
      foodId: honey,
      grams: 10,
    );

    final items = await diary.watchDayEntries(today).first;
    expect(items.first.servingQuantity, 2);
    expect(items.first.servingLabel, '1 tbsp');
    expect(items.first.grams, 42);
    expect(items.last.servingLabel, isNull);
  });

  test('a version 8 database keeps its entries and gains servings', () async {
    final old = openDatabaseAtVersion(
      8,
      rows: [
        "INSERT INTO foods (id, name, source) VALUES (1, 'Rice', 'custom')",
        'INSERT INTO diary_entries (day, meal, food_id, grams) VALUES '
            "('2026-10-11', 0, 1, 150)",
      ],
    );
    addTearDown(old.close);

    final item = (await DiaryRepository(
      old,
    ).watchDayEntries(today).first).single;
    expect(item.grams, 150);
    expect(item.servingLabel, isNull);
  });

  test('deleting an entry removes it from the day', () async {
    final rice = await createFood('Rice', {NutrientCodes.energy: 130});
    final entry = await diary.addEntry(
      day: today,
      meal: Meal.dinner,
      foodId: rice,
      grams: 200,
    );

    await diary.deleteEntry(entry);

    expect(await diary.watchDayEntries(today).first, isEmpty);
    expect(await diary.watchDayTotals(today).first, isEmpty);
  });
}
