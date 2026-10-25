import 'package:drift/drift.dart';
import 'package:mizan/core/domain/meal.dart';

class Nutrients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  TextColumn get unit => text()();

  /// USDA FoodData Central nutrient id, used to map imported datasets.
  IntColumn get fdcId => integer().nullable()();
  IntColumn get sortOrder => integer()();
}

class Foods extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  /// Dataset the food came from; see `FoodSources`.
  TextColumn get source => text()();
  TextColumn get sourceId => text().nullable()();

  /// The dataset's own grouping, such as "Poultry Products"; null for foods
  /// the user created.
  TextColumn get category => text().nullable()();

  /// Set when the user deletes the food. The row stays so that diary entries
  /// and meals using it keep working; it is only hidden from search.
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// One ingredient of a meal. Both sides are foods: the meal itself and the
/// food that goes into it.
class RecipeIngredients extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recipeId =>
      integer().references(Foods, #id, onDelete: KeyAction.cascade)();
  IntColumn get ingredientId => integer().references(Foods, #id)();
  RealColumn get grams => real()();
  IntColumn get sortOrder => integer()();
}

/// Nutrient amounts are stored per 100 g of food, in the nutrient's unit.
class FoodNutrients extends Table {
  IntColumn get foodId =>
      integer().references(Foods, #id, onDelete: KeyAction.cascade)();
  IntColumn get nutrientId => integer().references(Nutrients, #id)();
  RealColumn get amount => real()();

  @override
  Set<Column> get primaryKey => {foodId, nutrientId};
}

/// A named amount of a food, such as "1 cup, chopped" weighing 140 g.
@DataClassName('FoodServingRow')
class FoodServings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get foodId =>
      integer().references(Foods, #id, onDelete: KeyAction.cascade)();
  TextColumn get label => text()();
  RealColumn get grams => real()();
  IntColumn get sortOrder => integer()();
}

/// The single user's details. Enum-like columns hold the enum value's name.
class UserProfiles extends Table {
  IntColumn get id => integer()();
  TextColumn get sex => text()();
  IntColumn get age => integer()();
  RealColumn get heightCm => real()();
  RealColumn get weightKg => real()();
  TextColumn get activity => text()();
  TextColumn get goal => text()();
  RealColumn get customTargetKcal => real().nullable()();

  /// Name of the macro target mode; the three values below are percentages
  /// or grams to match, and null for the standard split.
  TextColumn get macroMode => text().withDefault(const Constant('standard'))();
  RealColumn get macroProtein => real().nullable()();
  RealColumn get macroCarbs => real().nullable()();
  RealColumn get macroFat => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WaterEntryRow')
class WaterEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Local calendar day; see `dayKey`.
  TextColumn get day => text()();
  RealColumn get ml => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ExerciseEntryRow')
class ExerciseEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Local calendar day; see `dayKey`.
  TextColumn get day => text()();

  /// Name of the exercise type.
  TextColumn get type => text()();
  RealColumn get minutes => real()();

  /// Calories burned, fixed when the entry was logged.
  RealColumn get kcal => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@TableIndex(name: 'diary_entries_day', columns: {#day})
class DiaryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Local calendar day; see `dayKey`.
  TextColumn get day => text()();
  IntColumn get meal => intEnum<Meal>()();
  IntColumn get foodId => integer().references(Foods, #id)();
  RealColumn get grams => real()();

  /// How the amount was entered when it was a serving, such as 2 of
  /// "1 tbsp"; both null when it was entered in grams.
  RealColumn get servingQuantity => real().nullable()();
  TextColumn get servingLabel => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Which version of each bundled dataset is in the database, so that an app
/// update shipping richer data can bring existing foods up to date.
class DatasetImports extends Table {
  TextColumn get source => text()();
  IntColumn get version => integer()();

  @override
  Set<Column> get primaryKey => {source};
}
