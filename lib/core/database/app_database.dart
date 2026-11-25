import 'package:drift/drift.dart';

import 'database_connection.dart';
import 'tables/local_attendance_tables.dart';
import 'tables/local_entity_caches_table.dart';
import 'tables/local_grading_tables.dart';
import 'tables/local_sync_queue_table.dart';

part 'app_database.g.dart';

/// Root Drift local database for Offline-First caching and write queueing.
///
/// Multi-tenant safe: every table includes `teacherId`, and
/// [clearAllDataForTeacher] wipes a single teacher's local state cleanly when
/// switching accounts on shared school computers.
@DriftDatabase(
  tables: <Type>[
    LocalEntityCaches,
    LocalAttendanceSessions,
    LocalAttendanceRecords,
    LocalStudentScores,
    LocalSyncQueue,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? openAppDatabaseConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  /// Deletes all locally cached rows and queued mutations belonging to
  /// [teacherId] across all 5 tables without affecting any other teacher.
  Future<void> clearAllDataForTeacher(String teacherId) async {
    await transaction(() async {
      await (delete(
        localEntityCaches,
      )..where((t) => t.teacherId.equals(teacherId))).go();
      await (delete(
        localAttendanceSessions,
      )..where((t) => t.teacherId.equals(teacherId))).go();
      await (delete(
        localAttendanceRecords,
      )..where((t) => t.teacherId.equals(teacherId))).go();
      await (delete(
        localStudentScores,
      )..where((t) => t.teacherId.equals(teacherId))).go();
      await (delete(
        localSyncQueue,
      )..where((t) => t.teacherId.equals(teacherId))).go();
    });
  }

  /// Wipes every local table in a single transaction (e.g., full reset).
  Future<void> clearAllTables() async {
    await transaction(() async {
      await delete(localEntityCaches).go();
      await delete(localAttendanceSessions).go();
      await delete(localAttendanceRecords).go();
      await delete(localStudentScores).go();
      await delete(localSyncQueue).go();
    });
  }
}
