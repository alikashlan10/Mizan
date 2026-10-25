import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/domain/display_units.dart';
import 'package:mizan/features/settings/data/settings_repository.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository settings;

  setUp(() {
    db = newTestDatabase();
    settings = SettingsRepository(db);
  });
  tearDown(() => db.close());

  test('starts from the defaults', () async {
    final units = await settings.watchDisplayUnits().first;
    expect(units.energyUnit, EnergyUnit.kcal);
    expect(units.weightUnit, WeightUnit.grams);
    expect(units.volumeUnit, VolumeUnit.ml);
    expect(units.defaultAmount, DefaultAmount.per100g);
  });

  test('saves and overwrites preferences', () async {
    await settings.saveDisplayUnits(
      const DisplayUnits().copyWith(energyUnit: EnergyUnit.kj),
    );
    await settings.saveDisplayUnits(
      const DisplayUnits().copyWith(
        weightUnit: WeightUnit.ounces,
        defaultAmount: DefaultAmount.perServing,
      ),
    );
    final units = await settings.watchDisplayUnits().first;
    expect(units.energyUnit, EnergyUnit.kcal);
    expect(units.weightUnit, WeightUnit.ounces);
    expect(units.defaultAmount, DefaultAmount.perServing);
  });

  test('upgrading from version 9 adds the settings table', () async {
    final old = openDatabaseAtVersion(9);
    addTearDown(old.close);
    final units = await SettingsRepository(old).watchDisplayUnits().first;
    expect(units.energyUnit, EnergyUnit.kcal);
  });
}
