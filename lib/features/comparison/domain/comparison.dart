/// How the foods in a comparison are made comparable.
sealed class ComparisonMatch {
  const ComparisonMatch();
}

/// Every food is taken at the same weight, such as 100 g each.
class MatchByWeight extends ComparisonMatch {
  const MatchByWeight(this.grams);

  final double grams;
}

/// Every food is taken at whatever weight supplies the same amount of one
/// nutrient, such as 10 g of carbohydrate each.
class MatchByNutrient extends ComparisonMatch {
  const MatchByNutrient({required this.code, required this.amount});

  /// Code of the nutrient to equalise.
  final String code;

  /// Amount of it, in the nutrient's own unit.
  final double amount;
}

/// Grams of a food to take under [match], given its nutrition facts
/// [per100g] keyed by nutrient code. Null when the food has none of the
/// matched nutrient, so no amount of it would get there.
double? gramsFor(Map<String, double> per100g, ComparisonMatch match) {
  switch (match) {
    case MatchByWeight(:final grams):
      return grams;
    case MatchByNutrient(:final code, :final amount):
      final density = per100g[code];
      return density == null || density <= 0 ? null : amount / density * 100;
  }
}

/// One food in a comparison: how much of it is taken and what that contains.
class ComparedFood {
  const ComparedFood({required this.grams, required this.per100g});

  /// Null when the food cannot supply the matched nutrient.
  final double? grams;
  final Map<String, double> per100g;

  /// Amount of the nutrient with [code] in [grams] of the food. Null when
  /// the food has no value recorded for it or no weight could be worked out.
  double? amountOf(String code) {
    final grams = this.grams;
    final density = per100g[code];
    return grams == null || density == null ? null : density * grams / 100;
  }
}
