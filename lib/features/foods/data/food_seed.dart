import 'package:mizan/core/domain/nutrient_catalog.dart';
import 'package:mizan/features/foods/data/food_repository.dart';
import 'package:mizan/features/foods/domain/food_sources.dart';
import 'package:mizan/features/foods/domain/seed_food.dart';

/// A food dataset shipped with the app, built by tool/build_usda_seed.dart.
class BundledDataset {
  const BundledDataset({
    required this.source,
    required this.foodsAsset,
    required this.servingsAsset,
    required this.version,
  });

  /// Stored as `Foods.source`; see [FoodSources].
  final String source;
  final String foodsAsset;
  final String servingsAsset;

  /// Raise when the bundled file gains data that existing installs should
  /// pick up, such as more nutrients. Version 1 had eight nutrients; version 2
  /// has the full catalogue.
  final int version;
}

const bundledDatasets = [
  BundledDataset(
    source: FoodSources.usda,
    foodsAsset: 'assets/data/usda_sr.tsv',
    servingsAsset: 'assets/data/usda_sr_servings.tsv',
    version: 2,
  ),
  BundledDataset(
    source: FoodSources.foundation,
    foodsAsset: 'assets/data/usda_foundation.tsv',
    servingsAsset: 'assets/data/usda_foundation_servings.tsv',
    version: 2,
  ),
  BundledDataset(
    source: FoodSources.fndds,
    foodsAsset: 'assets/data/usda_fndds.tsv',
    servingsAsset: 'assets/data/usda_fndds_servings.tsv',
    version: 2,
  ),
];

/// Parses a seed file: a header naming the columns (source id, name,
/// category, then one nutrient code per column), then one food per line.
/// Blank amounts are left out; columns for nutrients the app does not track
/// are ignored.
List<SeedFood> parseSeedTsv(String tsv) {
  final lines = tsv.split('\n');
  if (lines.isEmpty) return const [];
  final header = lines.first.trimRight().split('\t');
  final tracked = {for (final n in nutrientCatalog) n.code};
  final nutrientColumns = [
    for (final (i, code) in header.indexed)
      if (i >= 3 && tracked.contains(code)) (i, code),
  ];

  final foods = <SeedFood>[];
  for (final line in lines.skip(1)) {
    if (line.trim().isEmpty) continue;
    final fields = line.trimRight().split('\t');
    final amounts = <String, double>{
      for (final (i, code) in nutrientColumns)
        if (i < fields.length) code: ?double.tryParse(fields[i]),
    };
    final category = fields.length > 2 ? fields[2].trim() : '';
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
  final hadFoods = await foods.hasFoodsFrom(dataset.source);
  await seedFoodsIfNeeded(foods, dataset.source, loadFoods);
  // Foods imported by an older version of the app lack newer data. A
  // dataset seeded before versions were recorded counts as version 1.
  final recorded = await foods.importVersion(dataset.source);
  if (hadFoods && (recorded ?? 1) < dataset.version) {
    await foods.refreshFacts(dataset.source, parseSeedTsv(await loadFoods()));
  }
  if (recorded != dataset.version) {
    await foods.setImportVersion(dataset.source, dataset.version);
  }
  await seedCategoriesIfNeeded(foods, dataset.source, loadFoods);
  await seedServingsIfNeeded(
    foods,
    dataset.source,
    () => loadAsset(dataset.servingsAsset),
  );
}
