import 'package:mizan/features/profile/domain/macro_targets.dart';

// These enums are stored in the database by name: renaming a value needs a
// migration.

enum Sex { male, female }

enum ActivityLevel {
  sedentary(1.2),
  light(1.375),
  moderate(1.55),
  veryActive(1.725),
  extraActive(1.9);

  const ActivityLevel(this.factor);

  /// Multiplier applied to resting calories to get maintenance calories.
  final double factor;
}

enum Goal {
  extremeCut(-750),
  mediumCut(-500),
  lightCut(-250),
  maintain(0),
  lightGain(250),
  mediumGain(500);

  const Goal(this.kcalOffset);

  /// Daily calories added to maintenance.
  final int kcalOffset;
}

class Profile {
  const Profile({
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.activity,
    required this.goal,
    this.customTargetKcal,
    this.macros = const MacroSetting.standard(),
  });

  final Sex sex;
  final int age;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activity;
  final Goal goal;

  /// Daily target set by hand, replacing the calculated one.
  final double? customTargetKcal;

  /// How the daily protein, carbohydrate and fat targets are set.
  final MacroSetting macros;
}
