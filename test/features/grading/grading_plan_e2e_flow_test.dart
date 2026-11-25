import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/core/constants/submission_status.dart';
import 'package:checklist_student/core/errors/app_exception.dart';
import 'package:checklist_student/core/theme/app_theme.dart';
import 'package:checklist_student/core/widgets/unsaved_changes_provider.dart';
import 'package:checklist_student/features/auth/domain/entities/auth_state.dart';
import 'package:checklist_student/features/auth/domain/entities/teacher_profile.dart';
import 'package:checklist_student/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:checklist_student/features/grading/domain/entities/assignment.dart';
import 'package:checklist_student/features/grading/domain/entities/grade_result.dart';
import 'package:checklist_student/features/grading/domain/entities/grading_scale_config.dart';
import 'package:checklist_student/features/grading/domain/entities/score_category.dart';
import 'package:checklist_student/features/grading/domain/entities/student_pin_status.dart';
import 'package:checklist_student/features/grading/domain/entities/student_score.dart';
import 'package:checklist_student/features/grading/domain/repositories/grading_repository.dart';
import 'package:checklist_student/features/grading/presentation/pages/grading_plan_page.dart';
import 'package:checklist_student/features/grading/presentation/providers/grading_providers.dart';
import 'package:checklist_student/features/grading/presentation/providers/plan_editor_controller.dart';
import 'package:checklist_student/features/grading/presentation/widgets/copy_plan_dialog.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/class_enrollment.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/student_lifecycle_status.dart';
import 'package:checklist_student/features/homeroom_roster/presentation/providers/homeroom_roster_providers.dart';

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

class _InMemoryPlanRepository implements GradingRepository {
  final Map<String, List<ScoreCategory>> categoriesByClass = {};
  final Map<String, List<Assignment>> assignmentsByClass = {};
  final Map<String, List<StudentScore>> scoresByClass = {};
  final Map<String, GradingScaleConfig> scaleByClass = {};
  int _seq = 1;

  @override
  Future<List<ScoreCategory>> fetchScoreCategories(String classId) async =>
      List.unmodifiable(categoriesByClass[classId] ?? const <ScoreCategory>[]);

  @override
  Future<ScoreCategory> createScoreCategory({
    required String teacherId,
    required String subjectClassId,
    required String name,
    double? targetMaxScore,
    int? sortOrder,
  }) async {
    final now = DateTime.utc(2026, 11, 25);
    final created = ScoreCategory(
      id: 'cat-${_seq++}',
      teacherId: teacherId,
      subjectClassId: subjectClassId,
      name: name,
      targetMaxScore: targetMaxScore,
      sortOrder: sortOrder ?? 0,
      createdAt: now,
      updatedAt: now,
    );
    categoriesByClass.putIfAbsent(subjectClassId, () => []).add(created);
    return created;
  }

  @override
  Future<ScoreCategory> updateScoreCategory({
    required String categoryId,
    required String name,
    double? targetMaxScore,
    int? sortOrder,
  }) async {
    for (final list in categoriesByClass.values) {
      final idx = list.indexWhere((c) => c.id == categoryId);
      if (idx >= 0) {
        final updated = list[idx].copyWith(
          name: name,
          targetMaxScore: targetMaxScore,
          sortOrder: sortOrder,
        );
        list[idx] = updated;
        return updated;
      }
    }
    throw const ValidationException('not found');
  }

  @override
  Future<void> deleteScoreCategory(String categoryId) async {
    for (final list in categoriesByClass.values) {
      list.removeWhere((c) => c.id == categoryId);
    }
  }

