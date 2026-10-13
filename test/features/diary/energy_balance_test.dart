import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/features/diary/domain/energy_balance.dart';
import 'package:mizan/features/profile/domain/calorie_calculator.dart';

void main() {
  const estimate = CalorieEstimate(
    restingKcal: 1780,
    maintenanceKcal: 2759,
    targetKcal: 2259,
    raisedToMinimum: false,
  );

  test('macro energy uses 4, 4 and 9 kcal per gram', () {
    final macros = MacroEnergy.fromTotals({
      NutrientCodes.protein: 10,
      NutrientCodes.carbs: 20,
    });
    expect(macros.proteinKcal, 40);
    expect(macros.carbsKcal, 80);
    expect(macros.fatKcal, 0);
  });

  test('expenditure is resting, activity and exercise together', () {
    const balance = EnergyBalance(
      intakeKcal: 1000,
      exerciseKcal: 300,
      estimate: estimate,
    );
    expect(balance.restingKcal, 1780);
    expect(balance.activityKcal, 979);
    expect(balance.expenditureKcal, 3059);
  });

  test('exercise adds to what is left to eat', () {
    const balance = EnergyBalance(
      intakeKcal: 1000,
      exerciseKcal: 300,
      estimate: estimate,
    );
    expect(balance.budgetKcal, 2559);
    expect(balance.remainingKcal, 1559);
  });

  test('remaining goes negative once over budget', () {
    const balance = EnergyBalance(
      intakeKcal: 2500,
      exerciseKcal: 0,
      estimate: estimate,
    );
    expect(balance.remainingKcal, -241);
  });

  test('profile figures are unknown without a profile', () {
    const balance = EnergyBalance(
      intakeKcal: 500,
      exerciseKcal: 100,
      estimate: null,
    );
    expect(balance.expenditureKcal, isNull);
    expect(balance.remainingKcal, isNull);
    expect(balance.activityKcal, isNull);
  });
}
