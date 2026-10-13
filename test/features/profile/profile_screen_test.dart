import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/core/database/database_provider.dart';
import 'package:mizan/features/profile/data/profile_repository.dart';
import 'package:mizan/features/profile/presentation/profile_screen.dart';

import '../../support/test_database.dart';

void main() {
  testWidgets('calculates the target while typing and saves the profile', (
    tester,
  ) async {
    final db = newTestDatabase();
    // Database work runs on real timers, outside the test's fake clock.
    Future<void> settleDatabase() async {
      await tester.runAsync(() => Future<void>.delayed(Durations.short2));
      await tester.pump();
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await settleDatabase();

    expect(find.textContaining('Enter your details'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Age'), '30');
    await tester.enterText(find.widgetWithText(TextFormField, 'Height'), '180');
    await tester.enterText(find.widgetWithText(TextFormField, 'Weight'), '80');
    await tester.pump();

    // Male, sedentary, maintain: resting 1780, maintenance 1780 × 1.2.
    expect(find.text('1780 kcal'), findsOneWidget);
    expect(find.text('2136 kcal'), findsNWidgets(2));

    await tester.scrollUntilVisible(
      find.text('Save'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save'));
    await settleDatabase();

    final saved = await tester.runAsync(
      () => ProfileRepository(db).watchProfile().first,
    );
    expect(saved!.weightKg, 80);
    expect(find.text('Profile saved'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}
