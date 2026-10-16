import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/database/database_provider.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/features/foods/domain/food_categories.dart';
import 'package:mizan/features/foods/domain/food_nutrient_amount.dart';
import 'package:mizan/features/foods/domain/food_serving.dart';
import 'package:mizan/features/foods/domain/food_sources.dart';
import 'package:mizan/features/foods/domain/meal_ingredient.dart';
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
  /// "cooked" but not "uncooked". Processed and prepared foods come after
  /// everything else, then shorter names first, which ranks plain foods above
  /// their many variations. [source] limits the search to one dataset. Emits
  /// again whenever foods change.
  Stream<List<Food>> watchSearch(String query, {String? source}) {
    final q = _db.select(_db.foods)
      ..orderBy([
        (f) => OrderingTerm(
          expression: f.category.isIn(FoodCategories.rankedLast),
        ),
        (f) => OrderingTerm(expression: f.name.length),
        (f) => OrderingTerm(expression: f.name),
      ])
      ..limit(50);
    q.where((f) => f.deletedAt.isNull());
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
      ..addColumns([_db.foods.source])
      ..where(_db.foods.deletedAt.isNull());
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

  /// Whether any food from [source] still lacks a category.
  Future<bool> hasUncategorisedFrom(String source) async {
    final q = _db.select(_db.foods)
      ..where((f) => f.source.equals(source) & f.category.isNull())
      ..limit(1);
    return (await q.get()).isNotEmpty;
  }

  /// Sets the category of foods from [source], keyed by their source id.
  Future<void> setCategories(String source, Map<String, String> bySourceId) {
    return _db.batch((b) {
      for (final e in bySourceId.entries) {
        b.update(
          _db.foods,
          FoodsCompanion(category: Value(e.value)),
          where: (f) => f.source.equals(source) & f.sourceId.equals(e.key),
        );
      }
    });
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
              category: Value(food.category),
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

  /// The serving sizes known for a food, in display order.
  Future<List<FoodServing>> servingsOf(int foodId) async {
    final q = _db.select(_db.foodServings)
      ..where((s) => s.foodId.equals(foodId))
      ..orderBy([
        (s) => OrderingTerm(expression: s.sortOrder),
        (s) => OrderingTerm(expression: s.id),
      ]);
    return [
      for (final row in await q.get())
        FoodServing(id: row.id, label: row.label, grams: row.grams),
    ];
  }

  Future<bool> hasServingsFrom(String source) async {
    final q =
        _db.selectOnly(_db.foodServings).join([
            innerJoin(
              _db.foods,
              _db.foods.id.equalsExp(_db.foodServings.foodId),
            ),
          ])
          ..addColumns([_db.foodServings.id])
          ..where(_db.foods.source.equals(source))
          ..limit(1);
    return (await q.get()).isNotEmpty;
  }

  /// Adds serving sizes to foods already imported from [source]. Servings of
  /// foods that are not present are skipped.
  Future<void> importServings(String source, List<SeedServing> seed) async {
    final imported = await (_db.select(
      _db.foods,
    )..where((f) => f.source.equals(source))).get();
    final foodIds = {for (final f in imported) f.sourceId: f.id};
    await _db.batch((b) {
      b.insertAll(_db.foodServings, [
        for (final serving in seed)
          if (foodIds[serving.foodSourceId] case final foodId?)
            FoodServingsCompanion.insert(
              foodId: foodId,
              label: serving.label,
              grams: serving.grams,
              sortOrder: serving.sortOrder,
            ),
      ]);
    });
  }

  /// [amountsPer100g] is keyed by nutrient id.
  Future<int> createCustomFood(
    String name,
    Map<int, double> amountsPer100g, {
    List<ServingDraft> servings = const [],
  }) {
    return _db.transaction(() async {
      final foodId = await _db
          .into(_db.foods)
          .insert(
            FoodsCompanion.insert(name: name, source: FoodSources.custom),
          );
      await _replaceNutrients(foodId, amountsPer100g);
      await _replaceServings(foodId, servings);
      return foodId;
    });
  }

  /// Replaces the name, nutrition facts and servings of a custom food.
  /// [amountsPer100g] is keyed by nutrient id.
  Future<void> updateCustomFood(
    int foodId,
    String name,
    Map<int, double> amountsPer100g, {
    List<ServingDraft> servings = const [],
  }) {
    return _db.transaction(() async {
      await _rename(foodId, name);
      await _replaceNutrients(foodId, amountsPer100g);
      await _replaceServings(foodId, servings);
    });
  }

  /// Creates a meal from [ingredients], or replaces the one with [id]. The
  /// meal is itself a food: its nutrition facts per 100 g are worked out from
  /// the ingredients at this moment, and it gets a "1 meal" serving weighing
  /// the whole recipe. Later changes to an ingredient do not flow through
  /// until the meal is saved again.
  Future<int> saveMeal({
    required String name,
    required List<MealIngredient> ingredients,
    int? id,
  }) {
    return _db.transaction(() async {
      final mealId =
          id ??
          await _db
              .into(_db.foods)
              .insert(
                FoodsCompanion.insert(name: name, source: FoodSources.meal),
              );
      if (id != null) await _rename(id, name);

      await (_db.delete(
        _db.recipeIngredients,
      )..where((r) => r.recipeId.equals(mealId))).go();
      await _db.batch((b) {
        b.insertAll(_db.recipeIngredients, [
          for (final (i, ingredient) in ingredients.indexed)
            RecipeIngredientsCompanion.insert(
              recipeId: mealId,
              ingredientId: ingredient.foodId,
              grams: ingredient.grams,
              sortOrder: i,
            ),
        ]);
      });

      final facts =
          await (_db.select(_db.foodNutrients)..where(
                (n) => n.foodId.isIn({for (final i in ingredients) i.foodId}),
              ))
              .get();
      final totalGrams = ingredients.fold<double>(0, (sum, i) => sum + i.grams);
      final totals = <int, double>{};
      for (final ingredient in ingredients) {
        for (final fact in facts) {
          if (fact.foodId != ingredient.foodId) continue;
          totals[fact.nutrientId] =
              (totals[fact.nutrientId] ?? 0) +
              fact.amount * ingredient.grams / 100;
        }
      }
      await _replaceNutrients(mealId, {
        if (totalGrams > 0)
          for (final e in totals.entries) e.key: e.value / totalGrams * 100,
      });
      await _replaceServings(mealId, [
        if (totalGrams > 0) ServingDraft(label: '1 meal', grams: totalGrams),
      ]);
      return mealId;
    });
  }

  /// The ingredients of a meal, in the order they were added.
  Future<List<MealIngredient>> mealIngredients(int mealId) async {
    final rows = await _db
        .customSelect(
          'SELECT r.ingredient_id, r.grams, f.name, '
          '(SELECT fn.amount FROM food_nutrients fn '
          'JOIN nutrients n ON n.id = fn.nutrient_id '
          'WHERE fn.food_id = r.ingredient_id AND n.code = ?) AS kcal '
          'FROM recipe_ingredients r JOIN foods f ON f.id = r.ingredient_id '
          'WHERE r.recipe_id = ? ORDER BY r.sort_order, r.id',
          variables: [
            Variable.withString(NutrientCodes.energy),
            Variable.withInt(mealId),
          ],
        )
        .get();
    return [
      for (final r in rows)
        MealIngredient(
          foodId: r.read<int>('ingredient_id'),
          name: r.read<String>('name'),
          grams: r.read<double>('grams'),
          kcalPer100g: r.readNullable<double>('kcal'),
        ),
    ];
  }

  /// Energy per 100 g of a food, or null when none is recorded.
  Future<double?> energyPer100g(int foodId) async {
    for (final fact in await nutrientsOf(foodId)) {
      if (fact.code == NutrientCodes.energy) return fact.amountPer100g;
    }
    return null;
  }

  /// Hides a custom food or meal from search. The row is kept, so diary
  /// entries and meals that already use it stay intact.
  Future<void> deleteFood(int foodId) =>
      (_db.update(_db.foods)..where(
            (f) => f.id.equals(foodId) & f.source.isIn(FoodSources.userCreated),
          ))
          .write(FoodsCompanion(deletedAt: Value(DateTime.now())));

  Future<void> _rename(int foodId, String name) =>
      (_db.update(_db.foods)..where((f) => f.id.equals(foodId))).write(
        FoodsCompanion(name: Value(name)),
      );

  Future<void> _replaceNutrients(
    int foodId,
    Map<int, double> amountsPer100g,
  ) async {
    await (_db.delete(
      _db.foodNutrients,
    )..where((n) => n.foodId.equals(foodId))).go();
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
  }

  Future<void> _replaceServings(int foodId, List<ServingDraft> servings) async {
    await (_db.delete(
      _db.foodServings,
    )..where((s) => s.foodId.equals(foodId))).go();
    await _db.batch((b) {
      b.insertAll(_db.foodServings, [
        for (final (i, serving) in servings.indexed)
          FoodServingsCompanion.insert(
            foodId: foodId,
            label: serving.label,
            grams: serving.grams,
            sortOrder: i,
          ),
      ]);
    });
  }
}
