import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/core/domain/display_units.dart';

void main() {
  const metric = DisplayUnits();
  final imperial = metric.copyWith(
    energyUnit: EnergyUnit.kj,
    weightUnit: WeightUnit.ounces,
    volumeUnit: VolumeUnit.flOz,
  );

  test('defaults to kcal, grams and ml', () {
    expect(metric.energy(1234), '1,234 kcal');
    expect(metric.weight(150), '150 g');
    expect(metric.volume(500), '500 ml');
  });

  test('converts energy to kJ and back', () {
    expect(imperial.energy(100), '418 kJ');
    expect(imperial.kcalFrom(418.4), closeTo(100, 1e-9));
  });

  test('converts weight to ounces', () {
    expect(imperial.weight(gramsPerOunce * 2), '2.0 oz');
    expect(imperial.weightValue(100), closeTo(3.527, 0.001));
  });

  test('converts water to fl oz and back', () {
    expect(imperial.volume(mlPerFlOz * 8), '8.0 fl oz');
    expect(imperial.mlFrom(8), closeTo(236.588, 0.001));
    expect(imperial.quickWaterMl.first, closeTo(mlPerFlOz * 8, 1e-9));
  });
}
