import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/features/foods/data/food_repository.dart';
import 'package:mizan/features/foods/data/food_seed.dart';

/// Completes once the bundled food datasets are in the database.
final foodSeedProvider = FutureProvider<void>((ref) {
  return seedFoodsIfNeeded(
    ref.watch(foodRepositoryProvider),
    () => rootBundle.loadString(usdaSeedAsset),
  );
});

final nutrientsProvider = FutureProvider<List<Nutrient>>(
  (ref) => ref.watch(foodRepositoryProvider).allNutrients(),
);

/// Live search results for a query.
final foodSearchProvider = StreamProvider.autoDispose
    .family<List<Food>, String>(
      (ref, query) => ref.watch(foodRepositoryProvider).watchSearch(query),
    );
