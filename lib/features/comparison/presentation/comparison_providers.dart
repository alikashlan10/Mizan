import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mizan/core/database/app_database.dart';

/// The most foods that can be compared at once; more would not fit a phone.
const maxComparedFoods = 4;

/// The foods currently being compared, in the order they were added.
class ComparedFoods extends Notifier<List<Food>> {
  @override
  List<Food> build() => const [];

  bool get isFull => state.length >= maxComparedFoods;

  /// Adds [food] unless it is already there or the comparison is full.
  void add(Food food) {
    if (isFull || state.any((f) => f.id == food.id)) return;
    state = [...state, food];
  }

  void remove(Food food) => state = [
    for (final f in state)
      if (f.id != food.id) f,
  ];
}

final comparedFoodsProvider = NotifierProvider<ComparedFoods, List<Food>>(
  ComparedFoods.new,
);
