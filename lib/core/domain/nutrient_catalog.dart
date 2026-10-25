// Every nutrient the app tracks. This file is the single source of truth:
// the database's nutrient list is synced from it on every launch, and
// tool/build_usda_seed.dart uses it to decide which columns to write.
//
// Plain Dart with no Flutter imports, so the build tool can use it too.

import 'package:mizan/core/domain/nutrient_codes.dart';

/// How nutrients are grouped on screen, in display order.
enum NutrientGroup {
  general,
  carbohydrates,
  lipids,
  protein,
  vitamins,
  minerals,
}

class NutrientDefinition {
  const NutrientDefinition(
    this.code,
    this.name,
    this.unit,
    this.group,
    this.fdcIds, {
    this.dailyValue,
    this.isLimit = false,
  });

  /// Stable identifier, stored in the database.
  final String code;
  final String name;

  /// Display unit: kcal, g, mg or µg.
  final String unit;
  final NutrientGroup group;

  /// USDA FoodData Central nutrient ids, most preferred first. Newer USDA
  /// datasets often leave the classic field empty and report an alternative.
  final List<int> fdcIds;

  /// General daily reference amount for adults (US FDA Daily Value), in
  /// [unit]; null where there is none. Energy and the macros are measured
  /// against the user's own targets instead.
  final double? dailyValue;

  /// Whether [dailyValue] is a ceiling to stay under rather than an amount
  /// to reach, as for sodium.
  final bool isLimit;
}

