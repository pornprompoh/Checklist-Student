import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  final now = DateTime.utc(2026, 11, 25, 8, 30);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedAllTablesForTeacher(String teacherId, String suffix) async {
    await db.into(db.localEntityCaches).insert(
      LocalEntityCachesCompanion.insert(
        cacheKey: 'dashboard_$suffix',
        teacherId: teacherId,
        entityGroup: 'dashboard',
        payloadJson: '{"teacher":"$teacherId"}',
        updatedAt: now,
      ),
    );
    await db.into(db.localAttendanceSessions).insert(
      LocalAttendanceSessionsCompanion.insert(
        id: 'sess-$suffix',
        teacherId: teacherId,
        subjectClassId: 'class-$suffix',
        sessionDateIso: '2026-11-25',
        isLocked: const Value(true),
        note: const Value('คาบเช้า'),
        version: const Value(1),
        isDirty: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.into(db.localAttendanceRecords).insert(
      LocalAttendanceRecordsCompanion.insert(
        id: 'rec-$suffix',
        teacherId: teacherId,
        sessionId: 'sess-$suffix',
        enrollmentId: 'enroll-$suffix',
        status: 'present',
        note: const Value('มาตรงเวลา'),
        version: const Value(1),
        isDirty: const Value(true),
        updatedAt: now,
      ),
    );
    await db.into(db.localStudentScores).insert(
      LocalStudentScoresCompanion.insert(
        id: 'score-$suffix',
        teacherId: teacherId,
        assignmentId: 'assign-$suffix',
        enrollmentId: 'enroll-$suffix',
        subjectClassId: 'class-$suffix',
        submissionStatus: const Value('submitted'),
        score: const Value(9.75),
        note: const Value('งานเรียบร้อย'),
        version: const Value(2),
        isDirty: const Value(true),
        updatedAt: now,
      ),
    );
    await db.into(db.localSyncQueue).insert(
      LocalSyncQueueCompanion.insert(
        id: 'queue-$suffix',
        teacherId: teacherId,
        entityType: 'student_score',
        entityId: 'score-$suffix',
        displayLabel: 'คะแนน ด.ช.สมชาย — ใบงานที่ 1',
        operation: 'update',
        payloadJson: '{"score":9.75}',
        expectedVersion: const Value(2),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  group('AppDatabase (Drift In-Memory SQLite)', () {
    test('supports insert, read, and update across all 5 local tables', () async {
      await seedAllTablesForTeacher('teacher-A', 'a1');

      final caches = await db.select(db.localEntityCaches).get();
      expect(caches, hasLength(1));
      expect(caches.first.cacheKey, 'dashboard_a1');

      final sessions = await db.select(db.localAttendanceSessions).get();
      expect(sessions, hasLength(1));
      expect(sessions.first.isLocked, isTrue);

      final records = await db.select(db.localAttendanceRecords).get();
      expect(records, hasLength(1));
      expect(records.first.status, 'present');

      final scores = await db.select(db.localStudentScores).get();
      expect(scores, hasLength(1));
      expect(scores.first.score, 9.75);
      expect(scores.first.version, 2);

      // Update exact decimal score & version in local_student_scores
      await (db.update(db.localStudentScores)
            ..where((t) => t.id.equals('score-a1')))
          .write(
            const LocalStudentScoresCompanion(
              score: Value(9.99),
              version: Value(3),
              isDirty: Value(false),
            ),
          );
      final updatedScore = await (db.select(
        db.localStudentScores,
      )..where((t) => t.id.equals('score-a1'))).getSingle();
      expect(updatedScore.score, 9.99);
      expect(updatedScore.version, 3);
      expect(updatedScore.isDirty, isFalse);

      final queueRows = await db.select(db.localSyncQueue).get();
      expect(queueRows, hasLength(1));
      expect(queueRows.first.status, 'pending');
      expect(queueRows.first.retryCount, 0);
    });

    test(
      'Multi-Tenant Isolation: clearAllDataForTeacher wipes teacher-A only and preserves teacher-B 100%',
      () async {
        await seedAllTablesForTeacher('teacher-A', 'a1');
        await seedAllTablesForTeacher('teacher-B', 'b1');

        await db.clearAllDataForTeacher('teacher-A');

        final caches = await db.select(db.localEntityCaches).get();
        final sessions = await db.select(db.localAttendanceSessions).get();
        final records = await db.select(db.localAttendanceRecords).get();
        final scores = await db.select(db.localStudentScores).get();
        final queues = await db.select(db.localSyncQueue).get();

        expect(caches.map((r) => r.teacherId), <String>['teacher-B']);
        expect(sessions.map((r) => r.teacherId), <String>['teacher-B']);
        expect(records.map((r) => r.teacherId), <String>['teacher-B']);
        expect(scores.map((r) => r.teacherId), <String>['teacher-B']);
        expect(queues.map((r) => r.teacherId), <String>['teacher-B']);

        await db.clearAllTables();
        expect(await db.select(db.localEntityCaches).get(), isEmpty);
        expect(await db.select(db.localAttendanceSessions).get(), isEmpty);
        expect(await db.select(db.localAttendanceRecords).get(), isEmpty);
        expect(await db.select(db.localStudentScores).get(), isEmpty);
        expect(await db.select(db.localSyncQueue).get(), isEmpty);
      },
    );
  });
}
