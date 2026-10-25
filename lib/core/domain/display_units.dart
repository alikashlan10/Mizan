import 'package:mizan/core/formatting/amount_format.dart';

// Everything is stored in kcal, grams and millilitres; these only change how
// amounts are shown and entered. Stored in the settings table by name.

enum EnergyUnit { kcal, kj }

enum WeightUnit { grams, ounces }

enum VolumeUnit { ml, flOz }

/// The starting amount offered when looking at or logging a food.
enum DefaultAmount {
  /// 100 g (or its equivalent in ounces).
  per100g,

  /// The food's first serving size, when it has one.
  perServing,
}

const kjPerKcal = 4.184;
const gramsPerOunce = 28.349523125;
const mlPerFlOz = 29.5735295625;

/// How the user wants amounts shown.
class DisplayUnits {
  const DisplayUnits({
    this.energyUnit = EnergyUnit.kcal,
    this.weightUnit = WeightUnit.grams,
    this.volumeUnit = VolumeUnit.ml,
    this.defaultAmount = DefaultAmount.per100g,
  });

  final EnergyUnit energyUnit;
  final WeightUnit weightUnit;
  final VolumeUnit volumeUnit;
  final DefaultAmount defaultAmount;

  DisplayUnits copyWith({
    EnergyUnit? energyUnit,
    WeightUnit? weightUnit,
    VolumeUnit? volumeUnit,
    DefaultAmount? defaultAmount,
  }) => DisplayUnits(
    energyUnit: energyUnit ?? this.energyUnit,
    weightUnit: weightUnit ?? this.weightUnit,
    volumeUnit: volumeUnit ?? this.volumeUnit,
    defaultAmount: defaultAmount ?? this.defaultAmount,
  );

  // Energy.

  String get energyLabel => energyUnit == EnergyUnit.kcal ? 'kcal' : 'kJ';

  /// [kcal] in the chosen unit.
  double energyValue(double kcal) =>
      energyUnit == EnergyUnit.kcal ? kcal : kcal * kjPerKcal;

  /// An amount entered in the chosen unit, back in kcal.
  double kcalFrom(double value) =>
      energyUnit == EnergyUnit.kcal ? value : value / kjPerKcal;

  /// Whole number with separators, without the unit: "1,234".
  String energyNumber(double kcal) => formatWhole(energyValue(kcal));

  /// "1,234 kcal" or "5,163 kJ".
  String energy(double kcal) => '${energyNumber(kcal)} $energyLabel';

  // Food weight.

  String get weightLabel => weightUnit == WeightUnit.grams ? 'g' : 'oz';

  /// [grams] of food in the chosen unit.
  double weightValue(double grams) =>
      weightUnit == WeightUnit.grams ? grams : grams / gramsPerOunce;

  /// "150 g" or "5.3 oz".
  String weight(double grams) =>
      '${formatAmount(weightValue(grams))} $weightLabel';

  // Water.

  String get volumeLabel => volumeUnit == VolumeUnit.ml ? 'ml' : 'fl oz';

  double volumeValue(double ml) =>
      volumeUnit == VolumeUnit.ml ? ml : ml / mlPerFlOz;

  double mlFrom(double value) =>
      volumeUnit == VolumeUnit.ml ? value : value * mlPerFlOz;

  /// "500 ml" or "16.9 fl oz".
  String volume(double ml) => volumeUnit == VolumeUnit.ml
      ? '${ml.round()} ml'
      : '${formatAmount(volumeValue(ml))} fl oz';

  /// Quick amounts offered when logging water, in millilitres.
  List<double> get quickWaterMl => volumeUnit == VolumeUnit.ml
      ? const [250, 330, 500, 750]
      : [
          for (final oz in const [8, 12, 16, 24]) oz * mlPerFlOz,
        ];
}
