import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/features/foods/data/food_seed.dart';

void main() {
  test('reads columns by the header and leaves out blank amounts', () {
    final foods = parseSeedTsv(
      'fdc_id\tname\tcategory\tenergy\tfat\tfiber\tsodium\tretired_code\n'
      '1\tOil, olive\tFats and Oils\t884\t100\t0\t2\t5\n'
      '2\tCoating mix\t\t377\t3.7\t\t2182\n',
    );

    expect(foods.map((f) => f.name), ['Oil, olive', 'Coating mix']);
    expect(foods.first.sourceId, '1');
    expect(foods.first.category, 'Fats and Oils');
    expect(foods.first.amounts, {
      NutrientCodes.energy: 884,
      NutrientCodes.fat: 100,
      NutrientCodes.fiber: 0,
      NutrientCodes.sodium: 2,
    });
    expect(foods.last.category, isNull);
    expect(foods.last.amounts[NutrientCodes.sodium], 2182);
    expect(foods.last.amounts.containsKey(NutrientCodes.fiber), isFalse);
  });

  test('parses serving rows', () {
    final servings = parseServingsTsv('10\t2\t1 large\t50\n10\t1\tbad\t0\n');

    expect(servings.single.label, '1 large');
    expect(servings.single.sortOrder, 2);
    expect(servings.single.grams, 50);
  });
}
