import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/core/database/database_provider.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/core/theme/app_theme.dart';
import 'package:mizan/features/foods/data/food_repository.dart';
import 'package:mizan/features/foods/domain/food_serving.dart';
import 'package:mizan/features/foods/domain/food_sources.dart';
import 'package:mizan/features/foods/domain/seed_food.dart';
import 'package:mizan/features/foods/presentation/food_detail_screen.dart';
import 'package:mizan/features/foods/presentation/food_providers.dart';

import '../../support/test_database.dart';

void main() {
  testWidgets('shows facts for the chosen serving and reports the amount', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = newTestDatabase();
    final foods = FoodRepository(db);
    // Database work runs on real timers, outside the test's fake clock.
    Future<void> settleDatabase() async {
      await tester.runAsync(() => Future<void>.delayed(Durations.short2));
      await tester.pump();
    }

    final egg = await tester.runAsync(() async {
      await foods.importFoods(FoodSources.usda, const [
        SeedFood(
          sourceId: '10',
          name: 'Egg, whole, raw',
          amounts: {
            NutrientCodes.energy: 140,
            NutrientCodes.protein: 12,
            NutrientCodes.fat: 10,
            NutrientCodes.sodium: 140,
          },
        ),
      ]);
      await foods.importServings(FoodSources.usda, const [
        SeedServing(
          foodSourceId: '10',
          sortOrder: 1,
          label: '1 large',
          grams: 50,
        ),
      ]);
      return (await foods.watchSearch('egg').first).single;
    });

    FoodAmount? added;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          foodSeedProvider.overrideWith((ref) async {}),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: FoodDetailScreen(
            food: egg!,
            onAddToDiary: (_, amount) async => added = amount,
          ),
        ),
      ),
    );
    await settleDatabase();
    // The servings load after the seed provider has reported in.
    await settleDatabase();

    // 100 g against the 2,000 kcal reference diet.
    expect(find.text('140'), findsOneWidget);
    expect(find.text('7% of daily'), findsOneWidget);
    expect(find.text('12.0 g'), findsOneWidget);
    expect(find.text('140 mg'), findsOneWidget);
    // Carbohydrates, fiber, sugars and saturated fat are not recorded.
    expect(find.text('—'), findsNWidgets(4));

    await tester.tap(find.text('grams'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 large (50.0 g)').last);
    await tester.pumpAndSettle();

    expect(find.text('= 50.0 g'), findsOneWidget);
    expect(find.text('70'), findsOneWidget);
    expect(find.text('6.0 g'), findsOneWidget);

    await tester.tap(find.text('Add to diary'));
    expect(added!.grams, 50);
    expect(added!.serving!.label, '1 large');

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}
