import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/core/constants/submission_status.dart';
import 'package:checklist_student/core/errors/app_exception.dart';
import 'package:checklist_student/core/theme/app_theme.dart';
import 'package:checklist_student/features/attendance/domain/entities/student_attendance_summary.dart';
import 'package:checklist_student/features/grading/domain/entities/assignment.dart';
import 'package:checklist_student/features/grading/domain/entities/grade_result.dart';
import 'package:checklist_student/features/grading/domain/entities/grading_scale_config.dart';
import 'package:checklist_student/features/grading/domain/entities/score_category.dart';
import 'package:checklist_student/features/grading/domain/entities/student_pin_status.dart';
import 'package:checklist_student/features/grading/domain/entities/student_score.dart';
import 'package:checklist_student/features/grading/domain/repositories/grading_repository.dart';
import 'package:checklist_student/features/grading/presentation/providers/grading_filter_provider.dart';
import 'package:checklist_student/features/grading/presentation/providers/grading_providers.dart';
import 'package:checklist_student/features/grading/presentation/providers/grading_table_controller.dart';
import 'package:checklist_student/features/grading/presentation/widgets/editable_score_cell.dart';
import 'package:checklist_student/features/grading/presentation/widgets/frozen_grade_grid.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/class_enrollment.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/student_lifecycle_status.dart';

class _OptimisticScoreRepo implements GradingRepository {
  final Map<String, StudentScore> _store = <String, StudentScore>{};
  final List<int?> receivedExpectedVersions = <int?>[];
  bool forceConflictNext = false;

  @override
  Future<StudentScore> upsertStudentScore({
    required String teacherId,
    required String assignmentId,
    required String enrollmentId,
    String? existingScoreId,
    int? expectedVersion,
    required SubmissionStatus submissionStatus,
    double? score,
    String note = '',
  }) async {
    receivedExpectedVersions.add(expectedVersion);
    if (forceConflictNext) {
      throw const ConflictException(
        'คะแนนรายการนี้ถูกแก้ไขจากอุปกรณ์อื่น กรุณาโหลดข้อมูลล่าสุดก่อนบันทึกใหม่',
      );
    }

    final key = gradingCellKey(enrollmentId, assignmentId);
    final existing = _store[key];
    if (existingScoreId != null) {
      if (existing == null || existing.version != expectedVersion) {
        throw const ConflictException('version mismatch');
      }
      final updated = existing.copyWith(
        submissionStatus: submissionStatus,
        score: score,
        note: note,
        version: expectedVersion! + 1,
        updatedAt: DateTime.utc(2026, 11, 25),
      );
      _store[key] = updated;
      return updated;
    }

    final created = StudentScore(
      id: 'score-$key',
      teacherId: teacherId,
      assignmentId: assignmentId,
      enrollmentId: enrollmentId,
      submissionStatus: submissionStatus,
      score: score,
      note: note,
      version: 1,
      updatedAt: DateTime.utc(2026, 11, 25),
    );
    _store[key] = created;
    return created;
  }

  @override
  Future<List<ScoreCategory>> fetchScoreCategories(String id) async => const [];
  @override
  Future<ScoreCategory> createScoreCategory({
    required String teacherId,
    required String subjectClassId,
    required String name,
    double? targetMaxScore,
    int? sortOrder,
  }) => throw UnimplementedError();
  @override
  Future<ScoreCategory> updateScoreCategory({
    required String categoryId,
    required String name,
    double? targetMaxScore,
    int? sortOrder,
  }) => throw UnimplementedError();
  @override
  Future<void> deleteScoreCategory(String id) => throw UnimplementedError();
  @override
  Future<List<Assignment>> fetchAssignments(String id) async => const [];
  @override
  Future<Assignment> createAssignment({
    required String teacherId,
    required String subjectClassId,
    String? categoryId,
    required String title,
    String description = '',
    required double maxScore,
    bool isMandatory = false,
    DateTime? dueDate,
    int? sortOrder,
  }) => throw UnimplementedError();
  @override
  Future<Assignment> updateAssignment({
    required String assignmentId,
    required int expectedVersion,
    String? categoryId,
    required String title,
    required String description,
    required double maxScore,
    required bool isMandatory,
    DateTime? dueDate,
    int? sortOrder,
  }) => throw UnimplementedError();
  @override
  Future<int> countScoredStudentsForAssignment(String id) async => 0;
  @override
  Future<void> deleteAssignment(String id) => throw UnimplementedError();
  @override
  Future<List<StudentScore>> fetchStudentScoresByClass(String id) async =>
      _store.values.toList();
  @override
  Future<GradingScaleConfig> fetchGradingScaleConfig(String id) async =>
      GradingScaleConfig(
        subjectClassId: id,
        scaleType: GradingScaleType.scale0To4,
        rules: GradingScaleConfig.defaultZeroToFourRules,
        missingWorkThreshold: 3,
      );
  @override
  Future<GradingScaleConfig> updateGradingScaleConfig(
    GradingScaleConfig config,
  ) => throw UnimplementedError();
  @override
  Future<CopyPlanResult> copySubjectClassPlan({
    required String sourceClassId,
    required String targetClassId,
    bool replaceExisting = false,
  }) => throw UnimplementedError();
  @override
  Future<void> updateSpecialGradeStatus({
    required String enrollmentId,
    required int expectedVersion,
    required String? specialGradeOverride,
    required bool markRResolved,
    required bool markMsResolved,
  }) => throw UnimplementedError();
  @override
  Future<StudentPinStatus> fetchStudentPinStatus(String id) =>
      throw UnimplementedError();
  @override
  Future<void> resetStudentPin(String id) => throw UnimplementedError();
}

