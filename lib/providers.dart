import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'data/database.dart';
import 'data/food_seed.dart';

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Completes once the bundled food datasets are in the database.
final seedProvider = FutureProvider<void>((ref) {
  return seedFoodsIfNeeded(
    ref.watch(dbProvider),
    () => rootBundle.loadString(usdaSeedAsset),
  );
});

String dayKey(DateTime day) => DateFormat('yyyy-MM-dd').format(day);

class SelectedDay extends Notifier<DateTime> {
  @override
  DateTime build() => DateUtils.dateOnly(DateTime.now());

  void set(DateTime day) => state = DateUtils.dateOnly(day);

  void shift(int days) => state = DateUtils.addDaysToDate(state, days);
}

final selectedDayProvider = NotifierProvider<SelectedDay, DateTime>(
  SelectedDay.new,
);

final dayEntriesProvider = StreamProvider<List<DiaryItem>>((ref) {
  final day = dayKey(ref.watch(selectedDayProvider));
  return ref.watch(dbProvider).watchDayEntries(day);
});

final dayTotalsProvider = StreamProvider<Map<String, double>>((ref) {
  final day = dayKey(ref.watch(selectedDayProvider));
  return ref.watch(dbProvider).watchDayTotals(day);
});
