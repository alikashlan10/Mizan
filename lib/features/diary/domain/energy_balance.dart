import 'package:mizan/core/domain/macro_energy.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/features/profile/domain/calorie_calculator.dart';

/// Calories that protein, carbohydrate and fat contribute, using the standard
/// 4 / 4 / 9 kcal per gram.
class MacroEnergy {
  const MacroEnergy({
    required this.proteinKcal,
    required this.carbsKcal,
    required this.fatKcal,
  });

  /// [totals] is intake in grams keyed by nutrient code.
  factory MacroEnergy.fromTotals(Map<String, double> totals) => MacroEnergy(
    proteinKcal: (totals[NutrientCodes.protein] ?? 0) * kcalPerGramProtein,
    carbsKcal: (totals[NutrientCodes.carbs] ?? 0) * kcalPerGramCarbs,
    fatKcal: (totals[NutrientCodes.fat] ?? 0) * kcalPerGramFat,
  );

  final double proteinKcal;
  final double carbsKcal;
  final double fatKcal;
}

/// A day's calories in and out. The figures that depend on the user's profile
/// are null until a profile exists.
class EnergyBalance {
  const EnergyBalance({
    required this.intakeKcal,
    required this.exerciseKcal,
    required this.estimate,
  });

  final double intakeKcal;
  final double exerciseKcal;
  final CalorieEstimate? estimate;

  double? get restingKcal => estimate?.restingKcal;

  /// Everyday movement implied by the profile's activity level.
  double? get activityKcal {
    final e = estimate;
    return e == null ? null : e.maintenanceKcal - e.restingKcal;
  }

  /// Resting + everyday activity + logged exercise.
  double? get expenditureKcal {
    final e = estimate;
    return e == null ? null : e.maintenanceKcal + exerciseKcal;
  }

  /// What can be eaten today: the target plus calories earned by exercise.
  double? get budgetKcal {
    final e = estimate;
    return e == null ? null : e.targetKcal + exerciseKcal;
  }

  /// Negative once intake has passed the budget.
  double? get remainingKcal {
    final budget = budgetKcal;
    return budget == null ? null : budget - intakeKcal;
  }
}
