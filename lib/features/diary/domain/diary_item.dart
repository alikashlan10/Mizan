import 'package:mizan/core/domain/meal.dart';

/// One logged food as shown in the diary.
class DiaryItem {
  const DiaryItem({
    required this.entryId,
    required this.meal,
    required this.foodName,
    required this.grams,
    required this.kcal,
  });

  final int entryId;
  final Meal meal;
  final String foodName;
  final double grams;

  /// Null when the food has no energy value recorded.
  final double? kcal;
}
