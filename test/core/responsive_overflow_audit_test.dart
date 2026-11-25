import 'package:checklist_student/core/constants/app_routes.dart';
import 'package:checklist_student/core/theme/app_theme.dart';
import 'package:checklist_student/core/widgets/app_shell_scaffold.dart';
import 'package:checklist_student/core/widgets/typed_confirm_dialog.dart';
import 'package:checklist_student/features/academic_structure/presentation/pages/academic_structure_page.dart';
import 'package:checklist_student/features/attendance/presentation/pages/attendance_check_in_page.dart';
import 'package:checklist_student/features/attendance/presentation/pages/attendance_rule_settings_page.dart';
import 'package:checklist_student/features/audit_log/presentation/pages/audit_log_page.dart';
import 'package:checklist_student/features/auth/presentation/pages/teacher_login_page.dart';
import 'package:checklist_student/features/dashboard/presentation/pages/teacher_dashboard_page.dart';
import 'package:checklist_student/features/export_reports/presentation/pages/export_reports_page.dart';
import 'package:checklist_student/features/grading/presentation/pages/grading_plan_page.dart';
import 'package:checklist_student/features/grading/presentation/pages/grading_table_page.dart';
import 'package:checklist_student/features/grading/presentation/providers/grading_table_state.dart';
import 'package:checklist_student/features/grading/presentation/widgets/assignment_form_dialog.dart';
import 'package:checklist_student/features/grading/presentation/widgets/copy_plan_dialog.dart';
import 'package:checklist_student/features/grading/presentation/widgets/special_grade_action_dialog.dart';
import 'package:checklist_student/features/grading/presentation/widgets/student_profile_drawer.dart';
import 'package:checklist_student/features/homeroom_roster/presentation/pages/homeroom_roster_page.dart';
import 'package:checklist_student/features/homeroom_roster/presentation/widgets/student_form_dialog.dart';
import 'package:checklist_student/features/settings/presentation/pages/teacher_settings_page.dart';
import 'package:checklist_student/features/sync_queue/presentation/pages/sync_queue_page.dart';
import 'package:checklist_student/features/sync_queue/presentation/widgets/sync_conflict_resolution_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'responsive_test_fixtures.dart';

