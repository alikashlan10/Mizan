/// Datasets a food can come from, as stored in `Foods.source`.
abstract final class FoodSources {
  static const usda = 'usda_sr';
  static const custom = 'custom';

  static String label(String source) => switch (source) {
    usda => 'USDA',
    custom => 'Custom',
    _ => source,
  };
}
