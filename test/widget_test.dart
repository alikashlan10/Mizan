import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/data/database.dart';
import 'package:mizan/main.dart';
import 'package:mizan/providers.dart';

void main() {
  testWidgets('diary opens on today with an empty summary', (tester) async {
    // Drift otherwise closes query streams on a timer, which the test binding
    // reports as still pending once the widget tree is disposed.
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          seedProvider.overrideWith((ref) async {}),
        ],
        child: const MizanApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('0 kcal'), findsWidgets);
    expect(find.text('Breakfast'), findsOneWidget);
    expect(
      find.widgetWithText(FloatingActionButton, 'Add food'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}
