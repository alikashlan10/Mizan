import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/features/profile/domain/calorie_calculator.dart';
import 'package:mizan/features/profile/domain/profile.dart';

void main() {
  const man = Profile(
    sex: Sex.male,
    age: 30,
    heightCm: 180,
    weightKg: 80,
    activity: ActivityLevel.moderate,
    goal: Goal.mediumCut,
  );
  const smallWoman = Profile(
    sex: Sex.female,
    age: 30,
    heightCm: 165,
    weightKg: 60,
    activity: ActivityLevel.sedentary,
    goal: Goal.extremeCut,
  );

  test('resting calories follow Mifflin-St Jeor', () {
    // 10 × 80 + 6.25 × 180 − 5 × 30 + 5
    expect(restingKcal(man), 1780);
    // 10 × 60 + 6.25 × 165 − 5 × 30 − 161
    expect(restingKcal(smallWoman), 1320.25);
  });

  test('target is maintenance plus the goal offset', () {
    final estimate = estimateCalories(man);
    expect(estimate.maintenanceKcal, closeTo(2759, 1e-9));
    expect(estimate.targetKcal, closeTo(2259, 1e-9));
    expect(estimate.raisedToMinimum, isFalse);
  });

  test('a calculated target is never below the minimum', () {
    final estimate = estimateCalories(smallWoman);
    // Maintenance 1584.3 − 750 would be 834.3.
    expect(estimate.targetKcal, minimumTargetKcal);
    expect(estimate.raisedToMinimum, isTrue);
  });

  test('a custom target replaces the calculated one', () {
    const custom = Profile(
      sex: Sex.female,
      age: 30,
      heightCm: 165,
      weightKg: 60,
      activity: ActivityLevel.sedentary,
      goal: Goal.extremeCut,
      customTargetKcal: 1000,
    );
    final estimate = estimateCalories(custom);
    expect(estimate.targetKcal, 1000);
    expect(estimate.raisedToMinimum, isFalse);
    expect(estimate.maintenanceKcal, closeTo(1584.3, 1e-9));
  });
}
