import 'package:mizan/features/profile/domain/profile.dart';

extension SexLabel on Sex {
  String get label => switch (this) {
    Sex.male => 'Male',
    Sex.female => 'Female',
  };
}

extension ActivityLevelLabel on ActivityLevel {
  String get label => switch (this) {
    ActivityLevel.sedentary => 'Sedentary',
    ActivityLevel.light => 'Lightly active',
    ActivityLevel.moderate => 'Moderately active',
    ActivityLevel.veryActive => 'Very active',
    ActivityLevel.extraActive => 'Extra active',
  };

  String get description => switch (this) {
    ActivityLevel.sedentary => 'Little or no exercise',
    ActivityLevel.light => 'Exercise 1–3 days a week',
    ActivityLevel.moderate => 'Exercise 3–5 days a week',
    ActivityLevel.veryActive => 'Exercise 6–7 days a week',
    ActivityLevel.extraActive => 'Hard daily exercise or a physical job',
  };
}

extension GoalLabel on Goal {
  String get label => switch (this) {
    Goal.extremeCut => 'Extreme cut',
    Goal.mediumCut => 'Medium cut',
    Goal.lightCut => 'Light cut',
    Goal.maintain => 'Maintain weight',
    Goal.lightGain => 'Light gain',
    Goal.mediumGain => 'Medium gain',
  };

  /// The daily offset from maintenance, such as `−500 kcal`.
  String get offsetLabel => switch (kcalOffset) {
    0 => 'No change',
    < 0 => '−${-kcalOffset} kcal',
    _ => '+$kcalOffset kcal',
  };
}
