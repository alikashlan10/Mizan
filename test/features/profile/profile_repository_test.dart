import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/features/profile/data/profile_repository.dart';
import 'package:mizan/features/profile/domain/profile.dart';

import '../../support/test_database.dart';

void main() {
  const profile = Profile(
    sex: Sex.female,
    age: 28,
    heightCm: 165.5,
    weightKg: 60,
    activity: ActivityLevel.veryActive,
    goal: Goal.lightGain,
  );

  test('there is no profile until one is saved', () async {
    final db = newTestDatabase();
    addTearDown(db.close);

    expect(await ProfileRepository(db).watchProfile().first, isNull);
  });

  test('saving again replaces the profile', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final profiles = ProfileRepository(db);

    await profiles.saveProfile(profile);
    await profiles.saveProfile(
      const Profile(
        sex: Sex.female,
        age: 29,
        heightCm: 165.5,
        weightKg: 62,
        activity: ActivityLevel.veryActive,
        goal: Goal.maintain,
        customTargetKcal: 2100,
      ),
    );

    final saved = (await profiles.watchProfile().first)!;
    expect(saved.sex, Sex.female);
    expect(saved.age, 29);
    expect(saved.heightCm, 165.5);
    expect(saved.weightKg, 62);
    expect(saved.activity, ActivityLevel.veryActive);
    expect(saved.goal, Goal.maintain);
    expect(saved.customTargetKcal, 2100);
  });

  test('a version 1 database gains the profile table on upgrade', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) => raw.execute('PRAGMA user_version = 1'),
      ),
    );
    addTearDown(db.close);
    final profiles = ProfileRepository(db);

    await profiles.saveProfile(profile);

    expect((await profiles.watchProfile().first)!.age, 28);
  });
}
