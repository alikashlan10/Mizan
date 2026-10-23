import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/features/foods/data/food_repository.dart';
import 'package:mizan/features/foods/domain/food_sources.dart';
import 'package:mizan/features/foods/domain/seed_food.dart';

/// A food dataset shipped with the app, built by tool/build_usda_seed.dart.
class BundledDataset {
  const BundledDataset({
    required this.source,
    required this.foodsAsset,
    required this.servingsAsset,
  });

  /// Stored as `Foods.source`; see [FoodSources].
  final String source;
  final String foodsAsset;
  final String servingsAsset;
}

const bundledDatasets = [
  BundledDataset(
    source: FoodSources.usda,
    foodsAsset: 'assets/data/usda_sr.tsv',
    servingsAsset: 'assets/data/usda_sr_servings.tsv',
  ),
  BundledDataset(
    source: FoodSources.fndds,
    foodsAsset: 'assets/data/usda_fndds.tsv',
    servingsAsset: 'assets/data/usda_fndds_servings.tsv',
  ),
];

/// Nutrient columns of a seed file, after the source id and name. Must match
/// the order written by tool/build_usda_seed.dart.
const _seedColumns = [
  NutrientCodes.energy,
  NutrientCodes.protein,
  NutrientCodes.carbs,
  NutrientCodes.fat,
  NutrientCodes.fiber,
  NutrientCodes.sugars,
  NutrientCodes.saturatedFat,
  NutrientCodes.sodium,
];

List<SeedFood> parseSeedTsv(String tsv) {
  final foods = <SeedFood>[];
  for (final line in tsv.split('\n')) {
    if (line.trim().isEmpty) continue;
    final fields = line.split('\t');
    final amounts = <String, double>{};
    for (final (i, code) in _seedColumns.indexed) {
      final value = i + 2 < fields.length
          ? double.tryParse(fields[i + 2])
          : null;
      if (value != null) amounts[code] = value;
    }
    final categoryColumn = _seedColumns.length + 2;
    final category = categoryColumn < fields.length
        ? fields[categoryColumn].trim()
        : '';
    foods.add(
      SeedFood(
        sourceId: fields[0],
        name: fields[1],
        amounts: amounts,
        category: category.isEmpty ? null : category,
      ),
    );
  }
  return foods;
}

/// Parses rows of food source id, order, label and grams.
List<SeedServing> parseServingsTsv(String tsv) {
  final servings = <SeedServing>[];
  for (final line in tsv.split('\n')) {
    final fields = line.trimRight().split('\t');
    if (fields.length < 4) continue;
    final grams = double.tryParse(fields[3]);
    if (grams == null || grams <= 0) continue;
    servings.add(
      SeedServing(
        foodSourceId: fields[0],
        sortOrder: int.tryParse(fields[1]) ?? 0,
        label: fields[2],
        grams: grams,
      ),
    );
  }
  return servings;
}

/// Imports a bundled dataset's foods the first time the app runs with it.
Future<void> seedFoodsIfNeeded(
  FoodRepository foods,
  String source,
  Future<String> Function() loadTsv,
) async {
  if (await foods.hasFoodsFrom(source)) return;
  await foods.importFoods(source, parseSeedTsv(await loadTsv()));
}

/// Fills in the categories of foods imported before categories were bundled.
/// Does nothing once every food from [source] has one.
Future<void> seedCategoriesIfNeeded(
  FoodRepository foods,
  String source,
  Future<String> Function() loadTsv,
) async {
  if (!await foods.hasUncategorisedFrom(source)) return;
  await foods.setCategories(source, {
    for (final food in parseSeedTsv(await loadTsv()))
      food.sourceId: ?food.category,
  });
}

/// Imports a bundled dataset's serving sizes once its foods are in. Separate
/// from the foods so that databases seeded before servings existed gain them.
Future<void> seedServingsIfNeeded(
  FoodRepository foods,
  String source,
  Future<String> Function() loadTsv,
) async {
  if (await foods.hasServingsFrom(source)) return;
  await foods.importServings(source, parseServingsTsv(await loadTsv()));
}

/// Brings one bundled dataset fully into the database: foods, then any
/// categories or servings an older import lacks.
Future<void> seedDataset(
  FoodRepository foods,
  BundledDataset dataset,
  Future<String> Function(String asset) loadAsset,
) async {
  Future<String> loadFoods() => loadAsset(dataset.foodsAsset);
  await seedFoodsIfNeeded(foods, dataset.source, loadFoods);
  await seedCategoriesIfNeeded(foods, dataset.source, loadFoods);
  await seedServingsIfNeeded(
    foods,
    dataset.source,
    () => loadAsset(dataset.servingsAsset),
  );
}
