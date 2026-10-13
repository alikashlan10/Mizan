import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/features/foods/data/food_seed.dart';

void main() {
  test('parses seed rows and leaves out blank amounts', () {
    final foods = parseSeedTsv(
      '1\tOil, olive\t884\t0\t0\t100\t0\t0\t13.8\t2\n'
      '2\tCoating mix\t377\t6.1\t79.8\t3.7\t\t\t\t2182\n',
    );

    expect(foods.map((f) => f.name), ['Oil, olive', 'Coating mix']);
    expect(foods.first.sourceId, '1');
    expect(foods.first.amounts[NutrientCodes.fat], 100);
    expect(foods.last.amounts[NutrientCodes.sodium], 2182);
    expect(foods.last.amounts.containsKey(NutrientCodes.fiber), isFalse);
  });
}
