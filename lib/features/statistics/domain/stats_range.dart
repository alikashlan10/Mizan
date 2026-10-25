/// The quick choices offered for the statistics range.
enum StatsPreset { today, lastWeek, lastMonth, custom }

/// A span of whole local days, both ends included.
class StatsRange {
  StatsRange({
    required DateTime start,
    required DateTime end,
    required this.preset,
  }) : start = _dateOnly(start),
       end = _dateOnly(end) {
    if (this.end.isBefore(this.start)) {
      throw ArgumentError('The range ends before it starts.');
    }
  }

  /// The range a [preset] stands for, ending on [today].
  factory StatsRange.preset(StatsPreset preset, DateTime today) {
    DateTime daysBefore(int days) =>
        DateTime(today.year, today.month, today.day - days);
    return switch (preset) {
      StatsPreset.today || StatsPreset.custom => StatsRange(
        start: today,
        end: today,
        preset: preset,
      ),
      StatsPreset.lastWeek => StatsRange(
        start: daysBefore(6),
        end: today,
        preset: preset,
      ),
      StatsPreset.lastMonth => StatsRange(
        start: daysBefore(29),
        end: today,
        preset: preset,
      ),
    };
  }

  final DateTime start;
  final DateTime end;
  final StatsPreset preset;

  /// Every day in the range, in order.
  List<DateTime> get days => [
    for (
      var day = start;
      !day.isAfter(end);
      day = DateTime(day.year, day.month, day.day + 1)
    )
      day,
  ];

  bool get isSingleDay => start == end;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
