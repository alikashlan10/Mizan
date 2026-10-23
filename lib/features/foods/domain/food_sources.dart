/// Datasets a food can come from, as stored in `Foods.source`.
abstract final class FoodSources {
  /// USDA SR Legacy: generic foods, mostly as single ingredients.
  static const usda = 'usda_sr';

  /// USDA FNDDS: foods and dishes as people eat them, with portion sizes.
  static const fndds = 'usda_fndds';

  /// A single food whose nutrition facts the user typed in.
  static const custom = 'custom';

  /// A meal the user built from other foods.
  static const meal = 'meal';

  /// Sources whose foods the user can edit and delete.
  static const userCreated = [custom, meal];

  /// The order sources are offered in; unknown ones follow alphabetically.
  static const _order = [usda, fndds, custom, meal];

  static String label(String source) => switch (source) {
    usda => 'USDA',
    fndds => 'FNDDS',
    custom => 'Custom',
    meal => 'Meals',
    _ => source,
  };

  static int compare(String a, String b) {
    int rank(String source) {
      final i = _order.indexOf(source);
      return i < 0 ? _order.length : i;
    }

    final byRank = rank(a).compareTo(rank(b));
    return byRank != 0 ? byRank : a.compareTo(b);
  }
}
