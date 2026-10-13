import 'package:mizan/core/domain/meal.dart';

extension MealLabel on Meal {
  String get label => switch (this) {
    Meal.breakfast => 'Breakfast',
    Meal.lunch => 'Lunch',
    Meal.dinner => 'Dinner',
    Meal.snacks => 'Snacks',
    Meal.other => 'Other',
  };
}
