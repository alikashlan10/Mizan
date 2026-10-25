/// What a restore brought back.
class BackupSummary {
  const BackupSummary({
    required this.foods,
    required this.diaryEntries,
    required this.waterEntries,
    required this.exerciseEntries,
    required this.skipped,
  });

  /// Custom foods and meals.
  final int foods;
  final int diaryEntries;
  final int waterEntries;
  final int exerciseEntries;

  /// Diary entries and meal ingredients left out because they use a bundled
  /// food this install does not have.
  final int skipped;
}
