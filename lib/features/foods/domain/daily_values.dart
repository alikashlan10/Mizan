import 'package:mizan/core/domain/nutrient_codes.dart';

/// Calories of the reference diet that general daily values are based on.
const referenceDailyKcal = 2000.0;

/// General daily reference amounts (US FDA Daily Values), in each nutrient's
/// own unit, for nutrients that have no personal target. Total sugars have no
/// daily value.
const referenceDailyValues = <String, double>{
  NutrientCodes.fiber: 28,
  NutrientCodes.saturatedFat: 20,
  NutrientCodes.sodium: 2300,
};
