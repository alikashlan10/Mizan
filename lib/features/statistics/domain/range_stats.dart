import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/features/profile/domain/calorie_calculator.dart';
import 'package:mizan/features/statistics/domain/stats_range.dart';

/// Calories in and out on one day of a range.
class DayBalance {
  const DayBalance({
    required this.day,
    required this.intakeKcal,
    required this.expenditureKcal,
  });

  final DateTime day;

  /// Null on a day with no food logged.
  final double? intakeKcal;

  /// Null on a day with no food logged, or without a profile.
  final double? expenditureKcal;

  /// Positive for a surplus, negative for a deficit; null when either side is
  /// unknown.
  double? get balanceKcal {
    final intake = intakeKcal;
    final out = expenditureKcal;
    return intake == null || out == null ? null : intake - out;
  }
}

/// What was eaten and burned over a [StatsRange].
///
/// Only days with food logged count: a day nobody logged is missing data, not
/// a day of eating nothing, so it is left out of averages and totals.
class RangeStats {
  RangeStats({
    required this.range,
    required Map<DateTime, Map<String, double>> intakeByDay,
    required Map<DateTime, double> exerciseByDay,
    required this.estimate,
  }) : _intake = intakeByDay,
       _exercise = exerciseByDay;

  final StatsRange range;

  /// Calorie figures from the profile; null without one.
  final CalorieEstimate? estimate;

  /// Nutrient totals by day, keyed by nutrient code.
  final Map<DateTime, Map<String, double>> _intake;
  final Map<DateTime, double> _exercise;

  /// Days in the range with food logged, in order.
  late final List<DateTime> loggedDays = [
    for (final day in range.days)
      if (_intake.containsKey(day)) day,
  ];

  bool get hasData => loggedDays.isNotEmpty;

  /// Average daily amount of the nutrient with [code] over logged days.
  double averageOf(String code) => hasData
      ? loggedDays.fold<double>(0, (sum, d) => sum + (_intake[d]![code] ?? 0)) /
            loggedDays.length
      : 0;

  /// Whether any logged food in the range has data for [code].
  bool hasAny(String code) =>
      loggedDays.any((d) => _intake[d]!.containsKey(code));

  /// Average exercise calories over logged days.
  double get averageExerciseKcal => hasData
      ? loggedDays.fold<double>(0, (sum, d) => sum + (_exercise[d] ?? 0)) /
            loggedDays.length
      : 0;

  /// Every day of the range, logged or not, for charting.
  List<DayBalance> get days => [
    for (final day in range.days)
      () {
        final logged = _intake[day];
        final e = estimate;
        return DayBalance(
          day: day,
          intakeKcal: logged == null ? null : logged[NutrientCodes.energy] ?? 0,
          expenditureKcal: logged == null || e == null
              ? null
              : e.maintenanceKcal + (_exercise[day] ?? 0),
        );
      }(),
  ];

  /// Total surplus (positive) or deficit (negative) against expenditure
  /// over logged days; null without a profile or without data.
  double? get totalBalanceKcal {
    if (estimate == null || !hasData) return null;
    return days.fold<double>(0, (sum, d) => sum + (d.balanceKcal ?? 0));
  }

  /// Average surplus or deficit per logged day.
  double? get averageBalanceKcal {
    final total = totalBalanceKcal;
    return total == null ? null : total / loggedDays.length;
  }
}
