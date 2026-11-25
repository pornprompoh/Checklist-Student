import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/core/theme/app_theme.dart';
import 'package:checklist_student/features/academic_structure/domain/entities/academic_year.dart';
import 'package:checklist_student/features/academic_structure/presentation/providers/academic_structure_providers.dart';
import 'package:checklist_student/features/audit_log/domain/entities/audit_log_target_type.dart';
import 'package:checklist_student/features/audit_log/domain/entities/audit_log_year_summary.dart';
import 'package:checklist_student/features/audit_log/domain/entities/score_audit_log_entry.dart';
import 'package:checklist_student/features/audit_log/domain/repositories/audit_log_repository.dart';
import 'package:checklist_student/features/audit_log/presentation/providers/audit_log_controller.dart';
import 'package:checklist_student/features/audit_log/presentation/providers/audit_log_providers.dart';
import 'package:checklist_student/features/audit_log/presentation/widgets/audit_log_cleanup_banner.dart';
import 'package:checklist_student/features/audit_log/presentation/widgets/audit_log_yearly_cleanup_card.dart';
import 'package:checklist_student/features/auth/domain/entities/auth_state.dart';
import 'package:checklist_student/features/auth/domain/entities/teacher_profile.dart';
import 'package:checklist_student/features/auth/presentation/providers/auth_state_provider.dart';

class _FakeAuthNotifier extends AuthStateNotifier {
  @override
  AuthSessionState build() => AuthSessionState.authenticated(
    userId: 'teacher-1',
    profile: TeacherProfile(
      id: 'teacher-1',
      email: 'teacher@example.com',
      displayName: 'ครูทดสอบ',
      teacherCode: 't-1001',
      schoolName: 'โรงเรียนทดสอบ',
      department: 'กลุ่มสาระคณิตศาสตร์',
      defaultAbsentThresholdPct: 20,
      defaultMissingWorkThreshold: 3,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
  );
}

class _InMemoryAuditLogRepository implements AuditLogRepository {
  _InMemoryAuditLogRepository(this.entries);

  final List<ScoreAuditLogEntry> entries;
  final List<String> deletedYearIds = <String>[];

  @override
  Future<List<ScoreAuditLogEntry>> fetchAuditLogs({
    String? academicYearId,
    String? subjectClassId,
    String? enrollmentId,
    AuditLogTargetType? targetType,
    int limit = 500,
  }) async {
    return entries
        .where((e) {
          if (academicYearId != null && e.academicYearId != academicYearId) {
            return false;
          }
          if (subjectClassId != null && e.subjectClassId != subjectClassId) {
            return false;
          }
          if (enrollmentId != null && e.enrollmentId != enrollmentId) {
            return false;
          }
          if (targetType != null && e.targetType != targetType) {
            return false;
          }
          return true;
        })
        .take(limit)
        .toList(growable: false);
  }

