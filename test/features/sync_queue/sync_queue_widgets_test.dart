import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/core/network/connectivity_provider.dart';
import 'package:checklist_student/core/theme/app_color_scheme.dart';
import 'package:checklist_student/core/theme/app_theme.dart';
import 'package:checklist_student/features/auth/domain/entities/auth_state.dart';
import 'package:checklist_student/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:checklist_student/features/sync_queue/domain/entities/sync_entity_type.dart';
import 'package:checklist_student/features/sync_queue/domain/entities/sync_item_status.dart';
import 'package:checklist_student/features/sync_queue/domain/entities/sync_operation_type.dart';
import 'package:checklist_student/features/sync_queue/domain/entities/sync_queue_item.dart';
import 'package:checklist_student/features/sync_queue/domain/entities/sync_run_summary.dart';
import 'package:checklist_student/features/sync_queue/domain/repositories/sync_queue_repository.dart';
import 'package:checklist_student/features/sync_queue/domain/repositories/sync_remote_executor.dart';
import 'package:checklist_student/features/sync_queue/domain/services/sync_engine_service.dart';
import 'package:checklist_student/features/sync_queue/presentation/pages/sync_queue_page.dart';
import 'package:checklist_student/features/sync_queue/presentation/providers/sync_queue_providers.dart';
import 'package:checklist_student/features/sync_queue/presentation/widgets/sync_conflict_resolution_dialog.dart';
import 'package:checklist_student/features/sync_queue/presentation/widgets/sync_status_badge.dart';

class _FakeAuthNotifier extends AuthStateNotifier {
  @override
  AuthSessionState build() =>
      const AuthSessionState.authenticated(userId: 'teacher-1');
}

class _SpySyncEngine extends SyncEngineService {
  _SpySyncEngine()
    : super(
        queueRepository: _NoopQueueRepo(),
        remoteExecutor: _NoopRemoteExecutor(),
      );

  int syncCalls = 0;

  @override
  Future<SyncRunSummary> syncPendingItems({
    required String teacherId,
    DateTime? now,
  }) async {
    syncCalls++;
    return const SyncRunSummary(
      syncedCount: 1,
      conflictCount: 0,
      failedCount: 0,
      remainingPendingCount: 0,
    );
  }
}

class _NoopQueueRepo implements SyncQueueRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopRemoteExecutor implements SyncRemoteExecutor {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final now = DateTime.utc(2026, 11, 25, 10, 0);