const nutrientCatalog = <NutrientDefinition>[
  // General.
  NutrientDefinition(
    NutrientCodes.energy,
    'Energy',
    'kcal',
    NutrientGroup.general,
    [1008, 2048, 2047],
  ),
  NutrientDefinition('water', 'Water', 'g', NutrientGroup.general, [1051]),
  NutrientDefinition('alcohol', 'Alcohol', 'g', NutrientGroup.general, [1018]),
  NutrientDefinition('caffeine', 'Caffeine', 'mg', NutrientGroup.general, [
    1057,
  ]),

  // Carbohydrates.
  NutrientDefinition(
    NutrientCodes.carbs,
    'Carbohydrates',
    'g',
    NutrientGroup.carbohydrates,
    [1005, 1050],
  ),
  NutrientDefinition(
    NutrientCodes.fiber,
    'Fiber',
    'g',
    NutrientGroup.carbohydrates,
    [1079],
    dailyValue: 28,
  ),
  NutrientDefinition(
    NutrientCodes.sugars,
    'Sugars',
    'g',
    NutrientGroup.carbohydrates,
    [2000, 1063],
  ),
  NutrientDefinition('starch', 'Starch', 'g', NutrientGroup.carbohydrates, [
    1009,
  ]),

  // Lipids.
  NutrientDefinition(NutrientCodes.fat, 'Fat', 'g', NutrientGroup.lipids, [
    1004,
  ]),
  NutrientDefinition(
    NutrientCodes.saturatedFat,
    'Saturated fat',
    'g',
    NutrientGroup.lipids,
    [1258],
    dailyValue: 20,
    isLimit: true,
  ),
  NutrientDefinition(
    'monounsaturated_fat',
    'Monounsaturated fat',
    'g',
    NutrientGroup.lipids,
    [1292],
  ),
  NutrientDefinition(
    'polyunsaturated_fat',
    'Polyunsaturated fat',
    'g',
    NutrientGroup.lipids,
    [1293],
  ),
  NutrientDefinition('trans_fat', 'Trans fat', 'g', NutrientGroup.lipids, [
    1257,
  ]),
  NutrientDefinition(
    'cholesterol',
    'Cholesterol',
    'mg',
    NutrientGroup.lipids,
    [1253],
    dailyValue: 300,
    isLimit: true,
  ),
  NutrientDefinition('omega3_ala', 'Omega-3 ALA', 'g', NutrientGroup.lipids, [
    1404,
    1270,
  ]),
  NutrientDefinition('omega3_epa', 'Omega-3 EPA', 'g', NutrientGroup.lipids, [
    1278,
  ]),
  NutrientDefinition('omega3_dha', 'Omega-3 DHA', 'g', NutrientGroup.lipids, [
    1272,
  ]),
  NutrientDefinition(
    'omega6_la',
    'Omega-6 linoleic acid',
    'g',
    NutrientGroup.lipids,
    [1316, 1269],
  ),

  // Protein and amino acids.
  NutrientDefinition(
    NutrientCodes.protein,
    'Protein',
    'g',
    NutrientGroup.protein,
    [1003],
  ),
  NutrientDefinition('tryptophan', 'Tryptophan', 'g', NutrientGroup.protein, [
    1210,
  ]),
  NutrientDefinition('threonine', 'Threonine', 'g', NutrientGroup.protein, [
    1211,
  ]),
  NutrientDefinition('isoleucine', 'Isoleucine', 'g', NutrientGroup.protein, [
    1212,
  ]),
  NutrientDefinition('leucine', 'Leucine', 'g', NutrientGroup.protein, [1213]),
  NutrientDefinition('lysine', 'Lysine', 'g', NutrientGroup.protein, [1214]),
  NutrientDefinition('methionine', 'Methionine', 'g', NutrientGroup.protein, [
    1215,
  ]),
  NutrientDefinition('cystine', 'Cystine', 'g', NutrientGroup.protein, [1216]),
  NutrientDefinition(
    'phenylalanine',
    'Phenylalanine',
    'g',
    NutrientGroup.protein,
    [1217],
  ),
  NutrientDefinition('tyrosine', 'Tyrosine', 'g', NutrientGroup.protein, [
    1218,
  ]),
  NutrientDefinition('valine', 'Valine', 'g', NutrientGroup.protein, [1219]),
  NutrientDefinition('arginine', 'Arginine', 'g', NutrientGroup.protein, [
    1220,
  ]),
  NutrientDefinition('histidine', 'Histidine', 'g', NutrientGroup.protein, [
    1221,
  ]),
  NutrientDefinition('alanine', 'Alanine', 'g', NutrientGroup.protein, [1222]),
  NutrientDefinition(
    'aspartic_acid',
    'Aspartic acid',
    'g',
    NutrientGroup.protein,
    [1223],
  ),
  NutrientDefinition(
    'glutamic_acid',
    'Glutamic acid',
    'g',
    NutrientGroup.protein,
    [1224],
  ),
  NutrientDefinition('glycine', 'Glycine', 'g', NutrientGroup.protein, [1225]),
  NutrientDefinition('proline', 'Proline', 'g', NutrientGroup.protein, [1226]),
  NutrientDefinition('serine', 'Serine', 'g', NutrientGroup.protein, [1227]),

  // Vitamins.
  NutrientDefinition('vitamin_a', 'Vitamin A', 'µg', NutrientGroup.vitamins, [
    1106,
  ], dailyValue: 900),
  NutrientDefinition('vitamin_c', 'Vitamin C', 'mg', NutrientGroup.vitamins, [
    1162,
  ], dailyValue: 90),
  NutrientDefinition('vitamin_d', 'Vitamin D', 'µg', NutrientGroup.vitamins, [
    1114,
  ], dailyValue: 20),
  NutrientDefinition('vitamin_e', 'Vitamin E', 'mg', NutrientGroup.vitamins, [
    1109,
  ], dailyValue: 15),
  NutrientDefinition('vitamin_k', 'Vitamin K', 'µg', NutrientGroup.vitamins, [
    1185,
  ], dailyValue: 120),
  NutrientDefinition('thiamin', 'B1 (Thiamin)', 'mg', NutrientGroup.vitamins, [
    1165,
  ], dailyValue: 1.2),
  NutrientDefinition(
    'riboflavin',
    'B2 (Riboflavin)',
    'mg',
    NutrientGroup.vitamins,
    [1166],
    dailyValue: 1.3,
  ),
  NutrientDefinition('niacin', 'B3 (Niacin)', 'mg', NutrientGroup.vitamins, [
    1167,
  ], dailyValue: 16),
  NutrientDefinition(
    'pantothenic_acid',
    'B5 (Pantothenic acid)',
    'mg',
    NutrientGroup.vitamins,
    [1170],
    dailyValue: 5,
  ),
  NutrientDefinition(
    'vitamin_b6',
    'B6 (Pyridoxine)',
    'mg',
    NutrientGroup.vitamins,
    [1175],
    dailyValue: 1.7,
  ),
  NutrientDefinition(
    'folate',
    'B9 (Folate)',
    'µg',
    NutrientGroup.vitamins,
    // Dietary folate equivalents, else total folate.
    [1190, 1177],
    dailyValue: 400,
  ),
  NutrientDefinition(
    'vitamin_b12',
    'B12 (Cobalamin)',
    'µg',
    NutrientGroup.vitamins,
    [1178],
    dailyValue: 2.4,
  ),
  NutrientDefinition('choline', 'Choline', 'mg', NutrientGroup.vitamins, [
    1180,
  ], dailyValue: 550),

  // Minerals.
  NutrientDefinition('calcium', 'Calcium', 'mg', NutrientGroup.minerals, [
    1087,
  ], dailyValue: 1300),
  NutrientDefinition('copper', 'Copper', 'mg', NutrientGroup.minerals, [
    1098,
  ], dailyValue: 0.9),
  NutrientDefinition('iron', 'Iron', 'mg', NutrientGroup.minerals, [
    1089,
  ], dailyValue: 18),
  NutrientDefinition('magnesium', 'Magnesium', 'mg', NutrientGroup.minerals, [
    1090,
  ], dailyValue: 420),
  NutrientDefinition('manganese', 'Manganese', 'mg', NutrientGroup.minerals, [
    1101,
  ], dailyValue: 2.3),
  NutrientDefinition('phosphorus', 'Phosphorus', 'mg', NutrientGroup.minerals, [
    1091,
  ], dailyValue: 1250),
  NutrientDefinition('potassium', 'Potassium', 'mg', NutrientGroup.minerals, [
    1092,
  ], dailyValue: 4700),
  NutrientDefinition('selenium', 'Selenium', 'µg', NutrientGroup.minerals, [
    1103,
  ], dailyValue: 55),
  NutrientDefinition(
    NutrientCodes.sodium,
    'Sodium',
    'mg',
    NutrientGroup.minerals,
    [1093],
    dailyValue: 2300,
    isLimit: true,
  ),
  NutrientDefinition('zinc', 'Zinc', 'mg', NutrientGroup.minerals, [
    1095,
  ], dailyValue: 11),
];

/// The catalogue entry for [code], or null for a code the app no longer
/// tracks.
NutrientDefinition? nutrientDefinition(String code) {
  for (final n in nutrientCatalog) {
    if (n.code == code) return n;
  }
  return null;
}
