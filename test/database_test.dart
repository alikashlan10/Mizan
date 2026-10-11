import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/data/database.dart';

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

  test('search matches part of the name', () async {
    await createFood('Rolled oats', {});
    await createFood('Olive oil', {});
    expect((await db.searchFoods('oat')).map((f) => f.name), ['Rolled oats']);
    expect(await db.searchFoods(''), hasLength(2));
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
