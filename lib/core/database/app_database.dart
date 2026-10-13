import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:mizan/core/database/tables.dart';
import 'package:mizan/core/domain/meal.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';

part 'app_database.g.dart';

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

/// The single local database. Only repositories may use it; everything else
/// goes through a repository.
@DriftDatabase(
  tables: [
    Nutrients,
    Foods,
    FoodNutrients,
    DiaryEntries,
    UserProfiles,
    WaterEntries,
    ExerciseEntries,
    FoodServings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'mizan',
              // Both files live in web/ and come from the drift release
              // matching the version in pubspec.lock.
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.js'),
              ),
            ),
      );

  @override
  int get schemaVersion => 5;

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
    // Add one step per schema version; never edit a step that has shipped.
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Created in its current shape, so the column steps below are skipped.
        await m.createTable(userProfiles);
      } else if (from < 4) {
        await m.addColumn(userProfiles, userProfiles.macroMode);
        await m.addColumn(userProfiles, userProfiles.macroProtein);
        await m.addColumn(userProfiles, userProfiles.macroCarbs);
        await m.addColumn(userProfiles, userProfiles.macroFat);
      }
      if (from < 5) await m.createTable(foodServings);
      if (from < 3) {
        await m.createTable(waterEntries);
        await m.createTable(exerciseEntries);
      }
    },
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
