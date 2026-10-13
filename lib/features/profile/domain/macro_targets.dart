import 'package:mizan/core/domain/macro_energy.dart';

/// How the user's daily macro targets are defined. Stored in the database by
/// name: renaming a value needs a migration.
enum MacroTargetMode {
  /// The app's standard split of the calorie target.
  standard,

  /// The user's own split, as percentages of the calorie target.
  percent,

  /// Fixed amounts in grams, independent of the calorie target.
  grams,
}

/// One number per macronutrient; grams or percentages depending on context.
class MacroValues {
  const MacroValues({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double protein;
  final double carbs;
  final double fat;
}

/// Share of daily calories from each macro when the user sets no targets.
/// Sits inside the commonly advised ranges (protein 10–35%, carbohydrate
/// 45–65%, fat 20–35%).
const standardMacroPercents = MacroValues(protein: 20, carbs: 50, fat: 30);

class MacroSetting {
  const MacroSetting.standard()
    : mode = MacroTargetMode.standard,
      values = null;

  const MacroSetting.percent(MacroValues this.values)
    : mode = MacroTargetMode.percent;

  const MacroSetting.grams(MacroValues this.values)
    : mode = MacroTargetMode.grams;

  final MacroTargetMode mode;

  /// Percentages or grams, matching [mode]; null for the standard split.
  final MacroValues? values;
}

/// Daily macro targets in grams for a calorie target of [targetKcal].
MacroValues macroTargetGrams(
  MacroSetting setting, {
  required double targetKcal,
}) {
  MacroValues fromPercents(MacroValues percents) => MacroValues(
    protein: targetKcal * percents.protein / 100 / kcalPerGramProtein,
    carbs: targetKcal * percents.carbs / 100 / kcalPerGramCarbs,
    fat: targetKcal * percents.fat / 100 / kcalPerGramFat,
  );

  return switch (setting.mode) {
    MacroTargetMode.standard => fromPercents(standardMacroPercents),
    MacroTargetMode.percent => fromPercents(setting.values!),
    MacroTargetMode.grams => setting.values!,
  };
}
