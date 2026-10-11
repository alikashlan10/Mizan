import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

enum Meal { breakfast, lunch, dinner, snacks }

class Nutrients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  TextColumn get unit => text()();

  /// USDA FoodData Central nutrient id, used to map imported datasets.
  IntColumn get fdcId => integer().nullable()();
  IntColumn get sortOrder => integer()();
}

class Foods extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  /// Dataset the food came from, e.g. `usda_sr` or `custom`.
  TextColumn get source => text()();
  TextColumn get sourceId => text().nullable()();
}

/// Nutrient amounts are stored per 100 g of food, in the nutrient's unit.
class FoodNutrients extends Table {
  IntColumn get foodId =>
      integer().references(Foods, #id, onDelete: KeyAction.cascade)();
  IntColumn get nutrientId => integer().references(Nutrients, #id)();
  RealColumn get amount => real()();

  @override
  Set<Column> get primaryKey => {foodId, nutrientId};
}

@TableIndex(name: 'diary_entries_day', columns: {#day})
class DiaryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Local calendar day as `yyyy-MM-dd`.
  TextColumn get day => text()();
  IntColumn get meal => intEnum<Meal>()();
  IntColumn get foodId => integer().references(Foods, #id)();
  RealColumn get grams => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class NutrientCodes {
  static const energy = 'energy';
  static const protein = 'protein';
  static const carbs = 'carbs';
  static const fat = 'fat';
  static const fiber = 'fiber';
  static const sugars = 'sugars';
  static const saturatedFat = 'saturated_fat';
  static const sodium = 'sodium';
}

const _coreNutrients = [
  (NutrientCodes.energy, 'Energy', 'kcal', 1008),
  (NutrientCodes.protein, 'Protein', 'g', 1003),
  (NutrientCodes.carbs, 'Carbohydrates', 'g', 1005),
  (NutrientCodes.fat, 'Fat', 'g', 1004),
  (NutrientCodes.fiber, 'Fiber', 'g', 1079),
  (NutrientCodes.sugars, 'Sugars', 'g', 2000),
  (NutrientCodes.saturatedFat, 'Saturated fat', 'g', 1258),
  (NutrientCodes.sodium, 'Sodium', 'mg', 1093),
];

/// A food from a bundled dataset, with amounts per 100 g keyed by nutrient code.
class SeedFood {
  const SeedFood({
    required this.sourceId,
    required this.name,
    required this.amounts,
  });

  final String sourceId;
  final String name;
  final Map<String, double> amounts;
}

class DiaryItem {
  const DiaryItem({
    required this.entryId,
    required this.meal,
    required this.foodName,
    required this.grams,
    required this.kcal,
  });

  final int entryId;
  final Meal meal;
  final String foodName;
  final double grams;
  final double? kcal;
}

@DriftDatabase(tables: [Nutrients, Foods, FoodNutrients, DiaryEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'mizan'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await batch((b) {
        b.insertAll(nutrients, [
          for (final (i, n) in _coreNutrients.indexed)
            NutrientsCompanion.insert(
              code: n.$1,
              name: n.$2,
              unit: n.$3,
              fdcId: Value(n.$4),
              sortOrder: i,
            ),
        ]);
      });
    },
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );

  Future<List<Nutrient>> allNutrients() =>
      (select(nutrients)..orderBy([(n) => OrderingTerm(expression: n.sortOrder)]))
          .get();

  /// Matches foods whose name contains every word of [query], shortest names
  /// first so that plain foods rank above their many variations.
  Future<List<Food>> searchFoods(String query) {
    final q = select(foods)
      ..orderBy([
        (f) => OrderingTerm(expression: f.name.length),
        (f) => OrderingTerm(expression: f.name),
      ])
      ..limit(50);
    for (final word in query.trim().split(RegExp(r'\s+'))) {
      if (word.isNotEmpty) q.where((f) => f.name.like('%$word%'));
    }
    return q.get();
  }

  Future<bool> hasFoodsFrom(String source) async {
    final q = select(foods)
      ..where((f) => f.source.equals(source))
      ..limit(1);
    return (await q.get()).isNotEmpty;
  }

  Future<void> importFoods(String source, List<SeedFood> seed) {
    return transaction(() async {
      await batch((b) {
        b.insertAll(foods, [
          for (final food in seed)
            FoodsCompanion.insert(
              name: food.name,
              source: source,
              sourceId: Value(food.sourceId),
            ),
        ]);
      });
      final nutrientIds = {for (final n in await allNutrients()) n.code: n.id};
      final imported = await (select(
        foods,
      )..where((f) => f.source.equals(source))).get();
      final foodIds = {for (final f in imported) f.sourceId: f.id};
      await batch((b) {
        b.insertAll(foodNutrients, [
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
    return transaction(() async {
      final foodId = await into(
        foods,
      ).insert(FoodsCompanion.insert(name: name, source: 'custom'));
      await batch((b) {
        b.insertAll(foodNutrients, [
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

  Future<int> addEntry({
    required String day,
    required Meal meal,
    required int foodId,
    required double grams,
  }) => into(diaryEntries).insert(
    DiaryEntriesCompanion.insert(
      day: day,
      meal: meal,
      foodId: foodId,
      grams: grams,
    ),
  );

  Future<void> deleteEntry(int id) =>
      (delete(diaryEntries)..where((e) => e.id.equals(id))).go();

  Stream<List<DiaryItem>> watchDayEntries(String day) {
    return customSelect(
      'SELECT e.id, e.meal, e.grams, f.name, '
      '(SELECT fn.amount * e.grams / 100.0 FROM food_nutrients fn '
      'JOIN nutrients n ON n.id = fn.nutrient_id '
      'WHERE fn.food_id = e.food_id AND n.code = ?) AS kcal '
      'FROM diary_entries e JOIN foods f ON f.id = e.food_id '
      'WHERE e.day = ? ORDER BY e.meal, e.created_at, e.id',
      variables: [
        Variable.withString(NutrientCodes.energy),
        Variable.withString(day),
      ],
      readsFrom: {diaryEntries, foods, foodNutrients, nutrients},
    ).watch().map(
      (rows) => [
        for (final r in rows)
          DiaryItem(
            entryId: r.read<int>('id'),
            meal: Meal.values[r.read<int>('meal')],
            foodName: r.read<String>('name'),
            grams: r.read<double>('grams'),
            kcal: r.readNullable<double>('kcal'),
          ),
      ],
    );
  }

  /// Total intake for [day], keyed by nutrient code.
  Stream<Map<String, double>> watchDayTotals(String day) {
    return customSelect(
      'SELECT n.code AS code, SUM(fn.amount * e.grams / 100.0) AS total '
      'FROM diary_entries e '
      'JOIN food_nutrients fn ON fn.food_id = e.food_id '
      'JOIN nutrients n ON n.id = fn.nutrient_id '
      'WHERE e.day = ? GROUP BY n.code',
      variables: [Variable.withString(day)],
      readsFrom: {diaryEntries, foodNutrients, nutrients},
    ).watch().map(
      (rows) => {
        for (final r in rows) r.read<String>('code'): r.read<double>('total'),
      },
    );
  }
}
