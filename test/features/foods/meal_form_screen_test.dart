import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/core/database/database_provider.dart';
import 'package:mizan/core/domain/nutrient_codes.dart';
import 'package:mizan/core/theme/app_theme.dart';
import 'package:mizan/features/foods/data/food_repository.dart';
import 'package:mizan/features/foods/domain/food_sources.dart';
import 'package:mizan/features/foods/presentation/food_providers.dart';
import 'package:mizan/features/foods/presentation/meal_form_screen.dart';

import '../../support/test_database.dart';

void main() {
  testWidgets('builds a meal from a picked ingredient and saves it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = newTestDatabase();
    final foods = FoodRepository(db);
    // Database work runs on real timers, outside the test's fake clock.
    Future<void> settleDatabase() async {
      await tester.runAsync(() => Future<void>.delayed(Durations.short2));
      await tester.pumpAndSettle();
    }

    await tester.runAsync(() async {
      final ids = {for (final n in await foods.allNutrients()) n.code: n.id};
      await foods.createCustomFood('Honey', {ids[NutrientCodes.energy]!: 300});
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          foodSeedProvider.overrideWith((ref) async {}),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const MealFormScreen(),
        ),
      ),
    );
    await settleDatabase();

    // Nothing to save until the meal has a name and an ingredient.
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Save'))
          .enabled,
      isFalse,
    );

    await tester.enterText(find.byType(TextField), 'Honey toast');
    await tester.tap(find.text('Add ingredient'));
    await settleDatabase();
    await settleDatabase();

    await tester.tap(find.text('Honey'));
    await settleDatabase();

    // The amount dialog is only as tall as its content.
    final surface = tester.getSize(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(surface.height, lessThan(400));

    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '50',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await settleDatabase();
    await settleDatabase();

    expect(find.text('Create meal'), findsOneWidget);
    expect(find.text('Honey'), findsOneWidget);
    expect(find.text('50.0 g · 150 kcal'), findsOneWidget);
    expect(find.text('150 kcal · 50.0 g'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await settleDatabase();

    final meal = await tester.runAsync(
      () async =>
          (await foods.watchSearch('toast', source: FoodSources.meal).first)
              .single,
    );
    final ingredients = await tester.runAsync(
      () => foods.mealIngredients(meal!.id),
    );
    expect(ingredients!.single.grams, 50);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}
