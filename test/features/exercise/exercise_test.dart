import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/features/exercise/data/exercise_repository.dart';
import 'package:mizan/features/exercise/domain/exercise.dart';

import '../../support/test_database.dart';

void main() {
  final today = DateTime(2026, 10, 13);

  test('calories are intensity × body weight × hours', () {
    expect(
      exerciseKcal(ExerciseType.walking, weightKg: 75, minutes: 30),
      131.25,
    );
    expect(
      exerciseKcal(ExerciseType.running, weightKg: 75, minutes: 30),
      closeTo(367.5, 1e-9),
    );
  });

  test('a weight-lifting session is a fixed 60 minutes', () {
    const lifting = ExerciseType.weightLifting;
    expect(lifting.fixedMinutes, 60);
    expect(
      exerciseKcal(lifting, weightKg: 75, minutes: lifting.fixedMinutes!),
      262.5,
    );
    expect(ExerciseType.walking.fixedMinutes, isNull);
  });

  test('entries are listed for their day and can be deleted', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final exercises = ExerciseRepository(db);

    final run = await exercises.addEntry(
      day: today,
      type: ExerciseType.running,
      minutes: 30,
      kcal: 367.5,
    );
    await exercises.addEntry(
      day: today.add(const Duration(days: 1)),
      type: ExerciseType.walking,
      minutes: 20,
      kcal: 87.5,
    );

    final entry = (await exercises.watchDay(today).first).single;
    expect(entry.type, ExerciseType.running);
    expect(entry.minutes, 30);
    expect(entry.kcal, 367.5);

    await exercises.deleteEntry(run);
    expect(await exercises.watchDay(today).first, isEmpty);
  });

  test('a version 2 database gains the exercise table on upgrade', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) => raw
          ..execute(userProfilesV2Sql)
          ..execute('PRAGMA user_version = 2'),
      ),
    );
    addTearDown(db.close);
    final exercises = ExerciseRepository(db);

    await exercises.addEntry(
      day: today,
      type: ExerciseType.walking,
      minutes: 10,
      kcal: 40,
    );

    expect(await exercises.watchDay(today).first, hasLength(1));
  });
}
