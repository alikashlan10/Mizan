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