void main() {
  final now = DateTime.utc(2026, 11, 25);

  group('Phase 4 QA Gate — Grading Table E2E Flows (UC-013, UC-014, UC-015)', () {
    test(
      'UC-013, UC-014 & UC-015: Preview default, multi-edit Optimistic Locking, ConflictException, and exact 79.99 -> 3.5',
      () async {
        final repo = _OptimisticScoreRepo();
        final container = ProviderContainer(
          overrides: [gradingRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        final ctrl = container.read(gradingTableControllerProvider.notifier);

        // Default Preview Mode
        expect(container.read(gradingTableControllerProvider).isEditMode, isFalse);

        // Edit #1: null -> 40.50 (auto-promotes missing -> submitted, version = 1)
        final ok1 = await ctrl.autoSaveCellScore(
          teacherId: 'teacher-1',
          enrollmentId: 'enr-1',
          assignmentId: 'a1',
          score: 40.50,
          status: SubmissionStatus.missing,
        );
        expect(ok1, isTrue);
        expect(
          container.read(gradingTableControllerProvider).overallSaveStatus,
          CellSaveStatus.saved,
        );
        expect(
          container
              .read(gradingTableControllerProvider)
              .scoresByCellKey[gradingCellKey('enr-1', 'a1')]
              ?.submissionStatus,
          SubmissionStatus.submitted,
        );

        // Edit #2 on SAME cell: 40.50 -> 40.50 (unchanged) does not trigger extra write
        final okNoop = await ctrl.autoSaveCellScore(
          teacherId: 'teacher-1',
          enrollmentId: 'enr-1',
          assignmentId: 'a1',
          score: 40.50,
          status: SubmissionStatus.submitted,
        );
        expect(okNoop, isTrue);
        expect(repo.receivedExpectedVersions, <int?>[null]);

        // Edit #3 on SAME cell: 40.50 -> 40.50 + note -> sends expectedVersion = 1, receives version = 2
        final ok2 = await ctrl.autoSaveCellScore(
          teacherId: 'teacher-1',
          enrollmentId: 'enr-1',
          assignmentId: 'a1',
          score: 40.50,
          status: SubmissionStatus.submitted,
          note: 'ตรวจแล้ว',
        );
        expect(ok2, isTrue);
        expect(repo.receivedExpectedVersions, <int?>[null, 1]);
        expect(
          container
              .read(gradingTableControllerProvider)
              .scoresByCellKey[gradingCellKey('enr-1', 'a1')]
              ?.version,
          2,
        );

        // Add second assignment score 39.49 -> live total = 79.99 -> grade = 3.5 (NOT 4)
        await ctrl.autoSaveCellScore(
          teacherId: 'teacher-1',
          enrollmentId: 'enr-1',
          assignmentId: 'a2',
          score: 39.49,
          status: SubmissionStatus.submitted,
        );

        final liveRows = ctrl.buildLiveRows(
          enrollments: <ClassEnrollment>[
            ClassEnrollment(
              id: 'enr-1',
              teacherId: 'teacher-1',
              subjectClassId: 'class-1',
              homeroomStudentId: null,
              studentIdentityId: 'id-1',
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
          ],
          categories: const <ScoreCategory>[],
          assignments: <Assignment>[
            Assignment(
              id: 'a1',
              teacherId: 'teacher-1',
              subjectClassId: 'class-1',
              title: 'กลางภาค',
              maxScore: 50,
              createdAt: now,
              updatedAt: now,
            ),
            Assignment(
              id: 'a2',
              teacherId: 'teacher-1',
              subjectClassId: 'class-1',
              title: 'ปลายภาค',
              maxScore: 50,
              createdAt: now,
              updatedAt: now,
            ),
          ],
          scaleConfig: const GradingScaleConfig(
            subjectClassId: 'class-1',
            scaleType: GradingScaleType.scale0To4,
            rules: GradingScaleConfig.defaultZeroToFourRules,
            missingWorkThreshold: 3,
          ),
          attendanceSummaries: const <String, StudentAttendanceSummary>{},
        );
        expect(liveRows.single.gradeResult.totalScore, 79.99);
        expect(liveRows.single.gradeResult.evaluatedGrade, '3.5');

        // ConflictException handling
        repo.forceConflictNext = true;
        final conflictResult = await ctrl.autoSaveCellScore(
          teacherId: 'teacher-1',
          enrollmentId: 'enr-1',
          assignmentId: 'a1',
          score: 45.0,
          status: SubmissionStatus.submitted,
        );
        expect(conflictResult, isFalse);
        expect(
          container.read(gradingTableControllerProvider).overallSaveStatus,
          CellSaveStatus.conflict,
        );
        expect(
          container.read(gradingTableControllerProvider).lastErrorMessage,
          contains('อุปกรณ์อื่น'),
        );
      },
    );

    testWidgets(
      'UC-013 Keyboard: Tab moves right, Shift+Tab moves left, Escape cancels without saving',
      (tester) async {
        var movedNextCol = 0;
        var movedPrevCol = 0;
        var cancelled = 0;
        var commits = 0;

        final assignment = Assignment(
          id: 'a1',
          teacherId: 'teacher-1',
          subjectClassId: 'class-1',
          title: 'ใบงาน 1',
          maxScore: 10,
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Center(
                child: EditableScoreCell(
                  assignment: assignment,
                  studentScore: null,
                  isEditMode: true,
                  isEditing: true,
                  isReadOnly: false,
                  saveStatus: CellSaveStatus.idle,
                  width: 104,
                  height: 56,
                  onStartEditing: () {},
                  onCancelEditing: () => cancelled++,
                  onCommitScore: (_, _) async => commits++,
                  onOpenDetailDialog: () {},
                  onMoveNextRow: () {},
                  onMoveNextColumn: () => movedNextCol++,
                  onMovePreviousColumn: () => movedPrevCol++,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), '8.5');
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(movedNextCol, 1);
        expect(commits, 1);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();
        expect(movedPrevCol, 1);

        final commitsBeforeEsc = commits;
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(cancelled, 1);
        expect(commits, commitsBeforeEsc);
      },
    );

    testWidgets(
      'UC-013 Scale & Responsive: FrozenGradeGrid renders 50 students x 10 assignments cleanly on Desktop and 390px',
      (tester) async {
        final assignments = List<Assignment>.generate(
          10,
          (i) => Assignment(
            id: 'a-$i',
            teacherId: 'teacher-1',
            subjectClassId: 'class-1',
            title: 'งานที่ ${i + 1}',
            maxScore: 10,
            isMandatory: i == 0,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final rows = List<GradingTableRowData>.generate(
          50,
          (i) => GradingTableRowData(
            enrollment: ClassEnrollment(
              id: 'enr-$i',
              teacherId: 'teacher-1',
              subjectClassId: 'class-1',
              homeroomStudentId: null,
              studentIdentityId: 'ident-$i',
              studentCode: '67${(i + 1).toString().padLeft(3, '0')}',
              studentNumber: i + 1,
              prefix: 'ด.ช.',
              firstName: 'นักเรียน',
              lastName: 'คนที่ ${i + 1}',
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
            gradeResult: GradeResult(
              enrollmentId: 'enr-$i',
              totalScore: 75.25,
              totalMaxScore: 100.0,
              percentage: 75.25,
              categorySummaries: const <CategoryScoreSummary>[],
              missingAssignmentsCount: 0,
              missingMandatoryCount: 0,
              overMaxAssignmentIds: const <String>[],
              evaluatedGrade: '3.5',
              specialGradeOverride: null,
              displayedGrade: '3.5',
              specialGradeAdvice: const SpecialGradeAdvice(
                recommendR: false,
                recommendMs: false,
                primaryRecommendedCode: null,
                reasons: <String>[],
              ),
            ),
          ),
        );

        for (final viewport in const <Size>[Size(1280, 800), Size(390, 844)]) {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(
                body: FrozenGradeGrid(
                  rows: rows,
                  assignments: assignments,
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
          );
          await tester.pumpAndSettle();
          expect(find.text('ด.ช.นักเรียน คนที่ 1'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        addTearDown(tester.view.reset);
      },
    );
  });
}
