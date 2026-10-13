import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/features/diary/data/diary_repository.dart';
import 'package:mizan/features/diary/domain/diary_item.dart';

/// The day the diary is showing.
class SelectedDay extends Notifier<DateTime> {
  @override
  DateTime build() => DateUtils.dateOnly(DateTime.now());

  void select(DateTime day) => state = DateUtils.dateOnly(day);

  void shift(int days) => state = DateUtils.addDaysToDate(state, days);
}

final selectedDayProvider = NotifierProvider<SelectedDay, DateTime>(
  SelectedDay.new,
);

final dayEntriesProvider = StreamProvider<List<DiaryItem>>((ref) {
  return ref
      .watch(diaryRepositoryProvider)
      .watchDayEntries(ref.watch(selectedDayProvider));
});

/// Intake for the selected day, keyed by nutrient code.
final dayTotalsProvider = StreamProvider<Map<String, double>>((ref) {
  return ref
      .watch(diaryRepositoryProvider)
      .watchDayTotals(ref.watch(selectedDayProvider));
});
