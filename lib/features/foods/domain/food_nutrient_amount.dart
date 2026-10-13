/// How much of one nutrient a food contains per 100 g.
class FoodNutrientAmount {
  const FoodNutrientAmount({
    required this.code,
    required this.name,
    required this.unit,
    required this.amountPer100g,
  });

  final String code;
  final String name;
  final String unit;
  final double amountPer100g;

  /// The amount in [grams] of the food.
  double amountIn(double grams) => amountPer100g * grams / 100;
}
