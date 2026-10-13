import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/database/database_provider.dart';
import 'package:mizan/features/foods/domain/food_sources.dart';
import 'package:mizan/features/foods/domain/seed_food.dart';

final foodRepositoryProvider = Provider<FoodRepository>(
  (ref) => FoodRepository(ref.watch(appDatabaseProvider)),
);

class FoodRepository {
  FoodRepository(this._db);

  final AppDatabase _db;

  Future<List<Nutrient>> allNutrients() => (_db.select(
    _db.nutrients,
  )..orderBy([(n) => OrderingTerm(expression: n.sortOrder)])).get();

  /// Foods whose name contains every word of [query], shortest names first so
  /// that plain foods rank above their many variations. Emits again whenever
  /// foods change.
  Stream<List<Food>> watchSearch(String query) {
    final q = _db.select(_db.foods)
      ..orderBy([
        (f) => OrderingTerm(expression: f.name.length),
        (f) => OrderingTerm(expression: f.name),
      ])
      ..limit(50);
    for (final word in query.trim().split(RegExp(r'\s+'))) {
      if (word.isNotEmpty) q.where((f) => f.name.like('%$word%'));
    }
    return q.watch();
  }

  Future<bool> hasFoodsFrom(String source) async {
    final q = _db.select(_db.foods)
      ..where((f) => f.source.equals(source))
      ..limit(1);
    return (await q.get()).isNotEmpty;
  }

  Future<void> importFoods(String source, List<SeedFood> seed) {
    return _db.transaction(() async {
      await _db.batch((b) {
        b.insertAll(_db.foods, [
          for (final food in seed)
            FoodsCompanion.insert(
              name: food.name,
              source: source,
              sourceId: Value(food.sourceId),
            ),
        ]);
      });
      final nutrientIds = {for (final n in await allNutrients()) n.code: n.id};
      final imported = await (_db.select(
        _db.foods,
      )..where((f) => f.source.equals(source))).get();
      final foodIds = {for (final f in imported) f.sourceId: f.id};
      await _db.batch((b) {
        b.insertAll(_db.foodNutrients, [
          for (final food in seed)
            for (final e in food.amounts.entries)
              FoodNutrientsCompanion.insert(
                foodId: foodIds[food.sourceId]!,
                nutrientId: nutrientIds[e.key]!,
                amount: e.value,
              ),
        ]);
      });
    });
  }

  /// [amountsPer100g] is keyed by nutrient id.
  Future<int> createCustomFood(String name, Map<int, double> amountsPer100g) {
    return _db.transaction(() async {
      final foodId = await _db
          .into(_db.foods)
          .insert(
            FoodsCompanion.insert(name: name, source: FoodSources.custom),
          );
      await _db.batch((b) {
        b.insertAll(_db.foodNutrients, [
          for (final e in amountsPer100g.entries)
            FoodNutrientsCompanion.insert(
              foodId: foodId,
              nutrientId: e.key,
              amount: e.value,
            ),
        ]);
      });
      return foodId;
    });
  }
}
