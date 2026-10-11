import 'database.dart';

const usdaSource = 'usda_sr';
const usdaSeedAsset = 'assets/data/usda_sr.tsv';

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

/// Imports the bundled USDA foods the first time the app runs.
Future<void> seedFoodsIfNeeded(
  AppDatabase db,
  Future<String> Function() loadTsv,
) async {
  if (await db.hasFoodsFrom(usdaSource)) return;
  await db.importFoods(usdaSource, parseSeedTsv(await loadTsv()));
}
