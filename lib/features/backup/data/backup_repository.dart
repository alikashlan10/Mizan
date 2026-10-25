import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/database/database_provider.dart';
import 'package:mizan/core/domain/meal.dart';
import 'package:mizan/features/backup/domain/backup_summary.dart';
import 'package:mizan/features/foods/domain/food_sources.dart';

final backupRepositoryProvider = Provider<BackupRepository>(
  (ref) => BackupRepository(ref.watch(appDatabaseProvider)),
);

/// Identifies a backup file and the layout of its contents. Raise
/// [_formatVersion] when the layout changes, and keep reading older ones.
const _app = 'mizan';
const _formatVersion = 1;

/// Writes everything the user created to JSON and restores it.
///
/// Bundled foods are not copied: entries refer to them by dataset and the
/// dataset's own id, which are the same on every install. Foods the user
/// created travel whole, with nutrients by code, and are referred to by an
/// id that only means something inside the file.
class BackupRepository {
  BackupRepository(this._db);

  final AppDatabase _db;

  Future<String> exportJson({DateTime? now}) async {
    final userFoods =
        await (_db.select(_db.foods)
              ..where((f) => f.source.isIn(FoodSources.userCreated))
              ..orderBy([(f) => OrderingTerm(expression: f.id)]))
            .get();
    final userIds = {for (final f in userFoods) f.id};

    // Bundled foods that anything refers to, keyed by id, for their
    // dataset reference.
    final referenced = <int, Food>{};
    Future<void> lookUp(Iterable<int> ids) async {
      final missing = ids.where(
        (id) => !userIds.contains(id) && !referenced.containsKey(id),
      );
      if (missing.isEmpty) return;
      final rows = await (_db.select(
        _db.foods,
      )..where((f) => f.id.isIn(missing.toSet()))).get();
      for (final r in rows) {
        referenced[r.id] = r;
      }
    }

    final nutrientCodes = {
      for (final n in await _db.select(_db.nutrients).get()) n.id: n.code,
    };
    final amounts = await (_db.select(
      _db.foodNutrients,
    )..where((n) => n.foodId.isIn(userIds))).get();
    final servings =
        await (_db.select(_db.foodServings)
              ..where((s) => s.foodId.isIn(userIds))
              ..orderBy([(s) => OrderingTerm(expression: s.sortOrder)]))
            .get();
    final ingredients =
        await (_db.select(_db.recipeIngredients)
              ..where((i) => i.recipeId.isIn(userIds))
              ..orderBy([(i) => OrderingTerm(expression: i.sortOrder)]))
            .get();
    final diary = await (_db.select(
      _db.diaryEntries,
    )..orderBy([(e) => OrderingTerm(expression: e.id)])).get();
    await lookUp([
      ...ingredients.map((i) => i.ingredientId),
      ...diary.map((e) => e.foodId),
    ]);

    Map<String, Object?> ref(int foodId) {
      if (userIds.contains(foodId)) return {'id': foodId};
      final food = referenced[foodId]!;
      return {'source': food.source, 'sourceId': food.sourceId};
    }

    final profile = await _db.select(_db.userProfiles).getSingleOrNull();
    final water = await (_db.select(
      _db.waterEntries,
    )..orderBy([(e) => OrderingTerm(expression: e.id)])).get();
    final exercise = await (_db.select(
      _db.exerciseEntries,
    )..orderBy([(e) => OrderingTerm(expression: e.id)])).get();

    final backup = {
      'app': _app,
      'format': _formatVersion,
      'exportedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'settings': {
        for (final s in await _db.select(_db.appSettings).get()) s.key: s.value,
      },
      'profile': profile == null
          ? null
          : {
              'sex': profile.sex,
              'age': profile.age,
              'heightCm': profile.heightCm,
              'weightKg': profile.weightKg,
              'activity': profile.activity,
              'goal': profile.goal,
              'customTargetKcal': profile.customTargetKcal,
              'macroMode': profile.macroMode,
              'macroProtein': profile.macroProtein,
              'macroCarbs': profile.macroCarbs,
              'macroFat': profile.macroFat,
            },
      'foods': [
        for (final f in userFoods)
          {
            'id': f.id,
            'name': f.name,
            'source': f.source,
            'category': f.category,
            'deletedAt': f.deletedAt?.toUtc().toIso8601String(),
            'nutrients': {
              for (final a in amounts.where((a) => a.foodId == f.id))
                nutrientCodes[a.nutrientId]: a.amount,
            },
            'servings': [
              for (final s in servings.where((s) => s.foodId == f.id))
                {'label': s.label, 'grams': s.grams},
            ],
            'ingredients': [
              for (final i in ingredients.where((i) => i.recipeId == f.id))
                {'food': ref(i.ingredientId), 'grams': i.grams},
            ],
          },
      ],
      'diary': [
        for (final e in diary)
          {
            'day': e.day,
            'meal': e.meal.name,
            'food': ref(e.foodId),
            'grams': e.grams,
            'servingQuantity': e.servingQuantity,
            'servingLabel': e.servingLabel,
            'createdAt': e.createdAt.toUtc().toIso8601String(),
          },
      ],
      'water': [
        for (final e in water)
          {
            'day': e.day,
            'ml': e.ml,
            'createdAt': e.createdAt.toUtc().toIso8601String(),
          },
      ],
      'exercise': [
        for (final e in exercise)
          {
            'day': e.day,
            'type': e.type,
            'minutes': e.minutes,
            'kcal': e.kcal,
            'createdAt': e.createdAt.toUtc().toIso8601String(),
          },
      ],
    };
    return const JsonEncoder.withIndent(' ').convert(backup);
  }

  /// Replaces the user's foods, meals, diary, profile and settings with the
  /// backup in [json]. Nothing changes if the file cannot be read.
  ///
  /// Throws [BackupFormatException] when [json] is not a Mizan backup.
  Future<BackupSummary> importJson(String json) async {
    final Map<String, Object?> backup;
    try {
      backup = jsonDecode(json) as Map<String, Object?>;
    } on FormatException {
      throw const BackupFormatException('This file is not a Mizan backup.');
    } on TypeError {
      throw const BackupFormatException('This file is not a Mizan backup.');
    }
    if (backup['app'] != _app) {
      throw const BackupFormatException('This file is not a Mizan backup.');
    }
    final format = backup['format'];
    if (format is! int || format > _formatVersion) {
      throw const BackupFormatException(
        'This backup was made by a newer version of Mizan. Update the app '
        'to restore it.',
      );
    }

    try {
      return await _db.transaction(() => _restore(backup));
    } on Error {
      // A missing field, a wrong type or an unknown name; the transaction
      // has rolled back.
      throw const BackupFormatException('This backup file is damaged.');
    }
  }

  Future<BackupSummary> _restore(Map<String, Object?> backup) async {
    List<Map<String, Object?>> listOf(String key) => [
      for (final item in (backup[key] as List<Object?>?) ?? const [])
        item! as Map<String, Object?>,
    ];
    final foods = listOf('foods');
    final diary = listOf('diary');
    final water = listOf('water');
    final exercise = listOf('exercise');

    await _clearUserData();

    // Foods first, so meals and diary entries can point at them.
    final nutrientIds = {
      for (final n in await _db.select(_db.nutrients).get()) n.code: n.id,
    };
    final newIds = <int, int>{};
    for (final f in foods) {
      final id = await _db
          .into(_db.foods)
          .insert(
            FoodsCompanion.insert(
              name: f['name']! as String,
              source: f['source']! as String,
              category: Value(f['category'] as String?),
              deletedAt: Value(_dateOrNull(f['deletedAt'])),
            ),
          );
      newIds[f['id']! as int] = id;
      final nutrients = f['nutrients'] as Map<String, Object?>? ?? const {};
      await _db.batch((b) {
        b.insertAll(_db.foodNutrients, [
          for (final MapEntry(:key, :value) in nutrients.entries)
            if (nutrientIds[key] case final nutrientId?)
              FoodNutrientsCompanion.insert(
                foodId: id,
                nutrientId: nutrientId,
                amount: (value! as num).toDouble(),
              ),
        ]);
        b.insertAll(_db.foodServings, [
          for (final (i, s) in _items(f['servings']).indexed)
            FoodServingsCompanion.insert(
              foodId: id,
              label: s['label']! as String,
              grams: (s['grams']! as num).toDouble(),
              sortOrder: i,
            ),
        ]);
      });
    }

    // Bundled foods by dataset reference; null for ones not on this
    // install.
    final bundled = <(String, String), int>{};
    for (final row in await (_db.select(
      _db.foods,
    )..where((f) => f.source.isNotIn(FoodSources.userCreated))).get()) {
      if (row.sourceId != null) bundled[(row.source, row.sourceId!)] = row.id;
    }
    int? resolve(Object? reference) {
      final ref = reference! as Map<String, Object?>;
      if (ref['id'] case final int id) return newIds[id];
      return bundled[(ref['source']! as String, ref['sourceId']! as String)];
    }

    var skipped = 0;
    for (final f in foods) {
      final recipeId = newIds[f['id']! as int]!;
      for (final (i, ingredient) in _items(f['ingredients']).indexed) {
        final foodId = resolve(ingredient['food']);
        if (foodId == null) {
          skipped++;
          continue;
        }
        await _db
            .into(_db.recipeIngredients)
            .insert(
              RecipeIngredientsCompanion.insert(
                recipeId: recipeId,
                ingredientId: foodId,
                grams: (ingredient['grams']! as num).toDouble(),
                sortOrder: i,
              ),
            );
      }
    }

    final diaryRows = <DiaryEntriesCompanion>[];
    for (final e in diary) {
      final foodId = resolve(e['food']);
      if (foodId == null) {
        skipped++;
        continue;
      }
      diaryRows.add(
        DiaryEntriesCompanion.insert(
          day: e['day']! as String,
          meal: Meal.values.byName(e['meal']! as String),
          foodId: foodId,
          grams: (e['grams']! as num).toDouble(),
          servingQuantity: Value((e['servingQuantity'] as num?)?.toDouble()),
          servingLabel: Value(e['servingLabel'] as String?),
          createdAt: Value(_date(e['createdAt'])),
        ),
      );
    }

    final profile = backup['profile'] as Map<String, Object?>?;
    final settings = backup['settings'] as Map<String, Object?>? ?? const {};
    await _db.batch((b) {
      b.insertAll(_db.diaryEntries, diaryRows);
      b.insertAll(_db.waterEntries, [
        for (final e in water)
          WaterEntriesCompanion.insert(
            day: e['day']! as String,
            ml: (e['ml']! as num).toDouble(),
            createdAt: Value(_date(e['createdAt'])),
          ),
      ]);
      b.insertAll(_db.exerciseEntries, [
        for (final e in exercise)
          ExerciseEntriesCompanion.insert(
            day: e['day']! as String,
            type: e['type']! as String,
            minutes: (e['minutes']! as num).toDouble(),
            kcal: (e['kcal']! as num).toDouble(),
            createdAt: Value(_date(e['createdAt'])),
          ),
      ]);
      if (profile != null) {
        b.insert(
          _db.userProfiles,
          UserProfilesCompanion.insert(
            id: const Value(1),
            sex: profile['sex']! as String,
            age: profile['age']! as int,
            heightCm: (profile['heightCm']! as num).toDouble(),
            weightKg: (profile['weightKg']! as num).toDouble(),
            activity: profile['activity']! as String,
            goal: profile['goal']! as String,
            customTargetKcal: Value(
              (profile['customTargetKcal'] as num?)?.toDouble(),
            ),
            macroMode: Value(profile['macroMode'] as String? ?? 'standard'),
            macroProtein: Value((profile['macroProtein'] as num?)?.toDouble()),
            macroCarbs: Value((profile['macroCarbs'] as num?)?.toDouble()),
            macroFat: Value((profile['macroFat'] as num?)?.toDouble()),
          ),
        );
      }
      b.insertAll(_db.appSettings, [
        for (final MapEntry(:key, :value) in settings.entries)
          AppSettingsCompanion.insert(key: key, value: value! as String),
      ]);
    });

    return BackupSummary(
      foods: foods.length,
      diaryEntries: diaryRows.length,
      waterEntries: water.length,
      exerciseEntries: exercise.length,
      skipped: skipped,
    );
  }

  /// Removes everything a backup holds, leaving the bundled foods.
  Future<void> _clearUserData() async {
    final userFoods = _db.selectOnly(_db.foods)
      ..addColumns([_db.foods.id])
      ..where(_db.foods.source.isIn(FoodSources.userCreated));
    await _db.delete(_db.diaryEntries).go();
    await _db.delete(_db.waterEntries).go();
    await _db.delete(_db.exerciseEntries).go();
    await _db.delete(_db.userProfiles).go();
    await _db.delete(_db.appSettings).go();
    await (_db.delete(
      _db.recipeIngredients,
    )..where((i) => i.recipeId.isInQuery(userFoods))).go();
    await (_db.delete(
      _db.foodServings,
    )..where((s) => s.foodId.isInQuery(userFoods))).go();
    await (_db.delete(
      _db.foodNutrients,
    )..where((n) => n.foodId.isInQuery(userFoods))).go();
    await (_db.delete(
      _db.foods,
    )..where((f) => f.source.isIn(FoodSources.userCreated))).go();
  }
}

List<Map<String, Object?>> _items(Object? list) => [
  for (final item in (list as List<Object?>?) ?? const [])
    item! as Map<String, Object?>,
];

DateTime _date(Object? value) => DateTime.parse(value! as String).toLocal();

DateTime? _dateOrNull(Object? value) => value == null ? null : _date(value);

/// The file is not a backup this version of the app can restore.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}
