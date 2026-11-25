import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

/// Flutter Web SQLite WASM connection backed by OPFS / IndexedDB via
/// `web/sqlite3.wasm` and `web/drift_worker.js`.
QueryExecutor openAppDatabaseConnection() {
  return DatabaseConnection.delayed(
    Future<DatabaseConnection>(() async {
      final result = await WasmDatabase.open(
        databaseName: 'checklist_student_local',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );
      if (result.missingFeatures.isNotEmpty) {
        debugPrint(
          'Drift Web DB initialized with ${result.chosenImplementation}; '
          'missing features: ${result.missingFeatures}',
        );
      }
      return DatabaseConnection(result.resolvedExecutor);
    }),
  );
}
