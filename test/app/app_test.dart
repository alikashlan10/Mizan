import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/app/app.dart';
import 'package:mizan/core/database/database_provider.dart';
import 'package:mizan/core/theme/app_colors.dart';
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
    expect(find.text('Intake'), findsOneWidget);
    expect(find.text('Expenditure'), findsOneWidget);
    expect(find.text('Remaining'), findsOneWidget);
    // No profile yet, so the card asks for one and the bars have no targets.
    expect(find.textContaining('Fill in your profile'), findsOneWidget);
    for (final macro in ['Protein', 'Carbs', 'Fat']) {
      expect(find.text(macro), findsOneWidget);
    }
    expect(find.text('0 g'), findsNWidgets(3));
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.byTooltip('Add food to breakfast'), findsOneWidget);
    expect(find.widgetWithText(NavigationBar, 'Profile'), findsOneWidget);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    final theme = Theme.of(tester.element(find.byType(Scaffold).first));
    expect(
      scaffold.backgroundColor ?? theme.scaffoldBackgroundColor,
      AppColors.background,
    );

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}
