import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/database/database_provider.dart';
import 'package:mizan/core/domain/display_units.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);

/// Keys of the stored preferences.
abstract final class _Keys {
  static const energyUnit = 'energy_unit';
  static const weightUnit = 'weight_unit';
  static const volumeUnit = 'volume_unit';
  static const defaultAmount = 'default_amount';
}

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  /// The display preferences; defaults for any not set yet.
  Stream<DisplayUnits> watchDisplayUnits() {
    return _db.select(_db.appSettings).watch().map((rows) {
      final values = {for (final r in rows) r.key: r.value};
      T pick<T extends Enum>(List<T> options, String key, T fallback) {
        final name = values[key];
        for (final o in options) {
          if (o.name == name) return o;
        }
        return fallback;
      }

      return DisplayUnits(
        energyUnit: pick(EnergyUnit.values, _Keys.energyUnit, EnergyUnit.kcal),
        weightUnit: pick(WeightUnit.values, _Keys.weightUnit, WeightUnit.grams),
        volumeUnit: pick(VolumeUnit.values, _Keys.volumeUnit, VolumeUnit.ml),
        defaultAmount: pick(
          DefaultAmount.values,
          _Keys.defaultAmount,
          DefaultAmount.per100g,
        ),
      );
    });
  }

  Future<void> saveDisplayUnits(DisplayUnits units) {
    return _db.batch((b) {
      b.insertAllOnConflictUpdate(_db.appSettings, [
        for (final (key, value) in [
          (_Keys.energyUnit, units.energyUnit),
          (_Keys.weightUnit, units.weightUnit),
          (_Keys.volumeUnit, units.volumeUnit),
          (_Keys.defaultAmount, units.defaultAmount),
        ])
          AppSettingsCompanion.insert(key: key, value: value.name),
      ]);
    });
  }
}
