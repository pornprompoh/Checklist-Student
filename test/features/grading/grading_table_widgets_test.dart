import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/core/constants/submission_status.dart';
import 'package:checklist_student/core/theme/app_theme.dart';
import 'package:checklist_student/features/grading/domain/entities/assignment.dart';
import 'package:checklist_student/features/grading/domain/entities/grade_result.dart';
import 'package:checklist_student/features/grading/domain/entities/student_score.dart';
import 'package:checklist_student/features/grading/presentation/providers/grading_filter_provider.dart';
import 'package:checklist_student/features/grading/presentation/providers/grading_table_state.dart';
import 'package:checklist_student/features/grading/presentation/widgets/editable_score_cell.dart';
import 'package:checklist_student/features/grading/presentation/widgets/frozen_grade_grid.dart';
import 'package:checklist_student/features/grading/presentation/widgets/save_status_indicator.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/class_enrollment.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/student_lifecycle_status.dart';

void main() {
  final now = DateTime.utc(2026, 11, 25);

  final assignment = Assignment(
    id: 'assign-1',
    teacherId: 'teacher-1',
    subjectClassId: 'class-1',
    title: 'ใบงานที่ 1',
    maxScore: 10,
    isMandatory: true,
    createdAt: now,
    updatedAt: now,
  );

  Widget wrapThemed(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('EditableScoreCell & Preview Mode Guardrails', () {
    testWidgets(
      'Preview Mode ignores single tap and only enters edit on double tap',
      (tester) async {
        var startEditCalls = 0;

        await tester.pumpWidget(
          wrapThemed(
            EditableScoreCell(
              assignment: assignment,
              studentScore: null,
              isEditMode: false,
              isEditing: false,
              isReadOnly: false,
              saveStatus: CellSaveStatus.idle,
              width: 104,
              height: 56,
              onStartEditing: () => startEditCalls++,
              onCancelEditing: () {},
              onCommitScore: (_, _) async {},
              onOpenDetailDialog: () {},
              onMoveNextRow: () {},
              onMoveNextColumn: () {},
              onMovePreviousColumn: () {},
            ),
          ),
        );

        // Single tap in Preview Mode MUST NOT trigger edit or show TextField.
        await tester.tap(find.byType(EditableScoreCell));
        await tester.pump(const Duration(milliseconds: 400));
        expect(startEditCalls, 0);
        expect(find.byType(TextField), findsNothing);

        // Double tap in Preview Mode triggers onStartEditing.
        await tester.tap(find.byType(EditableScoreCell));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byType(EditableScoreCell));
        await tester.pumpAndSettle();
        expect(startEditCalls, 1);
      },
    );

    testWidgets(
      'Inline editing commits exact decimal with Enter and moves to next row',
      (tester) async {
        double? committedScore;
        SubmissionStatus? committedStatus;
        var movedNextRow = false;

        await tester.pumpWidget(
          wrapThemed(
            EditableScoreCell(
              assignment: assignment,
              studentScore: null,
              isEditMode: true,
              isEditing: true,
              isReadOnly: false,
              saveStatus: CellSaveStatus.idle,
              width: 104,
              height: 56,
              onStartEditing: () {},
              onCancelEditing: () {},
              onCommitScore: (score, status) async {
                committedScore = score;
                committedStatus = status;
              },
              onOpenDetailDialog: () {},
              onMoveNextRow: () => movedNextRow = true,
              onMoveNextColumn: () {},
              onMovePreviousColumn: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        await tester.enterText(find.byType(TextField), '7.75');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(committedScore, 7.75);
        expect(committedStatus, SubmissionStatus.submitted);
        expect(movedNextRow, isTrue);
      },
    );

    testWidgets('Highlights warning when score exceeds assignment maxScore', (
      tester,
    ) async {
      final overMaxScore = StudentScore(
        id: 'score-1',
        teacherId: 'teacher-1',
        assignmentId: 'assign-1',
        enrollmentId: 'enr-1',
        submissionStatus: SubmissionStatus.submitted,
        score: 12.5,
        updatedAt: now,
      );

      await tester.pumpWidget(
        wrapThemed(
          EditableScoreCell(
            assignment: assignment,
            studentScore: overMaxScore,
            isEditMode: false,
            isEditing: false,
            isReadOnly: false,
            saveStatus: CellSaveStatus.saved,
            width: 104,
            height: 56,
            onStartEditing: () {},
            onCancelEditing: () {},
            onCommitScore: (_, _) async {},
            onOpenDetailDialog: () {},
            onMoveNextRow: () {},
            onMoveNextColumn: () {},
            onMovePreviousColumn: () {},
          ),
        ),
      );

      expect(find.text('12.5'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });

  group('SaveStatusIndicator & FrozenGradeGrid', () {
    testWidgets('SaveStatusIndicator renders saving, saved, and error states', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapThemed(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SaveStatusIndicator(status: CellSaveStatus.saving),
              SizedBox(height: 8),
              SaveStatusIndicator(status: CellSaveStatus.saved),
              SizedBox(height: 8),
              SaveStatusIndicator(status: CellSaveStatus.error),
            ],
          ),
        ),
      );

      expect(find.text('กำลังบันทึก...'), findsOneWidget);
      expect(find.text('บันทึกแล้ว'), findsOneWidget);
      expect(find.text('บันทึกไม่สำเร็จ'), findsOneWidget);
    });

    testWidgets(
      'FrozenGradeGrid renders cleanly on 390px viewport with exact unrounded total',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final row = GradingTableRowData(
          enrollment: ClassEnrollment(
            id: 'enr-1',
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
            enrolledAt: now,
            transferredOutAt: null,
            specialGradeOverride: null,
            wasRResolved: false,
            wasMsResolved: false,
            resolvedGradeAt: null,
            version: 1,
            createdAt: now,
            updatedAt: now,
          ),
          gradeResult: const GradeResult(
            enrollmentId: 'enr-1',
            totalScore: 79.75,
            totalMaxScore: 100.0,
            percentage: 79.75,
            categorySummaries: <CategoryScoreSummary>[],
            missingAssignmentsCount: 0,
            missingMandatoryCount: 0,
            overMaxAssignmentIds: <String>[],
            evaluatedGrade: '3.5',
            specialGradeOverride: null,
            displayedGrade: '3.5',
            specialGradeAdvice: SpecialGradeAdvice(
              recommendR: false,
              recommendMs: false,
              primaryRecommendedCode: null,
              reasons: <String>[],
            ),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SizedBox(
                height: 400,
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
                ),
              ),
            ),
          ),
        );

        expect(find.text('ด.ช.สมชาย ใจดี'), findsOneWidget);
        expect(find.text('79.75'), findsOneWidget);
        expect(find.text('3.5'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