  SyncQueueItem makeItem({
    required String id,
    required SyncItemStatus status,
    required String label,
    Map<String, dynamic>? payload,
    Map<String, dynamic>? serverSnapshot,
  }) {
    return SyncQueueItem(
      id: id,
      teacherId: 'teacher-1',
      entityType: SyncEntityType.studentScore,
      entityId: 'sc-$id',
      displayLabel: label,
      operation: SyncOperationType.update,
      payload: payload ?? const <String, dynamic>{'score': 79.99, 'submission_status': 'submitted'},
      expectedVersion: 1,
      status: status,
      retryCount: status == SyncItemStatus.failed ? 2 : 0,
      nextRetryAt: null,
      lastError: status == SyncItemStatus.conflict ? 'ข้อมูลชนกัน' : null,
      serverSnapshot: serverSnapshot,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('SyncStatusBadge', () {
    testWidgets('hides at 0 and renders warning vs danger color accurately', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Column(
              children: [
                SyncStatusBadge(counts: SyncQueueStatusCounts.empty),
                SyncStatusBadge(
                  counts: SyncQueueStatusCounts(pendingCount: 3),
                ),
                SyncStatusBadge(
                  counts: SyncQueueStatusCounts(pendingCount: 2, conflictCount: 1),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('0'), findsNothing);
      expect(find.text('3'), findsNWidgets(2));

      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.decoration is BoxDecoration)
          .toList();
      final warningDec = containers[0].decoration! as BoxDecoration;
      final dangerDec = containers[1].decoration! as BoxDecoration;
      expect(warningDec.color, AppSemanticColors.light.warning);
      expect(dangerDec.color, AppSemanticColors.light.danger);
    });
  });

  group('SyncConflictResolutionDialog', () {
    testWidgets('renders Local vs Server cleanly on Desktop and 390px without overflow and triggers both callbacks', (
      tester,
    ) async {
      final conflictItem = makeItem(
        id: 'c-1',
        status: SyncItemStatus.conflict,
        label: 'คะแนน ด.ช.สมชาย — ใบงานที่ 1',
        payload: const <String, dynamic>{
          'submission_status': 'submitted',
          'score': 79.99,
          'note': 'ของฉัน',
        },
        serverSnapshot: const <String, dynamic>{
          'submission_status': 'submitted',
          'score': 80.0,
          'note': 'ของอีกเครื่อง',
          'version': 3,
        },
      );

      var keepMineCalled = 0;
      var useServerCalled = 0;

      for (final width in const <double>[1024, 390]) {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SyncConflictResolutionDialog(
                item: conflictItem,
                onKeepMine: () async {
                  keepMineCalled++;
                  return false;
                },
                onUseServer: () async {
                  useServerCalled++;
                  return false;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('79.99'), findsOneWidget);
        expect(find.textContaining('80'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('ใช้ค่าของฉัน (บันทึกทับเซิร์ฟเวอร์)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ใช้ค่าล่าสุดบนเซิร์ฟเวอร์'));
        await tester.pumpAndSettle();
      }

      expect(keepMineCalled, 2);
      expect(useServerCalled, 2);
    });
  });

  group('SyncQueuePage', () {
    testWidgets('shows Thai empty state when queue is empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(_FakeAuthNotifier.new),
            connectivityStatusProvider.overrideWith((ref) => Stream.value(true)),
            syncQueueItemsStreamProvider.overrideWith(
              (ref) => Stream.value(const <SyncQueueItem>[]),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: SyncQueuePage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('ข้อมูลทั้งหมดซิงค์ขึ้นระบบเรียบร้อยแล้ว — ไม่มีรายการค้าง'),
        findsOneWidget,
      );
    });

    testWidgets(
      'orders Conflict before Pending, disables Sync Now when offline, and invokes syncNow when online on 390px',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final pendingItem = makeItem(
          id: 'p-1',
          status: SyncItemStatus.pending,
          label: 'รายการรอซิงค์-A',
        );
        final conflictItem = makeItem(
          id: 'c-1',
          status: SyncItemStatus.conflict,
          label: 'รายการข้อมูลชนกัน-B',
        );

        // 1) Offline -> Sync Now disabled
        final spyOffline = _SpySyncEngine();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(_FakeAuthNotifier.new),
              connectivityStatusProvider.overrideWith(
                (ref) => Stream.value(false),
              ),
              syncQueueItemsStreamProvider.overrideWith(
                (ref) => Stream.value(<SyncQueueItem>[pendingItem, conflictItem]),
              ),
              syncEngineServiceProvider.overrideWithValue(spyOffline),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(body: SyncQueuePage()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Conflict item appears vertically above Pending item
        final conflictY = tester.getTopLeft(find.text('รายการข้อมูลชนกัน-B')).dy;
        final pendingY = tester.getTopLeft(find.text('รายการรอซิงค์-A')).dy;
        expect(conflictY, lessThan(pendingY));
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('ซิงค์เดี๋ยวนี้'));
        await tester.pumpAndSettle();
        expect(spyOffline.syncCalls, 0);

        // 2) Online -> Sync Now enabled and invokes syncPendingItems
        final spyOnline = _SpySyncEngine();
        await tester.pumpWidget(
          ProviderScope(
            key: const ValueKey<String>('online_sync_scope'),
            overrides: [
              authStateProvider.overrideWith(_FakeAuthNotifier.new),
              connectivityStatusProvider.overrideWith(
                (ref) => Stream.value(true),
              ),
              syncQueueItemsStreamProvider.overrideWith(
                (ref) => Stream.value(<SyncQueueItem>[pendingItem, conflictItem]),
              ),
              syncEngineServiceProvider.overrideWithValue(spyOnline),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(body: SyncQueuePage()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('ซิงค์เดี๋ยวนี้'));
        await tester.pumpAndSettle();
        expect(spyOnline.syncCalls, 1);
      },
    );
  });
}
