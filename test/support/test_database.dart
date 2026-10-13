import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:mizan/core/database/app_database.dart';

/// An empty in-memory database for a single test.
AppDatabase newTestDatabase() => AppDatabase(
  // Drift otherwise closes query streams on a timer, which widget tests
  // report as still pending once the widget tree is disposed.
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);
