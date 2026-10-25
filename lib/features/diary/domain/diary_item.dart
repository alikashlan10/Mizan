import 'package:mizan/core/domain/meal.dart';

/// One logged food as shown in the diary.
class DiaryItem {
  const DiaryItem({
    required this.entryId,
    required this.meal,
    required this.foodName,
    required this.grams,
    required this.kcal,
    this.servingQuantity,
    this.servingLabel,
  });

  final int entryId;
  final Meal meal;
  final String foodName;
  final double grams;

  /// Null when the food has no energy value recorded.
  final double? kcal;

  /// Set when the amount was entered as servings, such as 2 of "1 tbsp".
  final double? servingQuantity;
  final String? servingLabel;
}
