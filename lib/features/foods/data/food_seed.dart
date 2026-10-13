import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/features/foods/data/food_repository.dart';
import 'package:mizan/features/foods/domain/food_sources.dart';
import 'package:mizan/features/foods/domain/seed_food.dart';

const usdaSeedAsset = 'assets/data/usda_sr.tsv';
const usdaServingsAsset = 'assets/data/usda_sr_servings.tsv';

/// Nutrient columns of the seed file, after the source id and name. Must match
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
    foods.add(SeedFood(sourceId: fields[0], name: fields[1], amounts: amounts));
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

/// Imports the bundled USDA foods the first time the app runs.
Future<void> seedFoodsIfNeeded(
  FoodRepository foods,
  Future<String> Function() loadTsv,
) async {
  if (await foods.hasFoodsFrom(FoodSources.usda)) return;
  await foods.importFoods(FoodSources.usda, parseSeedTsv(await loadTsv()));
}

/// Imports the bundled USDA serving sizes once the foods are in. Separate
/// from the foods so that databases seeded before servings existed gain them.
Future<void> seedServingsIfNeeded(
  FoodRepository foods,
  Future<String> Function() loadTsv,
) async {
  if (await foods.hasServingsFrom(FoodSources.usda)) return;
  await foods.importServings(
    FoodSources.usda,
    parseServingsTsv(await loadTsv()),
  );
}
