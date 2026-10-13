import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:mizan/core/database/app_database.dart';

/// The `user_profiles` table as it was in schema versions 2 and 3, for
/// building old databases in migration tests.
const userProfilesV2Sql =
    'CREATE TABLE user_profiles (id INTEGER NOT NULL PRIMARY KEY, '
    'sex TEXT NOT NULL, age INTEGER NOT NULL, height_cm REAL NOT NULL, '
    'weight_kg REAL NOT NULL, activity TEXT NOT NULL, '
    'goal TEXT NOT NULL, custom_target_kcal REAL)';

/// An empty in-memory database for a single test.
AppDatabase newTestDatabase() => AppDatabase(
  // Drift otherwise closes query streams on a timer, which widget tests
  // report as still pending once the widget tree is disposed.
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);
