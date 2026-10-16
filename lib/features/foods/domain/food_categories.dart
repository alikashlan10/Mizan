import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/features/foods/domain/food_sources.dart';

/// Dataset categories, as stored in `Foods.category`.
abstract final class FoodCategories {
  /// USDA categories of processed, prepared or special-purpose foods. Search
  /// ranks them after whole foods, so that "chicken breast" finds roasted
  /// chicken breast before a chicken breast deli roll.
  static const rankedLast = [
    'Sausages and Luncheon Meats',
    'Fast Foods',
    'Restaurant Foods',
    'Meals, Entrees, and Side Dishes',
    'Baby Foods',
    'Branded Food Products Database',
    'Quality Control Materials',
  ];
}

/// Where a food comes from, for showing under its name: the source, and the
/// category when it has one, such as "USDA · Poultry Products".
String foodOriginLabel(Food food) {
  final source = FoodSources.label(food.source);
  final category = food.category;
  return category == null ? source : '$source · $category';
}
