import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/domain/display_units.dart';
import 'package:mizan/features/settings/data/settings_repository.dart';

final _storedUnitsProvider = StreamProvider<DisplayUnits>(
  (ref) => ref.watch(settingsRepositoryProvider).watchDisplayUnits(),
);

/// How amounts are shown; the defaults until the stored preferences load.
final displayUnitsProvider = Provider<DisplayUnits>(
  (ref) => ref.watch(_storedUnitsProvider).value ?? const DisplayUnits(),
);
