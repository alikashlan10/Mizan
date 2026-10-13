import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/domain/meal.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/features/diary/data/diary_repository.dart';
import 'package:mizan/features/foods/data/food_repository.dart';
import 'package:mizan/features/foods/domain/food_serving.dart';
import 'package:mizan/features/foods/domain/food_sources.dart';
import 'package:mizan/features/foods/domain/meal_ingredient.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late FoodRepository foods;
  late Map<String, int> ids;

  setUp(() async {
    db = newTestDatabase();
    foods = FoodRepository(db);
    ids = {for (final n in await foods.allNutrients()) n.code: n.id};
  });
  tearDown(() => db.close());

  Future<int> createFood(String name, Map<String, double> byCode) =>
      foods.createCustomFood(name, {
        for (final e in byCode.entries) ids[e.key]!: e.value,
      });

  Future<Map<String, double>> factsOf(int foodId) async => {
    for (final f in await foods.nutrientsOf(foodId)) f.code: f.amountPer100g,
  };

  Future<List<String>> search(String query) async => [
    for (final f in await foods.watchSearch(query).first) f.name,
  ];

  test('a custom food can be created with servings', () async {
    final bar = await foods.createCustomFood(
      'Protein bar',
      {ids[NutrientCodes.energy]!: 400},
      servings: const [ServingDraft(label: '1 bar', grams: 60)],
    );

    final serving = (await foods.servingsOf(bar)).single;
    expect(serving.label, '1 bar');
    expect(serving.grams, 60);
  });

  test(
    'updating a custom food replaces its name, facts and servings',
    () async {
      final bar = await foods.createCustomFood(
        'Protein bar',
        {ids[NutrientCodes.energy]!: 400, ids[NutrientCodes.fat]!: 10},
        servings: const [ServingDraft(label: '1 bar', grams: 60)],
      );

      await foods.updateCustomFood(
        bar,
        'Oat bar',
        {ids[NutrientCodes.energy]!: 380},
        servings: const [ServingDraft(label: '1 small bar', grams: 40)],
      );

      expect(await search('bar'), ['Oat bar']);
      expect(await factsOf(bar), {NutrientCodes.energy: 380});
      expect((await foods.servingsOf(bar)).single.label, '1 small bar');
    },
  );

  test('a deleted food leaves search but stays in the diary', () async {
    final diary = DiaryRepository(db);
    final day = DateTime(2026, 10, 14);
    final bar = await createFood('Protein bar', {NutrientCodes.energy: 400});
    await diary.addEntry(day: day, meal: Meal.snacks, foodId: bar, grams: 50);

    await foods.deleteFood(bar);

    expect(await search('bar'), isEmpty);
    expect(await foods.watchSources().first, isEmpty);
    final entry = (await diary.watchDayEntries(day).first).single;
    expect(entry.foodName, 'Protein bar');
    expect(entry.kcal, 200);
  });

  test('foods from bundled datasets cannot be deleted', () async {
    await foods.importFoods(FoodSources.usda, const []);
    final id = await db
        .into(db.foods)
        .insert(FoodsCompanion.insert(name: 'Rice', source: FoodSources.usda));

    await foods.deleteFood(id);

    expect(await search('rice'), ['Rice']);
  });

  test('a meal gets facts per 100 g and a whole-meal serving', () async {
    final rice = await createFood('Rice', {
      NutrientCodes.energy: 130,
      NutrientCodes.carbs: 28,
    });
    final chicken = await createFood('Chicken', {
      NutrientCodes.energy: 165,
      NutrientCodes.protein: 31,
    });

    final meal = await foods.saveMeal(
      name: 'Chicken and rice',
      ingredients: [
        MealIngredient(foodId: rice, name: 'Rice', grams: 200),
        MealIngredient(foodId: chicken, name: 'Chicken', grams: 100),
      ],
    );

    // 260 + 165 kcal over 300 g.
    final facts = await factsOf(meal);
    expect(facts[NutrientCodes.energy], closeTo(425 / 3, 1e-9));
    expect(facts[NutrientCodes.carbs], closeTo(56 / 3, 1e-9));
    expect(facts[NutrientCodes.protein], closeTo(31 / 3, 1e-9));

    final serving = (await foods.servingsOf(meal)).single;
    expect(serving.label, '1 meal');
    expect(serving.grams, 300);

    expect(await foods.watchSources().first, [
      FoodSources.custom,
      FoodSources.meal,
    ]);
    final ingredients = await foods.mealIngredients(meal);
    expect(ingredients.map((i) => i.name), ['Rice', 'Chicken']);
    expect(ingredients.first.kcal, 260);
  });

  test('saving a meal again replaces its ingredients', () async {
    final rice = await createFood('Rice', {NutrientCodes.energy: 130});
    final oil = await createFood('Oil', {NutrientCodes.energy: 880});
    final meal = await foods.saveMeal(
      name: 'Rice bowl',
      ingredients: [MealIngredient(foodId: rice, name: 'Rice', grams: 200)],
    );

    await foods.saveMeal(
      id: meal,
      name: 'Fried rice',
      ingredients: [
        MealIngredient(foodId: rice, name: 'Rice', grams: 190),
        MealIngredient(foodId: oil, name: 'Oil', grams: 10),
      ],
    );

    expect(await search('rice'), contains('Fried rice'));
    expect(await search('bowl'), isEmpty);
    expect((await foods.mealIngredients(meal)).map((i) => i.grams), [190, 10]);
    // 247 + 88 kcal over 200 g.
    expect((await factsOf(meal))[NutrientCodes.energy], closeTo(167.5, 1e-9));
    expect((await foods.servingsOf(meal)).single.grams, 200);
  });

  test('a version 5 database gains deletion and meals on upgrade', () async {
    final old = openDatabaseAtVersion(
      5,
      rows: ["INSERT INTO foods (name, source) VALUES ('Old bar', 'custom')"],
    );
    addTearDown(old.close);
    final oldFoods = FoodRepository(old);

    final bar = (await oldFoods.watchSearch('bar').first).single;
    expect(bar.deletedAt, isNull);
    final meal = await oldFoods.saveMeal(
      name: 'Bar plate',
      ingredients: [MealIngredient(foodId: bar.id, name: bar.name, grams: 60)],
    );
    expect(await oldFoods.mealIngredients(meal), hasLength(1));
  });
}
