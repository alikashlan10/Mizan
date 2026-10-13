import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/database/database_provider.dart';
import 'package:mizan/core/database/day_key.dart';
import 'package:mizan/features/exercise/domain/exercise.dart';

final exerciseRepositoryProvider = Provider<ExerciseRepository>(
  (ref) => ExerciseRepository(ref.watch(appDatabaseProvider)),
);

class ExerciseRepository {
  ExerciseRepository(this._db);

  final AppDatabase _db;

  Future<int> addEntry({
    required DateTime day,
    required ExerciseType type,
    required double minutes,
    required double kcal,
  }) => _db
      .into(_db.exerciseEntries)
      .insert(
        ExerciseEntriesCompanion.insert(
          day: dayKey(day),
          type: type.name,
          minutes: minutes,
          kcal: kcal,
        ),
      );

  Future<void> deleteEntry(int id) =>
      (_db.delete(_db.exerciseEntries)..where((e) => e.id.equals(id))).go();

  Stream<List<ExerciseEntry>> watchDay(DateTime day) {
    final query = _db.select(_db.exerciseEntries)
      ..where((e) => e.day.equals(dayKey(day)))
      ..orderBy([
        (e) => OrderingTerm(expression: e.createdAt),
        (e) => OrderingTerm(expression: e.id),
      ]);
    return query.watch().map(
      (rows) => [
        for (final r in rows)
          ExerciseEntry(
            id: r.id,
            type: ExerciseType.values.byName(r.type),
            minutes: r.minutes,
            kcal: r.kcal,
          ),
      ],
    );
  }
}
