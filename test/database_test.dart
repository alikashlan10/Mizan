import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/data/database.dart';
import 'package:mizan/data/food_seed.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> createFood(String name, Map<String, double> byCode) async {
    final ids = {for (final n in await db.allNutrients()) n.code: n.id};
    return db.createCustomFood(name, {
      for (final e in byCode.entries) ids[e.key]!: e.value,
    });
  }

  test('seeds the core nutrients', () async {
    final nutrients = await db.allNutrients();
    expect(nutrients.first.code, NutrientCodes.energy);
    expect(nutrients, hasLength(8));
  });

  test('search matches every word, shortest names first', () async {
    await createFood('Egg, whole, raw, fresh', {});
    await createFood('Egg, whole, raw', {});
    await createFood('Olive oil', {});
    expect((await db.searchFoods('raw egg')).map((f) => f.name), [
      'Egg, whole, raw',
      'Egg, whole, raw, fresh',
    ]);
    expect(await db.searchFoods(''), hasLength(3));
  });

  test('seeds bundled foods once, skipping blank amounts', () async {
    var loads = 0;
    Future<String> load() async {
      loads++;
      return '1\tOil, olive\t884\t0\t0\t100\t0\t0\t13.8\t2\n'
          '2\tCoating mix\t377\t6.1\t79.8\t3.7\t\t\t\t2182\n';
    }

    await seedFoodsIfNeeded(db, load);
    await seedFoodsIfNeeded(db, load);
    expect(loads, 1);

    final coating = (await db.searchFoods('coating')).single;
    expect(coating.source, usdaSource);
    await db.addEntry(
      day: '2026-10-11',
      meal: Meal.snacks,
      foodId: coating.id,
      grams: 200,
    );
    final totals = await db.watchDayTotals('2026-10-11').first;
    expect(totals[NutrientCodes.sodium], closeTo(4364, 1e-9));
    expect(totals.containsKey(NutrientCodes.fiber), isFalse);
  });

  test('imports the bundled USDA dataset', () async {
    await seedFoodsIfNeeded(db, File(usdaSeedAsset).readAsString);
    final oil = (await db.searchFoods('oil olive salad')).first;
    expect(oil.name, 'Oil, olive, salad or cooking');
    await db.addEntry(
      day: '2026-10-11',
      meal: Meal.lunch,
      foodId: oil.id,
      grams: 10,
    );
    final totals = await db.watchDayTotals('2026-10-11').first;
    expect(totals[NutrientCodes.energy], closeTo(88.4, 1e-9));
    expect(totals[NutrientCodes.fat], closeTo(10, 1e-9));
  });

  test('day totals scale nutrients by grams eaten', () async {
    final oats = await createFood('Rolled oats', {
      NutrientCodes.energy: 380,
      NutrientCodes.protein: 13,
    });
    final oil = await createFood('Olive oil', {NutrientCodes.energy: 880});
    await db.addEntry(
      day: '2026-10-11',
      meal: Meal.breakfast,
      foodId: oats,
      grams: 50,
    );
    await db.addEntry(
      day: '2026-10-11',
      meal: Meal.lunch,
      foodId: oil,
      grams: 10,
    );
    await db.addEntry(
      day: '2026-10-12',
      meal: Meal.lunch,
      foodId: oil,
      grams: 100,
    );

    final totals = await db.watchDayTotals('2026-10-11').first;
    expect(totals[NutrientCodes.energy], closeTo(278, 1e-9));
    expect(totals[NutrientCodes.protein], closeTo(6.5, 1e-9));

    final items = await db.watchDayEntries('2026-10-11').first;
    expect(items.map((i) => i.foodName), ['Rolled oats', 'Olive oil']);
    expect(items.first.kcal, closeTo(190, 1e-9));
    expect(items.last.meal, Meal.lunch);
  });

  test('deleting an entry removes it from the day', () async {
    final food = await createFood('Rice', {NutrientCodes.energy: 130});
    final entry = await db.addEntry(
      day: '2026-10-11',
      meal: Meal.dinner,
      foodId: food,
      grams: 200,
    );
    await db.deleteEntry(entry);
    expect(await db.watchDayEntries('2026-10-11').first, isEmpty);
  });
}
