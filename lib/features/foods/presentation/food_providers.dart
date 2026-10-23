import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/features/foods/data/food_repository.dart';
import 'package:mizan/features/foods/data/food_seed.dart';
import 'package:mizan/features/foods/domain/food_nutrient_amount.dart';
import 'package:mizan/features/foods/domain/food_serving.dart';
import 'package:mizan/features/foods/domain/meal_ingredient.dart';

/// Completes once the bundled food datasets are in the database.
final foodSeedProvider = FutureProvider<void>((ref) async {
  final foods = ref.watch(foodRepositoryProvider);
  for (final dataset in bundledDatasets) {
    await seedDataset(foods, dataset, rootBundle.loadString);
  }
});

final nutrientsProvider = FutureProvider<List<Nutrient>>(
  (ref) => ref.watch(foodRepositoryProvider).allNutrients(),
);

/// The datasets that currently have foods, in display order.
final foodSourcesProvider = StreamProvider<List<String>>(
  (ref) => ref.watch(foodRepositoryProvider).watchSources(),
);

/// A search: the text typed and the source tab chosen (null for all sources).
typedef FoodSearch = ({String query, String? source});

/// Live results for a search.
final foodSearchProvider = StreamProvider.autoDispose
    .family<List<Food>, FoodSearch>(
      (ref, search) => ref
          .watch(foodRepositoryProvider)
          .watchSearch(search.query, source: search.source),
    );

/// The serving sizes of the food with the given id. Re-read once seeding
/// finishes, since servings arrive after the foods.
final foodServingsProvider = FutureProvider.autoDispose
    .family<List<FoodServing>, int>((ref, foodId) {
      ref.watch(foodSeedProvider);
      return ref.watch(foodRepositoryProvider).servingsOf(foodId);
    });

/// The ingredients of the meal with the given food id.
final mealIngredientsProvider = FutureProvider.autoDispose
    .family<List<MealIngredient>, int>(
      (ref, mealId) =>
          ref.watch(foodRepositoryProvider).mealIngredients(mealId),
    );

/// The nutrition facts of the food with the given id.
final foodNutrientsProvider = FutureProvider.autoDispose
    .family<List<FoodNutrientAmount>, int>(
      (ref, foodId) => ref.watch(foodRepositoryProvider).nutrientsOf(foodId),
    );
