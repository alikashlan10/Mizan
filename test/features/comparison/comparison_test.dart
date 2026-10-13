import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/core/database/database_provider.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/core/theme/app_theme.dart';
import 'package:mizan/features/comparison/domain/comparison.dart';
import 'package:mizan/features/comparison/presentation/comparison_providers.dart';
import 'package:mizan/features/comparison/presentation/comparison_screen.dart';
import 'package:mizan/features/foods/data/food_repository.dart';
import 'package:mizan/features/foods/presentation/food_providers.dart';

import '../../support/test_database.dart';

void main() {
  const rice = {NutrientCodes.energy: 130.0, NutrientCodes.carbs: 28.0};
  const pasta = {NutrientCodes.energy: 158.0, NutrientCodes.carbs: 31.0};
  const oil = {NutrientCodes.energy: 884.0, NutrientCodes.carbs: 0.0};

  test('matching by weight takes the same grams of every food', () {
    expect(gramsFor(rice, const MatchByWeight(150)), 150);
    expect(gramsFor(oil, const MatchByWeight(150)), 150);
  });

  test('matching by nutrient finds the grams that supply it', () {
    const tenCarbs = MatchByNutrient(code: NutrientCodes.carbs, amount: 10);
    // 10 g of carbohydrate ÷ 28 g per 100 g.
    expect(gramsFor(rice, tenCarbs), closeTo(35.714, 1e-3));
    expect(gramsFor(pasta, tenCarbs), closeTo(32.258, 1e-3));
  });

  test('a food with none of the matched nutrient has no weight', () {
    const tenCarbs = MatchByNutrient(code: NutrientCodes.carbs, amount: 10);
    expect(gramsFor(oil, tenCarbs), isNull);
    expect(gramsFor(const {}, tenCarbs), isNull);
  });

  test('a compared food reports each nutrient for its weight', () {
    final grams = gramsFor(
      rice,
      const MatchByNutrient(code: NutrientCodes.carbs, amount: 10),
    );
    final food = ComparedFood(grams: grams, per100g: rice);

    expect(food.amountOf(NutrientCodes.carbs), closeTo(10, 1e-9));
    expect(food.amountOf(NutrientCodes.energy), closeTo(46.43, 1e-2));
    expect(food.amountOf(NutrientCodes.protein), isNull);
    expect(
      const ComparedFood(
        grams: null,
        per100g: oil,
      ).amountOf(NutrientCodes.energy),
      isNull,
    );
  });

  test('the compared list ignores duplicates and stops when full', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final foods = FoodRepository(db);
    for (var i = 0; i < maxComparedFoods + 1; i++) {
      await foods.createCustomFood('Food $i', {});
    }
    final all = await foods.watchSearch('food').first;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final compared = container.read(comparedFoodsProvider.notifier);

    compared
      ..add(all[0])
      ..add(all[0]);
    expect(container.read(comparedFoodsProvider), hasLength(1));

    all.forEach(compared.add);
    expect(container.read(comparedFoodsProvider), hasLength(maxComparedFoods));

    compared.remove(all[0]);
    expect(
      container.read(comparedFoodsProvider).map((f) => f.id),
      isNot(contains(all[0].id)),
    );
  });

  testWidgets('shows two foods at the same weight, then at the same carbs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = newTestDatabase();
    final foods = FoodRepository(db);
    // Database work runs on real timers, outside the test's fake clock.
    Future<void> settleDatabase() async {
      await tester.runAsync(() => Future<void>.delayed(Durations.short2));
      await tester.pumpAndSettle();
    }

    final created = await tester.runAsync(() async {
      final ids = {for (final n in await foods.allNutrients()) n.code: n.id};
      await foods.createCustomFood('Rice', {
        for (final e in rice.entries) ids[e.key]!: e.value,
      });
      await foods.createCustomFood('Pasta', {
        for (final e in pasta.entries) ids[e.key]!: e.value,
      });
      return foods.watchSearch('').first;
    });
    final byName = {for (final f in created!) f.name: f};

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        foodSeedProvider.overrideWith((ref) async {}),
      ],
    );
    addTearDown(container.dispose);
    container.read(comparedFoodsProvider.notifier)
      ..add(byName['Rice']!)
      ..add(byName['Pasta']!);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const ComparisonScreen(),
        ),
      ),
    );
    await settleDatabase();
    await settleDatabase();

    // 100 g of each.
    expect(find.text('100 g'), findsNWidgets(2));
    expect(find.text('130 kcal'), findsOneWidget);
    expect(find.text('158 kcal'), findsOneWidget);
    expect(find.text('28.0 g'), findsOneWidget);

    await tester.tap(find.text('Same nutrient'));
    await settleDatabase();

    // 10 g of carbohydrate from each.
    expect(find.text('35.7 g'), findsOneWidget);
    expect(find.text('32.3 g'), findsOneWidget);
    expect(find.text('10.0 g'), findsNWidgets(2));
    expect(find.text('46 kcal'), findsOneWidget);
    expect(find.text('51 kcal'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}
