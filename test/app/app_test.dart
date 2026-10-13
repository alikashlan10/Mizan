import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/app/app.dart';
import 'package:mizan/core/database/database_provider.dart';
import 'package:mizan/features/foods/presentation/food_providers.dart';

import '../support/test_database.dart';

void main() {
  testWidgets('opens on today\'s diary with the navigation bar', (
    tester,
  ) async {
    final db = newTestDatabase();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          foodSeedProvider.overrideWith((ref) async {}),
        ],
        child: const MizanApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('0 kcal'), findsWidgets);
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.widgetWithText(NavigationBar, 'Profile'), findsOneWidget);
    expect(
      find.widgetWithText(FloatingActionButton, 'Add food'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}
