/// A food from a bundled dataset, with amounts per 100 g keyed by nutrient code.
class SeedFood {
  const SeedFood({
    required this.sourceId,
    required this.name,
    required this.amounts,
  });

  final String sourceId;
  final String name;
  final Map<String, double> amounts;
}

/// A serving size from a bundled dataset, for the food with [foodSourceId].
class SeedServing {
  const SeedServing({
    required this.foodSourceId,
    required this.sortOrder,
    required this.label,
    required this.grams,
  });

  final String foodSourceId;
  final int sortOrder;
  final String label;
  final double grams;
}
