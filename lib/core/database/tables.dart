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
