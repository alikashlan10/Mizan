/// The exercises phase 1 can log. Stored in the database by name: renaming a
/// value needs a migration.
enum ExerciseType {
  walking(met: 3.5),
  running(met: 9.8),
  weightLifting(met: 3.5, fixedMinutes: 60);

  const ExerciseType({required this.met, this.fixedMinutes});

  /// Intensity: kcal burned per kg of body weight per hour.
  final double met;

  /// Set when a session always counts as the same length, so the user is not
  /// asked for a duration.
  final double? fixedMinutes;
}

/// Estimated calories burned: intensity × body weight × hours.
double exerciseKcal(
  ExerciseType type, {
  required double weightKg,
  required double minutes,
}) => type.met * weightKg * minutes / 60;

/// One logged exercise as shown in the diary.
class ExerciseEntry {
  const ExerciseEntry({
    required this.id,
    required this.type,
    required this.minutes,
    required this.kcal,
  });

  final int id;
  final ExerciseType type;
  final double minutes;
  final double kcal;
}
