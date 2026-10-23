import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:mizan/core/database/tables.dart';
import 'package:mizan/core/domain/meal.dart';
import 'package:mizan/core/domain/nutrient_catalog.dart';

part 'app_database.g.dart';

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
    RecipeIngredients,
    DatasetImports,
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
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
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
      if (from < 7) await m.addColumn(foods, foods.category);
      if (from < 6) {
        await m.addColumn(foods, foods.deletedAt);
        await m.createTable(recipeIngredients);
      }
      if (from < 3) {
        await m.createTable(waterEntries);
        await m.createTable(exerciseEntries);
      }
      if (from < 8) await m.createTable(datasetImports);
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await _syncNutrients();
    },
  );

  /// Makes the nutrient table match [nutrientCatalog]: adds nutrients the app
  /// has started tracking and refreshes names, units and order. Runs on every
  /// launch, so adding a nutrient needs no migration. Rows are never deleted,
  /// since stored amounts refer to them.
  Future<void> _syncNutrients() async {
    final existing = {
      for (final n in await select(nutrients).get()) n.code: n.id,
    };
    await batch((b) {
      for (final (i, n) in nutrientCatalog.indexed) {
        final row = NutrientsCompanion(
          code: Value(n.code),
          name: Value(n.name),
          unit: Value(n.unit),
          fdcId: Value(n.fdcIds.first),
          sortOrder: Value(i),
        );
        final id = existing[n.code];
        if (id == null) {
          b.insert(nutrients, row);
        } else {
          b.update(nutrients, row, where: (t) => t.id.equals(id));
        }
      }
    });
  }
}
