import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/database/database_provider.dart';
import 'package:mizan/core/database/day_key.dart';
import 'package:mizan/features/statistics/domain/stats_range.dart';

final statisticsRepositoryProvider = Provider<StatisticsRepository>(
  (ref) => StatisticsRepository(ref.watch(appDatabaseProvider)),
);

/// A food's share of one nutrient over a range.
class FoodContribution {
  const FoodContribution({
    required this.foodId,
    required this.name,
    required this.amount,
  });

  final int foodId;
  final String name;

  /// Total of the nutrient this food supplied, in the nutrient's unit.
  final double amount;
}

class StatisticsRepository {
  StatisticsRepository(this._db);

  final AppDatabase _db;

  /// Nutrient totals for each day in [range] with food logged, keyed by day
  /// and then by nutrient code.
  Stream<Map<DateTime, Map<String, double>>> watchDailyIntake(
    StatsRange range,
  ) {
    return _db
        .customSelect(
          'SELECT e.day AS day, n.code AS code, '
          'SUM(fn.amount * e.grams / 100.0) AS total '
          'FROM diary_entries e '
          'JOIN food_nutrients fn ON fn.food_id = e.food_id '
          'JOIN nutrients n ON n.id = fn.nutrient_id '
          'WHERE e.day BETWEEN ? AND ? GROUP BY e.day, n.code',
          variables: [
            Variable.withString(dayKey(range.start)),
            Variable.withString(dayKey(range.end)),
          ],
          readsFrom: {_db.diaryEntries, _db.foodNutrients, _db.nutrients},
        )
        .watch()
        .map((rows) {
          final byDay = <DateTime, Map<String, double>>{};
          for (final r in rows) {
            final day = DateTime.parse(r.read<String>('day'));
            (byDay[day] ??= {})[r.read<String>('code')] = r.read<double>(
              'total',
            );
          }
          return byDay;
        });
  }

  /// Exercise calories for each day in [range] that has any.
  Stream<Map<DateTime, double>> watchDailyExercise(StatsRange range) {
    return _db
        .customSelect(
          'SELECT day, SUM(kcal) AS total FROM exercise_entries '
          'WHERE day BETWEEN ? AND ? GROUP BY day',
          variables: [
            Variable.withString(dayKey(range.start)),
            Variable.withString(dayKey(range.end)),
          ],
          readsFrom: {_db.exerciseEntries},
        )
        .watch()
        .map(
          (rows) => {
            for (final r in rows)
              DateTime.parse(r.read<String>('day')): r.read<double>('total'),
          },
        );
  }

  /// The foods that supplied the most of the nutrient with [code] over
  /// [range], largest first.
  Stream<List<FoodContribution>> watchTopFoods(
    StatsRange range,
    String code, {
    int limit = 5,
  }) {
    return _db
        .customSelect(
          'SELECT f.id AS id, f.name AS name, '
          'SUM(fn.amount * e.grams / 100.0) AS total '
          'FROM diary_entries e '
          'JOIN foods f ON f.id = e.food_id '
          'JOIN food_nutrients fn ON fn.food_id = e.food_id '
          'JOIN nutrients n ON n.id = fn.nutrient_id '
          'WHERE e.day BETWEEN ? AND ? AND n.code = ? '
          'GROUP BY f.id HAVING total > 0 ORDER BY total DESC LIMIT ?',
          variables: [
            Variable.withString(dayKey(range.start)),
            Variable.withString(dayKey(range.end)),
            Variable.withString(code),
            Variable.withInt(limit),
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
              FoodContribution(
                foodId: r.read<int>('id'),
                name: r.read<String>('name'),
                amount: r.read<double>('total'),
              ),
          ],
        );
  }
}