  @override
  Future<List<Assignment>> fetchAssignments(String classId) async =>
      List.unmodifiable(assignmentsByClass[classId] ?? const <Assignment>[]);

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
  }) async {
    final now = DateTime.utc(2026, 11, 25);
    final created = Assignment(
      id: 'assign-${_seq++}',
      teacherId: teacherId,
      subjectClassId: subjectClassId,
      categoryId: categoryId,
      title: title,
      description: description,
      maxScore: maxScore,
      isMandatory: isMandatory,
      dueDate: dueDate,
      sortOrder: sortOrder ?? 0,
      version: 1,
      createdAt: now,
      updatedAt: now,
    );
    assignmentsByClass.putIfAbsent(subjectClassId, () => []).add(created);
    return created;
  }

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
  }) async {
    for (final list in assignmentsByClass.values) {
      final idx = list.indexWhere((a) => a.id == assignmentId);
      if (idx >= 0) {
        if (list[idx].version != expectedVersion) {
          throw const ConflictException('เวอร์ชันไม่ตรงกัน');
        }
        final updated = list[idx].copyWith(
          categoryId: categoryId,
          title: title,
          description: description,
          maxScore: maxScore,
          isMandatory: isMandatory,
          dueDate: dueDate,
          version: expectedVersion + 1,
        );
        list[idx] = updated;
        return updated;
      }
    }
    throw const ValidationException('not found');
  }

  @override
  Future<int> countScoredStudentsForAssignment(String assignmentId) async {
    return scoresByClass.values
        .expand((s) => s)
        .where((s) => s.assignmentId == assignmentId && s.score != null)
        .length;
  }

  @override
  Future<void> deleteAssignment(String assignmentId) async {
    for (final list in assignmentsByClass.values) {
      list.removeWhere((a) => a.id == assignmentId);
    }
  }

  @override
  Future<List<StudentScore>> fetchStudentScoresByClass(String classId) async =>
      List.unmodifiable(scoresByClass[classId] ?? const <StudentScore>[]);

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
  }) => throw UnimplementedError();

  @override
  Future<GradingScaleConfig> fetchGradingScaleConfig(String classId) async {
    return scaleByClass[classId] ??
        GradingScaleConfig(
          subjectClassId: classId,
          scaleType: GradingScaleType.scale0To4,
          rules: GradingScaleConfig.defaultZeroToFourRules,
          missingWorkThreshold: 3,
        );
  }

  @override
  Future<GradingScaleConfig> updateGradingScaleConfig(
    GradingScaleConfig config,
  ) async {
    scaleByClass[config.subjectClassId] = config;
    return config;
  }

  @override
  Future<CopyPlanResult> copySubjectClassPlan({
    required String sourceClassId,
    required String targetClassId,
    bool replaceExisting = false,
  }) async {
    final srcCats = categoriesByClass[sourceClassId] ?? const <ScoreCategory>[];
    final srcAssigns = assignmentsByClass[sourceClassId] ?? const <Assignment>[];
    final srcScale = await fetchGradingScaleConfig(sourceClassId);

    if (replaceExisting) {
      categoriesByClass[targetClassId] = <ScoreCategory>[];
      assignmentsByClass[targetClassId] = <Assignment>[];
    }
    final catMap = <String, String>{};
    for (final cat in srcCats) {
      final copied = await createScoreCategory(
        teacherId: cat.teacherId,
        subjectClassId: targetClassId,
        name: cat.name,
        targetMaxScore: cat.targetMaxScore,
      );
      catMap[cat.id] = copied.id;
    }
    for (final a in srcAssigns) {
      await createAssignment(
        teacherId: a.teacherId,
        subjectClassId: targetClassId,
        categoryId: a.categoryId == null ? null : catMap[a.categoryId],
        title: a.title,
        description: a.description,
        maxScore: a.maxScore,
        isMandatory: a.isMandatory,
        dueDate: a.dueDate,
      );
    }
    scaleByClass[targetClassId] = srcScale.copyWith(
      subjectClassId: targetClassId,
    );
    return CopyPlanResult(
      copiedCategoriesCount: srcCats.length,
      copiedAssignmentsCount: srcAssigns.length,
      gradingScaleType: srcScale.scaleType.dbValue,
    );
  }

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

  group('Phase 4 QA Gate — Grading Plan E2E Flows (UC-010, UC-011, UC-012)', () {
    test(
      'UC-010 & UC-011: creates plan, validates scale, and copies plan in append & replace modes',
      () async {
        final repo = _InMemoryPlanRepository();
        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith(_FakeAuthNotifier.new),
            gradingRepositoryProvider.overrideWithValue(repo),
          ],
        );
        addTearDown(container.dispose);

        final ctrl = container.read(planEditorControllerProvider.notifier);

        // Create category & mandatory assignment in class-A
        final cat = await ctrl.createCategory(
          subjectClassId: 'class-A',
          name: 'คะแนนเก็บ',
          targetMaxScore: 60,
        );
        expect(cat, isNotNull);
        final assign = await ctrl.createAssignment(
          subjectClassId: 'class-A',
          categoryId: cat!.id,
          title: 'ใบงานบังคับ 1',
          maxScore: 20,
          isMandatory: true,
        );
        expect(assign?.isMandatory, isTrue);

        // Save A-F scale config
        final savedScale = await ctrl.saveGradingScaleConfig(
          const GradingScaleConfig(
            subjectClassId: 'class-A',
            scaleType: GradingScaleType.scaleAToF,
            rules: GradingScaleConfig.defaultAToFRules,
            missingWorkThreshold: 4,
          ),
        );
        expect(savedScale?.scaleType, GradingScaleType.scaleAToF);

        // Reject duplicate rules without modifying saved scale
        final invalidSave = await ctrl.saveGradingScaleConfig(
          const GradingScaleConfig(
            subjectClassId: 'class-A',
            scaleType: GradingScaleType.custom,
            rules: <GradingRuleTier>[
              GradingRuleTier(grade: '4', minScore: 80),
              GradingRuleTier(grade: '3', minScore: 80),
            ],
            missingWorkThreshold: 3,
          ),
        );
        expect(invalidSave, isNull);

        // UC-011: Copy append to class-B (which already has 1 old assignment)
        await ctrl.createAssignment(
          subjectClassId: 'class-B',
          title: 'งานเดิม',
          maxScore: 10,
        );
        final appendResult = await ctrl.copyPlanFromClass(
          sourceClassId: 'class-A',
          targetClassId: 'class-B',
          replaceExisting: false,
        );
        expect(appendResult?.copiedCategoriesCount, 1);
        expect(appendResult?.copiedAssignmentsCount, 1);
        expect((await repo.fetchAssignments('class-B')).length, 2);

        // UC-011: Copy replace to class-B -> leaves only copied plan + A-F scale
        final replaceResult = await ctrl.copyPlanFromClass(
          sourceClassId: 'class-A',
          targetClassId: 'class-B',
          replaceExisting: true,
        );
        expect(replaceResult?.copiedAssignmentsCount, 1);
        expect((await repo.fetchAssignments('class-B')).length, 1);
        expect(
          (await repo.fetchGradingScaleConfig('class-B')).scaleType,
          GradingScaleType.scaleAToF,
        );
      },
    );

    test(
      'UC-012: lowering maxScore finds over-max students without deleting scores & enforces Optimistic Locking',
      () async {
        final repo = _InMemoryPlanRepository();
        final assign = await repo.createAssignment(
          teacherId: 'teacher-1',
          subjectClassId: 'class-A',
          title: 'สอบย่อย 1',
          maxScore: 20,
        );
        repo.scoresByClass['class-A'] = <StudentScore>[
          StudentScore(
            id: 's1',
            teacherId: 'teacher-1',
            assignmentId: assign.id,
            enrollmentId: 'enr-1',
            submissionStatus: SubmissionStatus.submitted,
            score: 18.5,
            updatedAt: now,
          ),
          StudentScore(
            id: 's2',
            teacherId: 'teacher-1',
            assignmentId: assign.id,
            enrollmentId: 'enr-2',
            submissionStatus: SubmissionStatus.submitted,
            score: 14.0,
            updatedAt: now,
          ),
        ];

        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith(_FakeAuthNotifier.new),
            gradingRepositoryProvider.overrideWithValue(repo),
            classEnrollmentsProvider('class-A').overrideWith(
              (ref) async => <ClassEnrollment>[
                ClassEnrollment(
                  id: 'enr-1',
                  teacherId: 'teacher-1',
                  subjectClassId: 'class-A',
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
            ),
          ],
        );
        addTearDown(container.dispose);

        final ctrl = container.read(planEditorControllerProvider.notifier);

        // Lower maxScore from 20 -> 15: detects student #1 (18.5 > 15)
        final affected = await ctrl.findOverMaxScoresForNewMax(
          subjectClassId: 'class-A',
          assignmentId: assign.id,
          newMaxScore: 15,
        );
        expect(affected, hasLength(1));
        expect(affected.single.currentScore, 18.5);
        expect(affected.single.studentLabel, contains('สมชาย'));

        // Stale version update fails with ConflictException in controller state
        final staleUpdate = await ctrl.updateAssignment(
          subjectClassId: 'class-A',
          assignmentId: assign.id,
          expectedVersion: 99,
          title: 'สอบย่อย 1',
          description: '',
          maxScore: 15,
          isMandatory: false,
        );
        expect(staleUpdate, isNull);
        expect(
          container.read(planEditorControllerProvider).error,
          isA<ConflictException>(),
        );

        // Valid version update succeeds and original score 18.5 stays intact
        final updated = await ctrl.updateAssignment(
          subjectClassId: 'class-A',
          assignmentId: assign.id,
          expectedVersion: 1,
          title: 'สอบย่อย 1',
          description: '',
          maxScore: 15,
          isMandatory: false,
        );
        expect(updated?.version, 2);
        expect(repo.scoresByClass['class-A']!.first.score, 18.5);
        expect(await ctrl.countScoredStudents(assign.id), 2);
      },
    );

    testWidgets(
      'UC-010 & UC-011 Widget: GradingPlanPage activates UnsavedChangesGuard & CopyPlanDialog shows cross-term options',
      (tester) async {
        final repo = _InMemoryPlanRepository();
        const options = <CopyPlanSourceClassOption>[
          CopyPlanSourceClassOption(
            subjectClassId: 'class-A',
            academicYearBe: 2569,
            termId: 't-1',
            termLabel: '1',
            subjectCode: 'ค31101',
            subjectName: 'คณิตศาสตร์',
            roomName: 'ม.4/1',
          ),
          CopyPlanSourceClassOption(
            subjectClassId: 'class-old',
            academicYearBe: 2568,
            termId: 't-0',
            termLabel: '2',
            subjectCode: 'ค31101',
            subjectName: 'คณิตศาสตร์',
            roomName: 'ม.4/1',
          ),
        ];

        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith(_FakeAuthNotifier.new),
            gradingRepositoryProvider.overrideWithValue(repo),
            allCopyableClassesProvider.overrideWith((ref) async => options),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(
                body: GradingPlanPage(initialClassId: 'class-A'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(container.read(unsavedChangesStateProvider), isFalse);

        // Edit grading scale without saving -> UnsavedChangesGuard marks global dirty
        await tester.ensureVisible(find.text('A-F'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('A-F'));
        await tester.pumpAndSettle();
        expect(container.read(unsavedChangesStateProvider), isTrue);

        // Open CopyPlanDialog -> verify past-year class option and replace warning
        await tester.ensureVisible(find.text('คัดลอกแผนและเกณฑ์'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('คัดลอกแผนและเกณฑ์'));
        await tester.pumpAndSettle();
        expect(find.byType(CopyPlanDialog), findsOneWidget);
        expect(find.text('เพิ่มต่อท้ายแผนเดิม'), findsOneWidget);
        expect(find.text('แทนที่แผนเดิม'), findsOneWidget);
      },
    );
  });
}
