/// Datasets a food can come from, as stored in `Foods.source`.
abstract final class FoodSources {
  static const usda = 'usda_sr';
  static const custom = 'custom';

  /// The order sources are offered in; unknown ones follow alphabetically.
  static const _order = [usda, custom];

  static String label(String source) => switch (source) {
    usda => 'USDA',
    custom => 'Custom',
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