/// Pumps [widget] across all 6 stress viewports and asserts zero layout errors
/// (including `RenderFlex overflowed`) without suppressing `FlutterError.onError`.
Future<void> pumpAcross6Viewports(
  WidgetTester tester, {
  required ResponsiveTestFixtures fixtures,
  required Widget Function() builder,
  bool isOnline = true,
  bool wrapInScaffold = true,
  Future<void> Function(WidgetTester tester, StressViewport vp)? afterPump,
}) async {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  for (final vp in kStressViewports) {
    tester.view.physicalSize = vp.size;
    tester.view.devicePixelRatio = 1.0;

    final body = builder();
    await tester.pumpWidget(
      ProviderScope(
        key: ValueKey<String>('scope_${vp.label}'),
        overrides: fixtures.buildOverrides(isOnline: isOnline),
        child: MaterialApp(
          theme: AppTheme.light,
          home: wrapInScaffold ? Scaffold(body: body) : body,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.takeException(),
      isNull,
      reason: 'Overflow or layout exception at ${vp.label}',
    );

    if (afterPump != null) {
      await afterPump(tester, vp);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Overflow or layout exception after interaction at ${vp.label}',
      );
    }
  }
}

void main() {
  late ResponsiveTestFixtures fixtures;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    fixtures = ResponsiveTestFixtures();
  });

  group('Hotfix 6.3.2 — Full-App 6-Viewport Responsive Stress Audit', () {
    testWidgets('AppShellScaffold (offline + conflict banner + sidebar toggle)', (
      tester,
    ) async {
      await pumpAcross6Viewports(
        tester,
        fixtures: fixtures,
        isOnline: false,
        wrapInScaffold: false,
        builder: () => const AppShellScaffold(
          currentPath: AppRoutes.teacherDashboard,
          child: TeacherDashboardPage(),
        ),
        afterPump: (tester, vp) async {
          if (vp.size.width >= AppShellScaffold.desktopBreakpoint) {
            final collapseBtn = find.byTooltip('ย่อแถบเมนู');
            if (collapseBtn.evaluate().isNotEmpty) {
              await tester.tap(collapseBtn);
              await tester.pumpAndSettle();
            }
          }
        },
      );
    });

    testWidgets('TeacherLoginPage renders without overflow across 6 viewports', (
      tester,
    ) async {
      await pumpAcross6Viewports(
        tester,
        fixtures: fixtures,
        wrapInScaffold: false,
        builder: () => const TeacherLoginPage(),
      );
    });

    testWidgets('TeacherDashboardPage renders without overflow across 6 viewports', (
      tester,
    ) async {
      await pumpAcross6Viewports(
        tester,
        fixtures: fixtures,
        builder: () => const TeacherDashboardPage(),
      );
    });

    testWidgets('AcademicStructurePage renders without overflow across 6 viewports', (
      tester,
    ) async {
      await pumpAcross6Viewports(
        tester,
        fixtures: fixtures,
        builder: () => const AcademicStructurePage(),
      );
    });

    testWidgets('HomeroomRosterPage (both tabs) renders without overflow across 6 viewports', (
      tester,
    ) async {
      await pumpAcross6Viewports(
        tester,
        fixtures: fixtures,
        builder: () => const HomeroomRosterPage(),
        afterPump: (tester, vp) async {
          final classTab = find.text('รายชื่อแยกตามวิชา+ห้อง');
          if (classTab.evaluate().isNotEmpty) {
            await tester.tap(classTab);
            await tester.pumpAndSettle();
          }
        },
      );
    });

    testWidgets('AttendanceCheckInPage renders without overflow across 6 viewports', (
      tester,
    ) async {
      await pumpAcross6Viewports(
        tester,
        fixtures: fixtures,
        builder: () => const AttendanceCheckInPage(initialClassId: 'class-1'),
      );
    });

    testWidgets('AttendanceRuleSettingsPage renders without overflow across 6 viewports', (
      tester,
    ) async {
      await pumpAcross6Viewports(
        tester,
        fixtures: fixtures,
        builder: () =>
            const AttendanceRuleSettingsPage(subjectClassId: 'class-1'),
      );
    });

    testWidgets('GradingPlanPage renders without overflow across 6 viewports', (
      tester,
    ) async {
      await pumpAcross6Viewports(
        tester,
        fixtures: fixtures,
        builder: () => const GradingPlanPage(initialClassId: 'class-1'),
      );
    });

    testWidgets('GradingTablePage (FrozenGradeGrid + SpecialGradeBadge) across 6 viewports', (
      tester,
    ) async {
      await pumpAcross6Viewports(
        tester,
        fixtures: fixtures,
        builder: () => const GradingTablePage(initialClassId: 'class-1'),
      );
    });

    testWidgets('StudentProfileDrawer renders without overflow across 6 viewports', (
      tester,
    ) async {
      await pumpAcross6Viewports(
        tester,
        fixtures: fixtures,
        builder: () => StudentProfileDrawer(
          rowData: fixtures.drawerRowData,
          assignments: fixtures.assignments,
          scoresByCellKey: <String, dynamic>{}.isEmpty
              ? {
                  for (final s in fixtures.studentScores)
                    gradingCellKey(s.enrollmentId, s.assignmentId): s,
                }
              : const {},
          onManageSpecialGrade: () {},
        ),
      );
    });

    testWidgets('AuditLogPage (history & yearly cleanup tabs) across 6 viewports', (
      tester,
    ) async {
      await pumpAcross6Viewports(
        tester,
        fixtures: fixtures,
        builder: () => const AuditLogPage(),
        afterPump: (tester, vp) async {
          final cleanupTab = find.text('จัดการพื้นที่รายปี');
          if (cleanupTab.evaluate().isNotEmpty) {
            await tester.tap(cleanupTab);
            await tester.pumpAndSettle();
          }
        },
      );
    });

    testWidgets('ExportReportsPage (config + preview tabs) across 6 viewports', (
      tester,
    ) async {
      await pumpAcross6Viewports(
        tester,
        fixtures: fixtures,
        builder: () => const ExportReportsPage(initialClassId: 'class-1'),
        afterPump: (tester, vp) async {
          final previewTab = find.textContaining('Preview');
          if (previewTab.evaluate().isNotEmpty) {
            await tester.tap(previewTab.first);
            await tester.pumpAndSettle();
          }
        },
      );
    });

    testWidgets('SyncQueuePage renders without overflow across 6 viewports', (
      tester,
    ) async {
      await pumpAcross6Viewports(
        tester,
        fixtures: fixtures,
        isOnline: false,
        builder: () => const SyncQueuePage(),
      );
    });

    testWidgets('TeacherSettingsPage renders without overflow across 6 viewports', (
      tester,
    ) async {
      await pumpAcross6Viewports(
        tester,
        fixtures: fixtures,
        builder: () => const TeacherSettingsPage(),
      );
    });

    testWidgets('Key Dialogs render without overflow across 6 viewports', (
      tester,
    ) async {
      final dialogs = <String, Widget Function()>{
        'SyncConflictResolutionDialog': () => SyncConflictResolutionDialog(
          item: fixtures.syncQueueItems.first,
          onKeepMine: () async => true,
          onUseServer: () async => true,
        ),
        'TypedConfirmDialog': () => const TypedConfirmDialog(
          title: 'ยืนยันการลบรายวิชา ว31101 วิทยาการคำนวณ',
          description: 'ข้อมูลนักเรียน คะแนน และประวัติการเช็คชื่อทั้งหมดจะถูกลบถาวร',
          expectedText: 'ว31101',
          impactSummary: <DeleteImpactItem>[
            DeleteImpactItem(label: 'รายชื่อนักเรียนทั้งหมด', count: 38),
            DeleteImpactItem(label: 'ชิ้นงานที่มีคะแนนแล้ว', count: 12),
          ],
        ),
        'SpecialGradeActionDialog': () => SpecialGradeActionDialog(
          studentLabel: 'เลขที่ 1 นายกิตติพงศ์วัฒนากูล1 รัตนประเสริฐศักดิ์',
          gradeResult: fixtures.drawerRowData.gradeResult,
        ),
        'CopyPlanDialog': () => const CopyPlanDialog(
          targetClassId: 'class-1',
          targetHasExistingPlan: true,
        ),
        'AssignmentFormDialog': () => AssignmentFormDialog(
          categories: fixtures.scoreCategories,
          existing: fixtures.assignments.first,
        ),
        'StudentFormDialog': () => StudentFormDialog(
          title: 'เพิ่มนักเรียนใหม่เข้าห้องเรียน',
          initialStudentNumber: 7,
          showEnrolledAt: true,
          showAddToHomeroomOption: true,
          showSyncToLinkedClassesOption: true,
          linkedClassCount: 3,
        ),
      };

      for (final entry in dialogs.entries) {
        await pumpAcross6Viewports(
          tester,
          fixtures: fixtures,
          builder: entry.value,
        );
      }
    });
  });
}
