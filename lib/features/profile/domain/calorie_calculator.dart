import 'dart:math';

import 'package:mizan/features/profile/domain/profile.dart';

/// Calculated targets are never set below this many kcal per day.
const minimumTargetKcal = 1200.0;

class CalorieEstimate {
  const CalorieEstimate({
    required this.restingKcal,
    required this.maintenanceKcal,
    required this.targetKcal,
    required this.raisedToMinimum,
  });

  /// Calories burned at complete rest (BMR).
  final double restingKcal;

  /// Calories that keep weight stable at the profile's activity level.
  final double maintenanceKcal;

  /// Calories to eat per day for the profile's goal.
  final double targetKcal;

  /// Whether the goal alone would have put the target below the minimum.
  final bool raisedToMinimum;
}

/// Resting calories by the Mifflin-St Jeor equation.
double restingKcal(Profile profile) {
  final base =
      10 * profile.weightKg + 6.25 * profile.heightCm - 5 * profile.age;
  return switch (profile.sex) {
    Sex.male => base + 5,
    Sex.female => base - 161,
  };
}

CalorieEstimate estimateCalories(Profile profile) {
  final resting = restingKcal(profile);
  final maintenance = resting * profile.activity.factor;
  final custom = profile.customTargetKcal;
  final calculated = maintenance + profile.goal.kcalOffset;
  return CalorieEstimate(
    restingKcal: resting,
    maintenanceKcal: maintenance,
    targetKcal: custom ?? max(calculated, minimumTargetKcal),
    raisedToMinimum: custom == null && calculated < minimumTargetKcal,
  );
}
