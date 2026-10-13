import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/database/database_provider.dart';
import 'package:mizan/features/foods/domain/food_nutrient_amount.dart';
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

  /// Foods with a word starting with each word of [query], so "cook" finds
  /// "cooked" but not "uncooked". Shortest names come first, which ranks
  /// plain foods above their many variations. [source] limits the search to
  /// one dataset. Emits again whenever foods change.
  Stream<List<Food>> watchSearch(String query, {String? source}) {
    final q = _db.select(_db.foods)
      ..orderBy([
        (f) => OrderingTerm(expression: f.name.length),
        (f) => OrderingTerm(expression: f.name),
      ])
      ..limit(50);
    if (source != null) q.where((f) => f.source.equals(source));
    for (final word in query.trim().split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      final escaped = word.replaceAllMapped(
        RegExp(r'[\\%_]'),
        (m) => '\\${m[0]}',
      );
      q.where((f) => _wordStarts(f.name).like('% $escaped%', escapeChar: r'\'));
    }
    return q.watch();
  }

  /// [name] with a leading space and its punctuation turned into spaces, so
  /// that every word in it follows a space.
  Expression<String> _wordStarts(Expression<String> name) {
    var spaced = name;
    for (final separator in const [',', '-', '(', '/']) {
      spaced = FunctionCallExpression('replace', [
        spaced,
        Constant(separator),
        const Constant(' '),
      ]);
    }
    return const Constant(' ') + spaced;
  }

  /// The datasets that currently have foods, in display order.
  Stream<List<String>> watchSources() {
    final q = _db.selectOnly(_db.foods, distinct: true)
      ..addColumns([_db.foods.source]);
    return q.watch().map(
      (rows) =>
          [for (final r in rows) r.read(_db.foods.source)!]
            ..sort(FoodSources.compare),
    );
  }

  /// The nutrition facts of a food, in display order.
  Future<List<FoodNutrientAmount>> nutrientsOf(int foodId) async {
    final q =
        _db.select(_db.foodNutrients).join([
            innerJoin(
              _db.nutrients,
              _db.nutrients.id.equalsExp(_db.foodNutrients.nutrientId),
            ),
          ])
          ..where(_db.foodNutrients.foodId.equals(foodId))
          ..orderBy([OrderingTerm(expression: _db.nutrients.sortOrder)]);
    return [
      for (final row in await q.get())
        FoodNutrientAmount(
          code: row.readTable(_db.nutrients).code,
          name: row.readTable(_db.nutrients).name,
          unit: row.readTable(_db.nutrients).unit,
          amountPer100g: row.readTable(_db.foodNutrients).amount,
        ),
    ];
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
