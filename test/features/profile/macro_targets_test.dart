import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/features/profile/data/profile_repository.dart';
import 'package:mizan/features/profile/domain/macro_targets.dart';
import 'package:mizan/features/profile/domain/profile.dart';

import '../../support/test_database.dart';

Profile _profile(MacroSetting macros) => Profile(
  sex: Sex.male,
  age: 30,
  heightCm: 180,
  weightKg: 80,
  activity: ActivityLevel.moderate,
  goal: Goal.maintain,
  macros: macros,
);

void main() {
  test('the standard split is 20 / 50 / 30 percent of calories', () {
    final grams = macroTargetGrams(
      const MacroSetting.standard(),
      targetKcal: 2000,
    );
    expect(grams.protein, 100); // 400 kcal ÷ 4
    expect(grams.carbs, 250); // 1000 kcal ÷ 4
    expect(grams.fat, closeTo(66.667, 1e-3)); // 600 kcal ÷ 9
  });

  test('custom percentages follow the calorie target', () {
    final grams = macroTargetGrams(
      const MacroSetting.percent(MacroValues(protein: 30, carbs: 40, fat: 30)),
      targetKcal: 2400,
    );
    expect(grams.protein, 180);
    expect(grams.carbs, 240);
    expect(grams.fat, 80);
  });

  test('custom grams ignore the calorie target', () {
    final grams = macroTargetGrams(
      const MacroSetting.grams(MacroValues(protein: 150, carbs: 200, fat: 60)),
      targetKcal: 5000,
    );
    expect(grams.protein, 150);
    expect(grams.carbs, 200);
    expect(grams.fat, 60);
  });

  test('macro settings are saved with the profile', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final profiles = ProfileRepository(db);

    await profiles.saveProfile(_profile(const MacroSetting.standard()));
    var saved = (await profiles.watchProfile().first)!;
    expect(saved.macros.mode, MacroTargetMode.standard);
    expect(saved.macros.values, isNull);

    await profiles.saveProfile(
      _profile(
        const MacroSetting.grams(
          MacroValues(protein: 150, carbs: 200, fat: 60),
        ),
      ),
    );
    saved = (await profiles.watchProfile().first)!;
    expect(saved.macros.mode, MacroTargetMode.grams);
    expect(saved.macros.values!.carbs, 200);
  });

  test(
    'a version 3 profile keeps its data and gains standard macros',
    () async {
      final db = openDatabaseAtVersion(
        3,
        rows: [
          'INSERT INTO user_profiles VALUES '
              "(1, 'female', 28, 165, 60, 'light', 'maintain', NULL)",
        ],
      );
      addTearDown(db.close);

      final saved = (await ProfileRepository(db).watchProfile().first)!;
      expect(saved.sex, Sex.female);
      expect(saved.weightKg, 60);
      expect(saved.macros.mode, MacroTargetMode.standard);
    },
  );
}
