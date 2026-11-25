import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/core/constants/submission_status.dart';
import 'package:checklist_student/core/theme/app_theme.dart';
import 'package:checklist_student/features/attendance/domain/entities/student_attendance_summary.dart';
import 'package:checklist_student/features/grading/domain/entities/assignment.dart';
import 'package:checklist_student/features/grading/domain/entities/grade_result.dart';
import 'package:checklist_student/features/grading/domain/entities/student_pin_status.dart';
import 'package:checklist_student/features/grading/domain/entities/student_score.dart';
import 'package:checklist_student/features/grading/presentation/providers/grading_filter_provider.dart';
import 'package:checklist_student/features/grading/presentation/providers/grading_table_state.dart';
import 'package:checklist_student/features/grading/presentation/providers/student_profile_drawer_controller.dart';
import 'package:checklist_student/features/grading/presentation/widgets/frozen_grade_grid.dart';
import 'package:checklist_student/features/grading/presentation/widgets/special_grade_action_dialog.dart';
import 'package:checklist_student/features/grading/presentation/widgets/special_grade_badge.dart';
import 'package:checklist_student/features/grading/presentation/widgets/student_profile_drawer.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/class_enrollment.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/student_lifecycle_status.dart';

void main() {
  final now = DateTime.utc(2026, 11, 25);

  ClassEnrollment buildEnrollment({
    String id = 'enr-1',
    String? specialGradeOverride,
    bool wasRResolved = false,
  }) {
    return ClassEnrollment(
      id: id,
      teacherId: 'teacher-1',
      subjectClassId: 'class-1',
      homeroomStudentId: null,
      studentIdentityId: 'ident-1',
      studentCode: '67001',
      studentNumber: 1,
      prefix: 'ด.ช.',
      firstName: 'สมชาย',
      lastName: 'ใจดี',
      status: StudentLifecycleStatus.active,
      enrolledAt: DateTime(2026, 5, 16),
      transferredOutAt: null,
      specialGradeOverride: specialGradeOverride,
      wasRResolved: wasRResolved,
      wasMsResolved: false,
      resolvedGradeAt: wasRResolved ? now : null,
      version: 2,
      createdAt: now,
      updatedAt: now,
    );
  }

  GradeResult buildGradeResult({
    String? specialGradeOverride,
    bool recommendR = false,
    bool recommendMs = false,
    bool wasRResolved = false,
    bool wasMsResolved = false,
    int assessedAssignmentsCount = 0,
    int totalAssignmentsCount = 0,
  }) {
    return GradeResult(
      enrollmentId: 'enr-1',
      totalScore: 76.5,
      totalMaxScore: 100.0,
      percentage: 76.5,
      categorySummaries: const <CategoryScoreSummary>[],
      missingAssignmentsCount: recommendR ? 1 : 0,
      missingMandatoryCount: recommendR ? 1 : 0,
      overMaxAssignmentIds: const <String>[],
      evaluatedGrade: '3.5',
      specialGradeOverride: specialGradeOverride,
      displayedGrade: specialGradeOverride ?? '3.5',
      specialGradeAdvice: SpecialGradeAdvice(
        recommendR: recommendR,
        recommendMs: recommendMs,
        primaryRecommendedCode: recommendMs ? 'มส' : (recommendR ? 'ร' : null),
        reasons: <String>[
          if (recommendMs) 'ขาดเรียนเกินเกณฑ์ มส (25%)',
          if (recommendR) 'ค้างงานบังคับส่ง 1 ชิ้น',
        ],
        assessedAssignmentsCount: assessedAssignmentsCount,
        totalAssignmentsCount: totalAssignmentsCount,
      ),
      wasRResolved: wasRResolved,
      wasMsResolved: wasMsResolved,
      resolvedGradeAt: (wasRResolved || wasMsResolved) ? now : null,
    );
  }

  group('Special Grade & Student Profile Drawer Guardrails', () {
    testWidgets(
      'Safety Guard: tapping student name/number NEVER opens Drawer; only trailing icon does',
      (tester) async {
        final opened = <ClassEnrollment>[];
        final enrollment = buildEnrollment();
        final row = GradingTableRowData(
          enrollment: enrollment,
          gradeResult: buildGradeResult(),
        );
        final assignment = Assignment(
          id: 'assign-1',
          teacherId: 'teacher-1',
          subjectClassId: 'class-1',
          title: 'ใบงานที่ 1',
          maxScore: 10,
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SizedBox(
                height: 360,
                child: FrozenGradeGrid(
                  rows: <GradingTableRowData>[row],
                  assignments: <Assignment>[assignment],
                  scoresByCellKey: const <String, StudentScore>{},
                  cellStatuses: const <String, CellSaveStatus>{},
                  isEditMode: false,
                  activeCellKey: null,
                  onStartCellEdit: (_, _) {},
                  onCancelCellEdit: () {},
                  onCommitCellScore: ({
                    required enrollmentId,
                    required assignmentId,
                    required score,
                    required status,
                  }) async {},
                  onOpenCellDetail: (_, _) {},
                  onOpenStudentProfile: opened.add,
                ),
              ),
            ),
          ),
        );

        // Tap student name and number -> MUST NOT open drawer.
        await tester.tap(find.text('ด.ช.สมชาย ใจดี'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('67001'));
        await tester.pumpAndSettle();
        expect(opened, isEmpty);

        // Tap trailing profile icon button -> opens drawer once with enrollment.
        await tester.tap(find.byKey(const ValueKey<String>('open_profile_enr-1')));
        await tester.pumpAndSettle();
        expect(opened, hasLength(1));
        expect(opened.single.id, 'enr-1');
      },
    );

    testWidgets(
      'SpecialGradeBadge renders confirmed override, advisory, and resolved history states',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Column(
                children: [
                  SpecialGradeBadge(
                    result: buildGradeResult(specialGradeOverride: 'ร'),
                  ),
                  SpecialGradeBadge(result: buildGradeResult(recommendMs: true)),
                  SpecialGradeBadge(
                    result: buildGradeResult(wasRResolved: true),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('ร'), findsOneWidget);
        expect(find.text('แนะนำ มส'), findsOneWidget);
        expect(find.text('เคยแก้ ร'), findsOneWidget);
        expect(find.text('3.5'), findsNWidgets(2));
      },
    );

    testWidgets(
      'SpecialGradeActionDialog offers confirm buttons when normal and resolve button when overridden',
      (tester) async {
        SpecialGradeActionDecision? decision;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        decision = await SpecialGradeActionDialog.show(
                          context,
                          studentLabel: 'เลขที่ 1 ด.ช.สมชาย ใจดี',
                          gradeResult: buildGradeResult(recommendR: true),
                        );
                      },
                      child: const Text('เปิดโหมดปกติ'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        decision = await SpecialGradeActionDialog.show(
                          context,
                          studentLabel: 'เลขที่ 1 ด.ช.สมชาย ใจดี',
                          gradeResult: buildGradeResult(
                            specialGradeOverride: 'ร',
                          ),
                        );
                      },
                      child: const Text('เปิดโหมดติด ร'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Normal mode -> confirm ร / มส available
        await tester.tap(find.text('เปิดโหมดปกติ'));
        await tester.pumpAndSettle();
        expect(find.text('ยืนยันติด ร'), findsOneWidget);
        expect(find.text('ยืนยันติด มส'), findsOneWidget);
        await tester.tap(find.text('ยืนยันติด ร'));
        await tester.pumpAndSettle();
        expect(decision?.specialGradeOverride, 'ร');
        expect(decision?.markRResolved, isFalse);

        // Overridden ร mode -> resolve ร button immediately returns null + markRResolved=true
        await tester.tap(find.text('เปิดโหมดติด ร'));
        await tester.pumpAndSettle();
        expect(find.textContaining('บันทึกแก้ ร ผ่านแล้ว'), findsOneWidget);
        await tester.tap(find.textContaining('บันทึกแก้ ร ผ่านแล้ว'));
        await tester.pumpAndSettle();
        expect(decision?.specialGradeOverride, isNull);
        expect(decision?.markRResolved, isTrue);
      },
    );

    testWidgets(
      'StudentProfileDrawer renders attendance, assignments, PIN reset confirm, and transfer on 390px',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final enrollment = buildEnrollment();
        final assignment = Assignment(
          id: 'assign-1',
          teacherId: 'teacher-1',
          subjectClassId: 'class-1',
          title: 'โครงงานวิทยาศาสตร์',
          maxScore: 20,
          isMandatory: true,
          createdAt: now,
          updatedAt: now,
        );
        final score = StudentScore(
          id: 'score-1',
          teacherId: 'teacher-1',
          assignmentId: 'assign-1',
          enrollmentId: 'enr-1',
          submissionStatus: SubmissionStatus.submitted,
          score: 18.5,
          note: 'ส่งครบเรียบร้อย',
          updatedAt: now,
        );
        const attendance = StudentAttendanceSummary(
          enrollmentId: 'enr-1',
          totalEligibleSessions: 20,
          recordedSessions: 20,
          presentCount: 15,
          lateCount: 0,
          leaveCount: 0,
          absentCount: 5,
          convertedLateAbsentCount: 0,
          countedLeaveAbsentCount: 0,
          effectiveAbsentCount: 5,
          absentPercentage: 25.0,
          riskLevel: AttendanceRiskLevel.exceededMs,
        );

        final rowData = GradingTableRowData(
          enrollment: enrollment,
          gradeResult: buildGradeResult(recommendMs: true),
          attendanceSummary: attendance,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              studentPinStatusProvider('ident-1').overrideWith(
                (ref) async => StudentPinStatus(
                  studentIdentityId: 'ident-1',
                  hasPin: true,
                  failedAttempts: 0,
                  pinUpdatedAt: now,
                ),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(
                body: StudentProfileDrawer(
                  rowData: rowData,
                  assignments: <Assignment>[assignment],
                  scoresByCellKey: <String, StudentScore>{
                    gradingCellKey('enr-1', 'assign-1'): score,
                  },
                  onManageSpecialGrade: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('ด.ช.สมชาย ใจดี'), findsOneWidget);
        expect(find.text('มา 15'), findsOneWidget);
        expect(find.text('ขาด 5'), findsOneWidget);
        expect(find.text('โครงงานวิทยาศาสตร์'), findsOneWidget);
        expect(find.text('18.5 / 20'), findsOneWidget);

        // Scroll down to PIN & transfer actions section and verify PIN reset confirm dialog.
        await tester.drag(find.byType(ListView), const Offset(0, -450));
        await tester.pumpAndSettle();

        expect(find.textContaining('ตั้ง PIN แล้ว'), findsOneWidget);
        expect(find.text('รีเซต PIN นักเรียน'), findsOneWidget);
        expect(find.text('บันทึกย้ายออก (Soft Delete)'), findsOneWidget);

        await tester.tap(find.text('รีเซต PIN นักเรียน'));
        await tester.pumpAndSettle();

        expect(find.text('ยืนยันการรีเซต PIN นักเรียน'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'UC-020: SpecialGradeActionDialog shows assessed progress notice (X/Y งาน) when incomplete while keeping manual confirm buttons active',
      (tester) async {
        SpecialGradeActionDecision? decision;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    decision = await SpecialGradeActionDialog.show(
                      context,
                      studentLabel: 'เลขที่ 1 ด.ช.สมชาย ใจดี',
                      gradeResult: buildGradeResult(
                        recommendR: false,
                        assessedAssignmentsCount: 2,
                        totalAssignmentsCount: 5,
                      ),
                    );
                  },
                  child: const Text('เปิดจัดการเกรดพิเศษ'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('เปิดจัดการเกรดพิเศษ'));
        await tester.pumpAndSettle();

        expect(find.textContaining('กรอกแล้ว 2/5 งาน'), findsOneWidget);
        expect(find.text('ยืนยันติด ร'), findsOneWidget);
        expect(find.text('ยืนยันติด มส'), findsOneWidget);

        await tester.tap(find.text('ยืนยันติด ร'));
        await tester.pumpAndSettle();
        expect(decision?.specialGradeOverride, 'ร');
      },
    );
  });
}
