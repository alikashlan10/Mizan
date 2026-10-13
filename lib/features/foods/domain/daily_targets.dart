import 'package:mizan/core/domain/macro_energy.dart';
import 'package:mizan/features/foods/domain/daily_values.dart';

/// The daily amounts a food's nutrition facts are measured against.
class DailyTargets {
  const DailyTargets({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.isPersonal,
  });

  /// A general 2,000 kcal diet split 20 / 50 / 30 between protein,
  /// carbohydrate and fat, for when the user has no targets of their own.
  const DailyTargets.reference()
    : kcal = referenceDailyKcal,
      proteinG = referenceDailyKcal * 0.20 / kcalPerGramProtein,
      carbsG = referenceDailyKcal * 0.50 / kcalPerGramCarbs,
      fatG = referenceDailyKcal * 0.30 / kcalPerGramFat,
      isPersonal = false;

  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  /// Whether these come from the user's profile rather than the reference.
  final bool isPersonal;
}
