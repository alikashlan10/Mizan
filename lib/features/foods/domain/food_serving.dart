/// A named amount of a food, such as "1 cup, chopped" weighing 140 g.
class FoodServing {
  const FoodServing({
    required this.id,
    required this.label,
    required this.grams,
  });

  final int id;
  final String label;
  final double grams;
}

/// How much of a food: a number of [serving]s, or of grams when [serving] is
/// null.
class FoodAmount {
  const FoodAmount({required this.quantity, this.serving});

  const FoodAmount.grams(double grams) : quantity = grams, serving = null;

  final double quantity;
  final FoodServing? serving;

  double get grams => quantity * (serving?.grams ?? 1);
}
