import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// Non-web / Dart VM fallback connection used by unit/widget tests and desktop runs.
///
/// Enables [closeStreamsSynchronously] so Drift stream subscriptions close
/// cleanly inside Flutter widget test teardown without leaving pending timers.
QueryExecutor openAppDatabaseConnection() {
  return DatabaseConnection(
    NativeDatabase.memory(),
    closeStreamsSynchronously: true,
  );
}
