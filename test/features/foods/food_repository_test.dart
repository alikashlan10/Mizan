import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/features/foods/data/food_repository.dart';
import 'package:mizan/features/foods/data/food_seed.dart';
import 'package:mizan/features/foods/domain/food_sources.dart';

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
