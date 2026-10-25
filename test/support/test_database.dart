import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:mizan/core/database/app_database.dart';

/// An empty in-memory database for a single test.
AppDatabase newTestDatabase() => AppDatabase(
  // Drift otherwise closes query streams on a timer, which widget tests
  // report as still pending once the widget tree is disposed.
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

/// A database as it stood at schema [version], for testing upgrades. [rows]
/// are extra statements, such as inserts, run before the app opens it.
AppDatabase openDatabaseAtVersion(int version, {List<String> rows = const []}) {
  return AppDatabase(
    NativeDatabase.memory(
      setup: (raw) {
        for (final entry in _schemaSteps.entries) {
          if (entry.key > version) break;
          entry.value.forEach(raw.execute);
        }
        rows.forEach(raw.execute);
        raw.execute('PRAGMA user_version = $version');
      },
    ),
  );
}

/// What each schema version added, as the SQL that shipped at the time. Add
/// an entry whenever the schema version goes up; never edit an old one.
const _schemaSteps = <int, List<String>>{
  1: [
    'CREATE TABLE nutrients (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        'code TEXT NOT NULL UNIQUE, name TEXT NOT NULL, unit TEXT NOT NULL, '
        'fdc_id INTEGER, sort_order INTEGER NOT NULL)',
    'CREATE TABLE foods (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        'name TEXT NOT NULL, source TEXT NOT NULL, source_id TEXT)',
    'CREATE TABLE food_nutrients (food_id INTEGER NOT NULL REFERENCES foods '
        '(id) ON DELETE CASCADE, nutrient_id INTEGER NOT NULL REFERENCES '
        'nutrients (id), amount REAL NOT NULL, '
        'PRIMARY KEY (food_id, nutrient_id))',
    'CREATE TABLE diary_entries (id INTEGER NOT NULL PRIMARY KEY '
        'AUTOINCREMENT, day TEXT NOT NULL, meal INTEGER NOT NULL, '
        'food_id INTEGER NOT NULL REFERENCES foods (id), grams REAL NOT NULL, '
        "created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', "
        'CURRENT_TIMESTAMP) AS INTEGER)))',
    'INSERT INTO nutrients (code, name, unit, sort_order) VALUES '
        "('energy', 'Energy', 'kcal', 0)",
  ],
  2: [
    'CREATE TABLE user_profiles (id INTEGER NOT NULL PRIMARY KEY, '
        'sex TEXT NOT NULL, age INTEGER NOT NULL, height_cm REAL NOT NULL, '
        'weight_kg REAL NOT NULL, activity TEXT NOT NULL, '
        'goal TEXT NOT NULL, custom_target_kcal REAL)',
  ],
  3: [
    'CREATE TABLE water_entries (id INTEGER NOT NULL PRIMARY KEY '
        'AUTOINCREMENT, day TEXT NOT NULL, ml REAL NOT NULL, '
        "created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', "
        'CURRENT_TIMESTAMP) AS INTEGER)))',
    'CREATE TABLE exercise_entries (id INTEGER NOT NULL PRIMARY KEY '
        'AUTOINCREMENT, day TEXT NOT NULL, type TEXT NOT NULL, '
        'minutes REAL NOT NULL, kcal REAL NOT NULL, '
        "created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', "
        'CURRENT_TIMESTAMP) AS INTEGER)))',
  ],
  4: [
    'ALTER TABLE user_profiles ADD COLUMN macro_mode TEXT NOT NULL '
        "DEFAULT 'standard'",
    'ALTER TABLE user_profiles ADD COLUMN macro_protein REAL',
    'ALTER TABLE user_profiles ADD COLUMN macro_carbs REAL',
    'ALTER TABLE user_profiles ADD COLUMN macro_fat REAL',
  ],
  5: [
    'CREATE TABLE food_servings (id INTEGER NOT NULL PRIMARY KEY '
        'AUTOINCREMENT, food_id INTEGER NOT NULL REFERENCES foods (id) '
        'ON DELETE CASCADE, label TEXT NOT NULL, grams REAL NOT NULL, '
        'sort_order INTEGER NOT NULL)',
  ],
  6: [
    'ALTER TABLE foods ADD COLUMN deleted_at INTEGER',
    'CREATE TABLE recipe_ingredients (id INTEGER NOT NULL PRIMARY KEY '
        'AUTOINCREMENT, recipe_id INTEGER NOT NULL REFERENCES foods (id) '
        'ON DELETE CASCADE, ingredient_id INTEGER NOT NULL REFERENCES foods '
        '(id), grams REAL NOT NULL, sort_order INTEGER NOT NULL)',
  ],
  7: ['ALTER TABLE foods ADD COLUMN category TEXT'],
  8: [
    'CREATE TABLE dataset_imports (source TEXT NOT NULL PRIMARY KEY, '
        'version INTEGER NOT NULL)',
  ],
};
