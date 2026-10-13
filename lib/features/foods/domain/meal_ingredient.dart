/// One food in a meal, with how much of it goes in.
class MealIngredient {
  const MealIngredient({
    required this.foodId,
    required this.name,
    required this.grams,
    this.kcalPer100g,
  });

  final int foodId;
  final String name;
  final double grams;

  /// Null when the food has no energy value recorded.
  final double? kcalPer100g;

  /// Calories this ingredient adds to the meal; zero when unknown.
  double get kcal => (kcalPer100g ?? 0) * grams / 100;
}
