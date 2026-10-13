import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/features/foods/data/food_repository.dart';
import 'package:mizan/features/foods/data/food_seed.dart';
import 'package:mizan/features/foods/domain/food_serving.dart';
import 'package:mizan/features/foods/domain/food_sources.dart';
import 'package:mizan/features/foods/domain/seed_food.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late FoodRepository foods;

  setUp(() {
    db = newTestDatabase();
    foods = FoodRepository(db);
  });
  tearDown(() => db.close());

  Future<List<String>> search(String query) async => [
    for (final f in await foods.watchSearch(query).first) f.name,
  ];

  test('the core nutrients exist in a new database', () async {
    final nutrients = await foods.allNutrients();
    expect(nutrients.first.code, NutrientCodes.energy);
    expect(nutrients, hasLength(8));
  });

  test('search matches every word, shortest names first', () async {
    await foods.createCustomFood('Egg, whole, raw, fresh', {});
    await foods.createCustomFood('Egg, whole, raw', {});
    await foods.createCustomFood('Olive oil', {});

    expect(await search('raw egg'), [
      'Egg, whole, raw',
      'Egg, whole, raw, fresh',
    ]);
    expect(await search(''), hasLength(3));
  });

  test('search matches the start of words, not their middle', () async {
    await foods.createCustomFood('Rice, white, cooked', {});
    await foods.createCustomFood('Rice, white, uncooked', {});
    await foods.createCustomFood('Rice, short-grain (boiled)', {});

    expect(await search('cooked'), ['Rice, white, cooked']);
    expect(await search('cook'), ['Rice, white, cooked']);
    expect(await search('grain'), ['Rice, short-grain (boiled)']);
    expect(await search('boil'), ['Rice, short-grain (boiled)']);
    expect(await search('RICE'), hasLength(3));
  });

  test('search treats % and _ as ordinary characters', () async {
    await foods.createCustomFood('Milk, 2% fat', {});
    await foods.createCustomFood('Milk, whole', {});

    expect(await search('2%'), ['Milk, 2% fat']);
    expect(await search('%'), isEmpty);
    expect(await search('_'), isEmpty);
  });

  test('search can be limited to one source', () async {
    await foods.importFoods(FoodSources.usda, const [
      SeedFood(sourceId: '1', name: 'Rice, white', amounts: {}),
    ]);
    await foods.createCustomFood('Rice pudding', {});

    final custom = await foods
        .watchSearch('rice', source: FoodSources.custom)
        .first;
    expect(custom.map((f) => f.name), ['Rice pudding']);
    expect(await search('rice'), hasLength(2));
  });

  test('sources are listed only once they have foods, USDA first', () async {
    expect(await foods.watchSources().first, isEmpty);

    await foods.createCustomFood('Rice pudding', {});
    expect(await foods.watchSources().first, [FoodSources.custom]);

    await foods.importFoods(FoodSources.usda, const [
      SeedFood(sourceId: '1', name: 'Rice, white', amounts: {}),
    ]);
    expect(await foods.watchSources().first, [
      FoodSources.usda,
      FoodSources.custom,
    ]);
  });

  test('nutrition facts come back in display order', () async {
    final ids = {for (final n in await foods.allNutrients()) n.code: n.id};
    final rice = await foods.createCustomFood('Rice', {
      ids[NutrientCodes.sodium]!: 5,
      ids[NutrientCodes.energy]!: 130,
    });

    final facts = await foods.nutrientsOf(rice);
    expect(facts.map((f) => f.code), [
      NutrientCodes.energy,
      NutrientCodes.sodium,
    ]);
    expect(facts.first.unit, 'kcal');
    expect(facts.first.amountIn(250), 325);
  });

  test('servings are imported for foods that exist, in order', () async {
    await foods.importFoods(FoodSources.usda, const [
      SeedFood(sourceId: '10', name: 'Egg', amounts: {}),
    ]);
    expect(await foods.hasServingsFrom(FoodSources.usda), isFalse);

    await foods.importServings(FoodSources.usda, const [
      SeedServing(
        foodSourceId: '10',
        sortOrder: 2,
        label: '1 jumbo',
        grams: 63,
      ),
      SeedServing(
        foodSourceId: '10',
        sortOrder: 1,
        label: '1 large',
        grams: 50,
      ),
      SeedServing(foodSourceId: '99', sortOrder: 1, label: '1 cup', grams: 240),
    ]);

    expect(await foods.hasServingsFrom(FoodSources.usda), isTrue);
    final egg = (await foods.watchSearch('egg').first).single;
    final servings = await foods.servingsOf(egg.id);
    expect(servings.map((s) => s.label), ['1 large', '1 jumbo']);
    expect(servings.first.grams, 50);
  });

  test(
    'servings are seeded once, even into an already seeded database',
    () async {
      await foods.importFoods(FoodSources.usda, const [
        SeedFood(sourceId: '10', name: 'Egg', amounts: {}),
      ]);
      var loads = 0;
      Future<String> load() async {
        loads++;
        return '10\t1\t1 large\t50\n10\t2\t1 cup (4.86 large eggs)\t243\n';
      }

      await seedServingsIfNeeded(foods, load);
      await seedServingsIfNeeded(foods, load);

      expect(loads, 1);
      final egg = (await foods.watchSearch('egg').first).single;
      expect(await foods.servingsOf(egg.id), hasLength(2));
    },
  );

  test('an amount in servings converts to grams', () {
    const large = FoodServing(id: 1, label: '1 large', grams: 50);
    expect(const FoodAmount(quantity: 2, serving: large).grams, 100);
    expect(const FoodAmount.grams(150).grams, 150);
  });

  test('search results update when a food is created', () async {
    final results = foods.watchSearch('rice').map((list) => list.length);
    final expectation = expectLater(results, emitsInOrder([0, 1]));
    await pumpEventQueue();
    await foods.createCustomFood('Rice', {});
    await expectation;
  });

  test('bundled foods are seeded once', () async {
    var loads = 0;
    Future<String> load() async {
      loads++;
      return '1\tOil, olive\t884\t0\t0\t100\t0\t0\t13.8\t2\n';
    }

    await seedFoodsIfNeeded(foods, load);
    await seedFoodsIfNeeded(foods, load);

    expect(loads, 1);
    final oil = (await foods.watchSearch('olive').first).single;
    expect(oil.source, FoodSources.usda);
  });

  test('the bundled USDA dataset imports', () async {
    await seedFoodsIfNeeded(foods, File(usdaSeedAsset).readAsString);
    expect(
      (await search('oil olive salad')).first,
      'Oil, olive, salad or cooking',
    );
  });
}
