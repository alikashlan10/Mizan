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
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
