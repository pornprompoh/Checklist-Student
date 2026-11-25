import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/features/sync_queue/domain/entities/sync_entity_type.dart';
import 'package:checklist_student/features/sync_queue/domain/entities/sync_item_status.dart';
import 'package:checklist_student/features/sync_queue/domain/entities/sync_operation_type.dart';
import 'package:checklist_student/features/sync_queue/domain/entities/sync_queue_item.dart';
import 'package:checklist_student/features/sync_queue/domain/services/sync_retry_policy_service.dart';

void main() {
  const service = SyncRetryPolicyService();
  final baseTime = DateTime.utc(2026, 11, 25, 10, 0, 0);

  SyncQueueItem makeItem({
    SyncOperationType operation = SyncOperationType.update,
    SyncItemStatus status = SyncItemStatus.pending,
    int? expectedVersion = 3,
    int retryCount = 0,
    DateTime? nextRetryAt,
    Map<String, dynamic>? payload,
  }) {
    return SyncQueueItem(
      id: 'q-1',
      teacherId: 'teacher-1',
      entityType: SyncEntityType.studentScore,
      entityId: 'score-1',
      displayLabel: 'คะแนน ด.ช.สมชาย — ใบงานที่ 1',
      operation: operation,
      payload: payload ?? const <String, dynamic>{'score': 8.0},
      expectedVersion: expectedVersion,
      status: status,
      retryCount: retryCount,
      nextRetryAt: nextRetryAt,
      lastError: null,
      serverSnapshot: null,
      createdAt: baseTime,
      updatedAt: baseTime,
    );
  }

  group('SyncRetryPolicyService — Backoff & Retry Eligibility', () {
    test('computes exponential backoff schedule (5s, 15s, 45s, 120s, 300s)', () {
      expect(service.computeBackoffDelay(0), const Duration(seconds: 5));
      expect(service.computeBackoffDelay(1), const Duration(seconds: 5));
      expect(service.computeBackoffDelay(2), const Duration(seconds: 15));
      expect(service.computeBackoffDelay(3), const Duration(seconds: 45));
      expect(service.computeBackoffDelay(4), const Duration(seconds: 120));
      expect(service.computeBackoffDelay(5), const Duration(seconds: 300));
      expect(service.computeBackoffDelay(9), const Duration(seconds: 300));
    });

    test('computes nextRetryAt and returns null once maxRetryCount reached', () {
      expect(
        service.computeNextRetryAt(1, now: baseTime),
        baseTime.add(const Duration(seconds: 5)),
      );
      expect(
        service.computeNextRetryAt(4, now: baseTime),
        baseTime.add(const Duration(seconds: 120)),
      );
      expect(
        service.computeNextRetryAt(
          SyncRetryPolicyService.maxRetryCount,
          now: baseTime,
        ),
        isNull,
      );
    });

    test('canRetry respects status, nextRetryAt, and maxRetryCount', () {
      final retryAt = baseTime.add(const Duration(seconds: 15));
      final failedWaiting = makeItem(
        status: SyncItemStatus.failed,
        retryCount: 2,
        nextRetryAt: retryAt,
      );

      expect(service.canRetry(failedWaiting, now: baseTime), isFalse);
      expect(
        service.canRetry(
          failedWaiting,
          now: retryAt.subtract(const Duration(milliseconds: 1)),
        ),
        isFalse,
      );
      expect(service.canRetry(failedWaiting, now: retryAt), isTrue);
      expect(
        service.canRetry(
          failedWaiting,
          now: retryAt.add(const Duration(seconds: 1)),
        ),
        isTrue,
      );

      expect(
        service.canRetry(
          makeItem(
            status: SyncItemStatus.failed,
            retryCount: SyncRetryPolicyService.maxRetryCount,
          ),
          now: baseTime,
        ),
        isFalse,
      );
      expect(
        service.canRetry(
          makeItem(status: SyncItemStatus.syncing),
          now: baseTime,
        ),
        isFalse,
      );
      expect(
        service.canRetry(
          makeItem(status: SyncItemStatus.conflict),
          now: baseTime,
        ),
        isFalse,
      );
    });
  });

  group('SyncRetryPolicyService — Mutation Coalescing', () {
    test('create + update keeps create operation with latest payload and null expectedVersion', () {
      final existing = makeItem(
        operation: SyncOperationType.create,
        expectedVersion: null,
        payload: const <String, dynamic>{'score': 7.5},
      );

      final result = service.coalesce(
        existing: existing,
        incomingOperation: SyncOperationType.update,
        incomingPayload: const <String, dynamic>{'score': 9.25},
        incomingExpectedVersion: 1,
        incomingDisplayLabel: 'คะแนน ด.ช.สมชาย — ใบงานที่ 1 (แก้)',
      );

      expect(result.shouldDropFromQueue, isFalse);
      expect(result.operation, SyncOperationType.create);
      expect(result.payload['score'], 9.25);
      expect(result.expectedVersion, isNull);
    });

    test('create + delete drops item from queue completely', () {
      final existing = makeItem(
        operation: SyncOperationType.create,
        expectedVersion: null,
      );

      final result = service.coalesce(
        existing: existing,
        incomingOperation: SyncOperationType.delete,
        incomingPayload: const <String, dynamic>{},
        incomingExpectedVersion: null,
        incomingDisplayLabel: existing.displayLabel,
      );

      expect(result.shouldDropFromQueue, isTrue);
    });

    test('update + update preserves ORIGINAL expectedVersion before first offline edit', () {
      final existing = makeItem(
        operation: SyncOperationType.update,
        expectedVersion: 2,
        payload: const <String, dynamic>{'score': 8.0},
      );

      final result = service.coalesce(
        existing: existing,
        incomingOperation: SyncOperationType.update,
        incomingPayload: const <String, dynamic>{'score': 9.5},
        incomingExpectedVersion: 3,
        incomingDisplayLabel: 'คะแนน ด.ช.สมชาย — ใบงานที่ 1',
      );

      expect(result.shouldDropFromQueue, isFalse);
      expect(result.operation, SyncOperationType.update);
      expect(result.payload['score'], 9.5);
      expect(result.expectedVersion, 2);
    });

    test('update + delete turns into delete while preserving original expectedVersion', () {
      final existing = makeItem(
        operation: SyncOperationType.update,
        expectedVersion: 4,
      );

      final result = service.coalesce(
        existing: existing,
        incomingOperation: SyncOperationType.delete,
        incomingPayload: const <String, dynamic>{'id': 'score-1'},
        incomingExpectedVersion: 5,
        incomingDisplayLabel: 'ลบคะแนน ด.ช.สมชาย',
      );

      expect(result.shouldDropFromQueue, isFalse);
      expect(result.operation, SyncOperationType.delete);
      expect(result.expectedVersion, 4);
    });
  });
}
