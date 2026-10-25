import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/database/database_provider.dart';
import 'package:mizan/core/database/day_key.dart';
import 'package:mizan/core/domain/meal.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/features/diary/domain/diary_item.dart';
import 'package:mizan/features/diary/domain/water_entry.dart';

final diaryRepositoryProvider = Provider<DiaryRepository>(
  (ref) => DiaryRepository(ref.watch(appDatabaseProvider)),
);

class DiaryRepository {
  DiaryRepository(this._db);

  final AppDatabase _db;

  /// Logs [grams] of a food. When the amount was entered as servings, pass
  /// [servingQuantity] and [servingLabel] too so the diary can show it that
  /// way, such as "2 × 1 tbsp".
  Future<int> addEntry({
    required DateTime day,
    required Meal meal,
    required int foodId,
    required double grams,
    double? servingQuantity,
    String? servingLabel,
  }) => _db
      .into(_db.diaryEntries)
      .insert(
        DiaryEntriesCompanion.insert(
          day: dayKey(day),
          meal: meal,
          foodId: foodId,
          grams: grams,
          servingQuantity: Value(servingQuantity),
          servingLabel: Value(servingLabel),
        ),
      );

  Future<void> deleteEntry(int id) =>
      (_db.delete(_db.diaryEntries)..where((e) => e.id.equals(id))).go();

  Stream<List<DiaryItem>> watchDayEntries(DateTime day) {
    return _db
        .customSelect(
          'SELECT e.id, e.meal, e.grams, e.serving_quantity, e.serving_label, '
          'f.name, '
          '(SELECT fn.amount * e.grams / 100.0 FROM food_nutrients fn '
          'JOIN nutrients n ON n.id = fn.nutrient_id '
          'WHERE fn.food_id = e.food_id AND n.code = ?) AS kcal '
          'FROM diary_entries e JOIN foods f ON f.id = e.food_id '
          'WHERE e.day = ? ORDER BY e.meal, e.created_at, e.id',
          variables: [
            Variable.withString(NutrientCodes.energy),
            Variable.withString(dayKey(day)),
          ],
          readsFrom: {
            _db.diaryEntries,
            _db.foods,
            _db.foodNutrients,
            _db.nutrients,
          },
        )
        .watch()
        .map(
          (rows) => [
            for (final r in rows)
              DiaryItem(
                entryId: r.read<int>('id'),
                meal: Meal.values[r.read<int>('meal')],
                foodName: r.read<String>('name'),
                grams: r.read<double>('grams'),
                kcal: r.readNullable<double>('kcal'),
                servingQuantity: r.readNullable<double>('serving_quantity'),
                servingLabel: r.readNullable<String>('serving_label'),
              ),
          ],
        );
  }

  Future<int> addWater({required DateTime day, required double ml}) => _db
      .into(_db.waterEntries)
      .insert(WaterEntriesCompanion.insert(day: dayKey(day), ml: ml));

  Future<void> deleteWater(int id) =>
      (_db.delete(_db.waterEntries)..where((w) => w.id.equals(id))).go();

  Stream<List<WaterEntry>> watchDayWater(DateTime day) {
    final query = _db.select(_db.waterEntries)
      ..where((w) => w.day.equals(dayKey(day)))
      ..orderBy([
        (w) => OrderingTerm(expression: w.createdAt),
        (w) => OrderingTerm(expression: w.id),
      ]);
    return query.watch().map(
      (rows) => [for (final r in rows) WaterEntry(id: r.id, ml: r.ml)],
    );
  }

  /// Total intake for [day], keyed by nutrient code.
  Stream<Map<String, double>> watchDayTotals(DateTime day) {
    return _db
        .customSelect(
          'SELECT n.code AS code, SUM(fn.amount * e.grams / 100.0) AS total '
          'FROM diary_entries e '
          'JOIN food_nutrients fn ON fn.food_id = e.food_id '
          'JOIN nutrients n ON n.id = fn.nutrient_id '
          'WHERE e.day = ? GROUP BY n.code',
          variables: [Variable.withString(dayKey(day))],
          readsFrom: {_db.diaryEntries, _db.foodNutrients, _db.nutrients},
        )
        .watch()
        .map(
          (rows) => {
            for (final r in rows)
              r.read<String>('code'): r.read<double>('total'),
          },
        );
  }
}
