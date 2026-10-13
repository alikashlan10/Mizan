import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/database/database_provider.dart';
import 'package:mizan/features/profile/domain/macro_targets.dart';
import 'package:mizan/features/profile/domain/profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(appDatabaseProvider)),
);

/// The app has a single user, stored as the row with this id.
const _profileId = 1;

class ProfileRepository {
  ProfileRepository(this._db);

  final AppDatabase _db;

  /// The saved profile, or null until the user has filled it in.
  Stream<Profile?> watchProfile() {
    final query = _db.select(_db.userProfiles)
      ..where((p) => p.id.equals(_profileId));
    return query.watchSingleOrNull().map(
      (row) => row == null
          ? null
          : Profile(
              sex: Sex.values.byName(row.sex),
              age: row.age,
              heightCm: row.heightCm,
              weightKg: row.weightKg,
              activity: ActivityLevel.values.byName(row.activity),
              goal: Goal.values.byName(row.goal),
              customTargetKcal: row.customTargetKcal,
              macros: _macrosOf(row),
            ),
    );
  }

  MacroSetting _macrosOf(UserProfile row) {
    final mode = MacroTargetMode.values.byName(row.macroMode);
    if (mode == MacroTargetMode.standard) return const MacroSetting.standard();
    final values = MacroValues(
      protein: row.macroProtein!,
      carbs: row.macroCarbs!,
      fat: row.macroFat!,
    );
    return mode == MacroTargetMode.percent
        ? MacroSetting.percent(values)
        : MacroSetting.grams(values);
  }

  Future<void> saveProfile(Profile profile) => _db
      .into(_db.userProfiles)
      .insertOnConflictUpdate(
        UserProfilesCompanion.insert(
          id: const Value(_profileId),
          sex: profile.sex.name,
          age: profile.age,
          heightCm: profile.heightCm,
          weightKg: profile.weightKg,
          activity: profile.activity.name,
          goal: profile.goal.name,
          customTargetKcal: Value(profile.customTargetKcal),
          macroMode: Value(profile.macros.mode.name),
          macroProtein: Value(profile.macros.values?.protein),
          macroCarbs: Value(profile.macros.values?.carbs),
          macroFat: Value(profile.macros.values?.fat),
        ),
      );
}