  @override
  Future<List<AuditLogYearSummary>> fetchAuditLogYearSummaries() async {
    final grouped = <String, List<ScoreAuditLogEntry>>{};
    for (final item in entries) {
      grouped.putIfAbsent(item.academicYearId, () => []).add(item);
    }
    return grouped.entries
        .map((kv) {
          final list = kv.value;
          final sortedDates = list.map((e) => e.changedAt).toList()..sort();
          return AuditLogYearSummary(
            academicYearId: kv.key,
            yearBe: list.first.yearBe,
            totalLogsCount: list.length,
            scoreLogsCount: list
                .where((e) => e.targetType == AuditLogTargetType.score)
                .length,
            gradeStatusLogsCount: list
                .where((e) => e.targetType == AuditLogTargetType.gradeStatus)
                .length,
            oldestChangedAt: sortedDates.first,
            newestChangedAt: sortedDates.last,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<int> deleteAuditLogsByAcademicYear(String academicYearId) async {
    deletedYearIds.add(academicYearId);
    final before = entries.length;
    entries.removeWhere((e) => e.academicYearId == academicYearId);
    return before - entries.length;
  }
}

void main() {
  final now = DateTime.utc(2026, 11, 25);

  List<ScoreAuditLogEntry> buildSeedEntries() => <ScoreAuditLogEntry>[
    ScoreAuditLogEntry(
      id: 'log-old-1',
      teacherId: 'teacher-1',
      academicYearId: 'y-2568',
      targetType: AuditLogTargetType.score,
      studentScoreId: 's-old-1',
      enrollmentId: 'enr-old-1',
      oldValue: null,
      newValue: '15.00',
      isInitialEntry: true,
      changedAt: now.subtract(const Duration(days: 350)),
      yearBe: 2568,
      subjectClassId: 'class-old',
      subjectCode: 'ค31101',
      subjectName: 'คณิตศาสตร์',
      roomName: 'ม.4/1',
      studentNumber: 1,
      studentCode: '66001',
      studentFullName: 'ด.ช.รุ่นพี่ เก่า',
      assignmentTitle: 'ใบงานที่ 1',
    ),
    ScoreAuditLogEntry(
      id: 'log-cur-1',
      teacherId: 'teacher-1',
      academicYearId: 'y-2569',
      targetType: AuditLogTargetType.gradeStatus,
      studentScoreId: null,
      enrollmentId: 'enr-cur-1',
      oldValue: null,
      newValue: 'ร',
      isInitialEntry: true,
      changedAt: now.subtract(const Duration(days: 2)),
      yearBe: 2569,
      subjectClassId: 'class-cur',
      subjectCode: 'ค31101',
      subjectName: 'คณิตศาสตร์',
      roomName: 'ม.4/1',
      studentNumber: 2,
      studentCode: '67002',
      studentFullName: 'ด.ญ.สมหญิง ปัจจุบัน',
      assignmentTitle: null,
    ),
  ];

  group('Phase 4 QA Gate — Audit Log E2E Flows (UC-018, UC-019)', () {
    test(
      'UC-019: filters logs, exports valid CSV/JSON, tracks exported year, and deletes ONLY target year logs',
      () async {
        final repo = _InMemoryAuditLogRepository(buildSeedEntries());
        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith(_FakeAuthNotifier.new),
            auditLogRepositoryProvider.overrideWithValue(repo),
          ],
        );
        addTearDown(container.dispose);

        // Filter by gradeStatus -> only log-cur-1
        container
            .read(auditLogFilterProvider.notifier)
            .setTargetType(AuditLogTargetType.gradeStatus);
        final gradeOnly = await container.read(auditLogEntriesProvider.future);
        expect(gradeOnly.map((e) => e.id), <String>['log-cur-1']);

        // Export past year 2568 -> marks exported & builds valid CSV/JSON
        final ctrl = container.read(auditLogControllerProvider.notifier);
        final exportedCount = await ctrl.exportYearLogs(
          academicYearId: 'y-2568',
          yearBe: 2568,
          asJson: false,
        );
        expect(exportedCount, 1);
        expect(
          container.read(exportedAuditLogYearIdsProvider),
          contains('y-2568'),
        );

        final exporter = container.read(auditLogExportServiceProvider);
        final csv = exporter.buildCsvContent(repo.entries);
        expect(csv.startsWith('\uFEFF'), isTrue);
        final jsonMap =
            jsonDecode(
                  exporter.buildJsonContent(
                    repo.entries,
                    yearBe: 2568,
                    exportedAt: now,
                  ),
                )
                as Map<String, dynamic>;
        expect(jsonMap['total_records'], 2);

        // Delete ONLY y-2568 logs -> y-2569 log remains untouched
        final deleted = await ctrl.deleteLogsForAcademicYear('y-2568');
        expect(deleted, 1);
        expect(repo.deletedYearIds, <String>['y-2568']);
        expect(repo.entries.map((e) => e.id), <String>['log-cur-1']);
      },
    );

    testWidgets(
      'UC-019 Dashboard Banner & TypedConfirmDialog: banner shows for old logs, hides after cleanup, and delete requires exact BE year',
      (tester) async {
        final repo = _InMemoryAuditLogRepository(buildSeedEntries());
        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith(_FakeAuthNotifier.new),
            auditLogRepositoryProvider.overrideWithValue(repo),
            academicYearsProvider.overrideWith(
              (ref) async => <AcademicYear>[
                AcademicYear(
                  id: 'y-2569',
                  teacherId: 'teacher-1',
                  yearBe: 2569,
                  createdAt: now,
                  updatedAt: now,
                ),
                AcademicYear(
                  id: 'y-2568',
                  teacherId: 'teacher-1',
                  yearBe: 2568,
                  createdAt: now,
                  updatedAt: now,
                ),
              ],
            ),
            activeTermProvider.overrideWithValue(null),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      const AuditLogCleanupBanner(showNavigationAction: false),
                      Consumer(
                        builder: (context, ref, _) {
                          final summaries =
                              ref
                                  .watch(auditLogYearSummariesProvider)
                                  .asData
                                  ?.value ??
                              const <AuditLogYearSummary>[];
                          return AuditLogYearlyCleanupCard(
                            summaries: summaries,
                            exportedYearIds: ref.watch(
                              exportedAuditLogYearIdsProvider,
                            ),
                            isBusy: false,
                            onExportYearCsv: (_) {},
                            onExportYearJson: (_) {},
                            onDeleteYearLogs: (summary) {
                              ref
                                  .read(auditLogControllerProvider.notifier)
                                  .deleteLogsForAcademicYear(
                                    summary.academicYearId,
                                  );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Banner visible for past year 2568
        expect(find.textContaining('พ.ศ. 2568'), findsWidgets);
        expect(find.text('ล้าง Log ปี พ.ศ. 2568'), findsOneWidget);

        // Tap cleanup button -> TypedConfirmDialog opens with confirm disabled
        await tester.tap(find.text('ล้าง Log ปี พ.ศ. 2568'));
        await tester.pumpAndSettle();
        final confirmBtn = find.widgetWithText(
          FilledButton,
          'ยืนยันล้าง Log ปี 2568',
        );
        expect(tester.widget<FilledButton>(confirmBtn).onPressed, isNull);

        // Wrong year keeps confirm disabled
        await tester.enterText(find.byType(TextField), '2569');
        await tester.pumpAndSettle();
        expect(tester.widget<FilledButton>(confirmBtn).onPressed, isNull);

        // Exact year '2568' enables confirm and deletes ONLY y-2568 logs
        await tester.enterText(find.byType(TextField), '2568');
        await tester.pumpAndSettle();
        expect(tester.widget<FilledButton>(confirmBtn).onPressed, isNotNull);

        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        expect(repo.deletedYearIds, <String>['y-2568']);
        // Cleanup banner now hidden because only fresh 2569 logs remain
        expect(
          find.textContaining('แนะนำสำรองและล้างประวัติคะแนนประจำปี'),
          findsNothing,
        );
      },
    );
  });
}
