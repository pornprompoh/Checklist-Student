import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/features/sync_queue/domain/entities/sync_entity_type.dart';
import 'package:checklist_student/features/sync_queue/domain/entities/sync_item_status.dart';
import 'package:checklist_student/features/sync_queue/domain/entities/sync_operation_type.dart';
import 'package:checklist_student/features/sync_queue/domain/entities/sync_queue_item.dart';
import 'package:checklist_student/features/sync_queue/domain/services/sync_conflict_field_formatter.dart';

void main() {
  const formatter = SyncConflictFieldFormatter();
  final now = DateTime.utc(2026, 11, 25, 8, 30);

  SyncQueueItem makeConflict({
    required SyncEntityType entityType,
    required Map<String, dynamic> payload,
    required Map<String, dynamic> serverSnapshot,
    int? expectedVersion = 1,
  }) {
    return SyncQueueItem(
      id: 'q-1',
      teacherId: 'teacher-1',
      entityType: entityType,
      entityId: 'ent-1',
      displayLabel: 'ทดสอบความขัดแย้ง',
      operation: SyncOperationType.update,
      payload: payload,
      expectedVersion: expectedVersion,
      status: SyncItemStatus.conflict,
      retryCount: 0,
      nextRetryAt: null,
      lastError: 'ข้อมูลชนกัน',
      serverSnapshot: serverSnapshot,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('SyncConflictFieldFormatter', () {
    test('formats studentScore with exact decimals (79.99 vs 80, no rounding) and flags only changed fields', () {
      final item = makeConflict(
        entityType: SyncEntityType.studentScore,
        payload: const <String, dynamic>{
          'submission_status': 'submitted',
          'score': 79.99,
          'note': 'ส่งครบ',
        },
        serverSnapshot: <String, dynamic>{
          'submission_status': 'submitted',
          'score': 80.0,
          'note': 'ส่งครบ',
          'version': 3,
          'updated_at': '2026-11-25T09:00:00Z',
        },
      );

      final diffs = formatter.formatDiffs(item);
      final byLabel = <String, SyncConflictFieldDiff>{
        for (final d in diffs) d.label: d,
      };

      expect(byLabel['สถานะการส่งงาน']!.localValue, 'ส่งแล้ว');
      expect(byLabel['สถานะการส่งงาน']!.serverValue, 'ส่งแล้ว');
      expect(byLabel['สถานะการส่งงาน']!.isDifferent, isFalse);

      expect(byLabel['คะแนน']!.localValue, '79.99');
      expect(byLabel['คะแนน']!.serverValue, '80');
      expect(byLabel['คะแนน']!.isDifferent, isTrue);

      expect(byLabel['หมายเหตุ']!.isDifferent, isFalse);
      expect(byLabel['เวอร์ชันข้อมูล']!.localValue, 'v1');
      expect(byLabel['เวอร์ชันข้อมูล']!.serverValue, 'v3');
      expect(byLabel['เวอร์ชันข้อมูล']!.isDifferent, isTrue);
      expect(byLabel['เวลาอัปเดตล่าสุดบนเซิร์ฟเวอร์']!.serverValue, contains('2569'));
    });

    test('formats attendanceSession fields in Buddhist Era', () {
      final item = makeConflict(
        entityType: SyncEntityType.attendanceSession,
        payload: const <String, dynamic>{
          'session_date': '2026-11-25',
          'is_locked': true,
          'note': 'สอนคาบเช้า',
        },
        serverSnapshot: const <String, dynamic>{
          'session_date': '2026-11-25',
          'is_locked': false,
          'note': 'สอนคาบบ่าย',
          'version': 2,
        },
      );

      final diffs = formatter.formatDiffs(item);
      final byLabel = <String, SyncConflictFieldDiff>{
        for (final d in diffs) d.label: d,
      };
      expect(byLabel['วันที่คาบเรียน']!.localValue, '25 พ.ย. 2569');
      expect(byLabel['วันที่คาบเรียน']!.isDifferent, isFalse);
      expect(byLabel['สถานะการล็อกคาบ']!.localValue, 'ล็อกกันแก้ไข');
      expect(byLabel['สถานะการล็อกคาบ']!.serverValue, 'เปิดแก้ไข');
      expect(byLabel['สถานะการล็อกคาบ']!.isDifferent, isTrue);
      expect(byLabel['หมายเหตุคาบ']!.isDifferent, isTrue);
    });

    test('formats attendanceRecord 4 Thai statuses accurately', () {
      final item = makeConflict(
        entityType: SyncEntityType.attendanceRecord,
        payload: const <String, dynamic>{'status': 'late', 'note': 'มาสาย 5 นาที'},
        serverSnapshot: const <String, dynamic>{
          'status': 'absent',
          'note': '',
          'version': 2,
        },
      );

      final diffs = formatter.formatDiffs(item);
      final byLabel = <String, SyncConflictFieldDiff>{
        for (final d in diffs) d.label: d,
      };
      expect(byLabel['สถานะเข้าเรียน']!.localValue, 'สาย');
      expect(byLabel['สถานะเข้าเรียน']!.serverValue, 'ขาด');
      expect(byLabel['สถานะเข้าเรียน']!.isDifferent, isTrue);
      expect(byLabel['หมายเหตุรายบุคคล']!.serverValue, '-');
    });

    test('formats specialGradeStatus ร / มส / ปกติ and resolved flags', () {
      final item = makeConflict(
        entityType: SyncEntityType.specialGradeStatus,
        payload: const <String, dynamic>{
          'special_grade_override': null,
          'mark_r_resolved': true,
          'mark_ms_resolved': false,
        },
        serverSnapshot: const <String, dynamic>{
          'special_grade_override': 'ร',
          'was_r_resolved': false,
          'was_ms_resolved': false,
          'version': 4,
        },
      );

      final diffs = formatter.formatDiffs(item);
      final byLabel = <String, SyncConflictFieldDiff>{
        for (final d in diffs) d.label: d,
      };
      expect(byLabel['สถานะเกรดพิเศษ']!.localValue, 'ปกติ');
      expect(byLabel['สถานะเกรดพิเศษ']!.serverValue, 'ร');
      expect(byLabel['สถานะเกรดพิเศษ']!.isDifferent, isTrue);
      expect(byLabel['บันทึกแก้ ร แล้ว']!.localValue, 'ใช่');
      expect(byLabel['บันทึกแก้ ร แล้ว']!.serverValue, 'ไม่ใช่');
      expect(byLabel['บันทึกแก้ ร แล้ว']!.isDifferent, isTrue);
      expect(byLabel['บันทึกแก้ มส แล้ว']!.isDifferent, isFalse);
    });
  });
}
