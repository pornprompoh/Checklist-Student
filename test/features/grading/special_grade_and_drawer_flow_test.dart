import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/core/constants/submission_status.dart';
import 'package:checklist_student/core/errors/app_exception.dart';
import 'package:checklist_student/core/theme/app_theme.dart';
import 'package:checklist_student/features/attendance/domain/entities/student_attendance_summary.dart';
import 'package:checklist_student/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:checklist_student/features/auth/domain/entities/auth_state.dart';
import 'package:checklist_student/features/auth/domain/entities/teacher_profile.dart';
import 'package:checklist_student/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:checklist_student/features/grading/data/models/student_pin_status_dto.dart';
import 'package:checklist_student/features/grading/domain/entities/assignment.dart';
import 'package:checklist_student/features/grading/domain/entities/grade_result.dart';
import 'package:checklist_student/features/grading/domain/entities/grading_scale_config.dart';
import 'package:checklist_student/features/grading/domain/entities/score_category.dart';
import 'package:checklist_student/features/grading/domain/entities/student_pin_status.dart';
import 'package:checklist_student/features/grading/domain/entities/student_portal_visibility_config.dart';
import 'package:checklist_student/features/grading/domain/entities/student_score.dart';
import 'package:checklist_student/features/grading/domain/repositories/grading_repository.dart';
import 'package:checklist_student/features/grading/presentation/pages/grading_table_page.dart';
import 'package:checklist_student/features/grading/presentation/providers/grading_providers.dart';
import 'package:checklist_student/features/grading/presentation/providers/student_profile_drawer_controller.dart';
import 'package:checklist_student/features/grading/presentation/widgets/student_profile_drawer.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/class_enrollment.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/homeroom.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/homeroom_student.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/roster_import_result.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/roster_import_row_preview.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/student_lifecycle_status.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/uploaded_import_file.dart';
import 'package:checklist_student/features/homeroom_roster/domain/repositories/homeroom_roster_repository.dart';
import 'package:checklist_student/features/homeroom_roster/domain/services/roster_renumber_service.dart';
import 'package:checklist_student/features/homeroom_roster/domain/services/unlinked_room_sync_service.dart';
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

class _LifecycleState {
  _LifecycleState(this.enrollment, this.pinStatus);
  ClassEnrollment enrollment;
  StudentPinStatus pinStatus;
}

class _FakeSpecialGradeGradingRepo implements GradingRepository {
  _FakeSpecialGradeGradingRepo(this.state);
  final _LifecycleState state;

  @override
  Future<void> updateSpecialGradeStatus({
    required String enrollmentId,
    required int expectedVersion,
    required String? specialGradeOverride,
    required bool markRResolved,
    required bool markMsResolved,
  }) async {
    if (state.enrollment.version != expectedVersion) {
      throw const ConflictException('เวอร์ชันไม่ตรงกัน');
    }
    final old = state.enrollment;
    state.enrollment = ClassEnrollment(
      id: old.id,
      teacherId: old.teacherId,
      subjectClassId: old.subjectClassId,
      homeroomStudentId: old.homeroomStudentId,
      studentIdentityId: old.studentIdentityId,
      studentCode: old.studentCode,
      studentNumber: old.studentNumber,
      prefix: old.prefix,
      firstName: old.firstName,
      lastName: old.lastName,
      status: old.status,
      enrolledAt: old.enrolledAt,
      transferredOutAt: old.transferredOutAt,
      specialGradeOverride: specialGradeOverride,
      wasRResolved: markRResolved ? true : old.wasRResolved,
      wasMsResolved: markMsResolved ? true : old.wasMsResolved,
      resolvedGradeAt: (markRResolved || markMsResolved)
          ? DateTime.utc(2026, 11, 25)
          : old.resolvedGradeAt,
      version: expectedVersion + 1,
      createdAt: old.createdAt,
      updatedAt: DateTime.utc(2026, 11, 25),
    );
  }

  @override
  Future<StudentPinStatus> fetchStudentPinStatus(String id) async =>
      state.pinStatus;

  @override
  Future<StudentPortalVisibilityConfig> fetchStudentPortalVisibility(
    String subjectClassId,
  ) async => StudentPortalVisibilityConfig(
    subjectClassId: subjectClassId,
    showScoreToStudent: true,
    showGradeToStudent: true,
  );

  @override
  Future<StudentPortalVisibilityConfig> updateStudentPortalVisibility(
    StudentPortalVisibilityConfig config,
  ) async => config;

  @override
  Future<void> resetStudentPin(String id) async {
    state.pinStatus = StudentPinStatus(
      studentIdentityId: id,
      hasPin: false,
      failedAttempts: 0,
      lockedUntil: null,
      pinUpdatedAt: null,
    );
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
  Future<List<Assignment>> fetchAssignments(String id) async => <Assignment>[
    Assignment(
      id: 'assign-1',
      teacherId: 'teacher-1',
      subjectClassId: id,
      title: 'งานบังคับส่ง 1',
      maxScore: 20,
      isMandatory: true,
      createdAt: DateTime.utc(2026, 11, 25),
      updatedAt: DateTime.utc(2026, 11, 25),
    ),
  ];
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
      const [];
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
}

class _FakeRosterRepo implements HomeroomRosterRepository {
  _FakeRosterRepo(this.state);
  final _LifecycleState state;

  @override
  Future<List<ClassEnrollment>> fetchClassEnrollments(String id) async =>
      <ClassEnrollment>[state.enrollment];

  @override
  Future<int> setClassEnrollmentStatus({
    required ClassEnrollment existing,
    required StudentLifecycleStatus status,
    DateTime? transferredOutAt,
    required bool syncToHomeroomAndAllClasses,
  }) async {
    state.enrollment = ClassEnrollment(
      id: existing.id,
      teacherId: existing.teacherId,
      subjectClassId: existing.subjectClassId,
      homeroomStudentId: existing.homeroomStudentId,
      studentIdentityId: existing.studentIdentityId,
      studentCode: existing.studentCode,
      studentNumber: existing.studentNumber, // preserved on Soft Delete!
      prefix: existing.prefix,
      firstName: existing.firstName,
      lastName: existing.lastName,
      status: status,
      enrolledAt: existing.enrolledAt,
      transferredOutAt: transferredOutAt,
      specialGradeOverride: existing.specialGradeOverride,
      wasRResolved: existing.wasRResolved,
      wasMsResolved: existing.wasMsResolved,
      resolvedGradeAt: existing.resolvedGradeAt,
      version: existing.version + 1,
      createdAt: existing.createdAt,
      updatedAt: DateTime.utc(2026, 11, 25),
    );
    return 1;
  }

  @override
  Future<List<Homeroom>> fetchHomerooms(String termId) async => const [];
  @override
  Future<Homeroom> createHomeroom({
    required String teacherId,
    required String termId,
    required String name,
  }) => throw UnimplementedError();
  @override
  Future<Homeroom> renameHomeroom({
    required String homeroomId,
    required String name,
  }) => throw UnimplementedError();
  @override
  Future<void> deleteHomeroom(String homeroomId) => throw UnimplementedError();
  @override
  Future<List<HomeroomStudent>> fetchHomeroomStudents(String id) async =>
      const [];
  @override
  Future<HomeroomStudent> addHomeroomStudent({
    required String teacherId,
    required String homeroomId,
    required String studentCode,
    required int studentNumber,
    required String prefix,
    required String firstName,
    required String lastName,
    bool autoEnrollLinkedClasses = false,
    DateTime? enrolledAt,
  }) => throw UnimplementedError();
  @override
  Future<int> updateHomeroomStudent({
    required String homeroomStudentId,
    required String teacherId,
    required String studentCode,
    required int studentNumber,
    required String prefix,
    required String firstName,
    required String lastName,
    required bool syncLinkedClasses,
  }) => throw UnimplementedError();
  @override
  Future<int> setHomeroomStudentStatus({
    required String homeroomStudentId,
    required StudentLifecycleStatus status,
    DateTime? transferredOutAt,
    required bool syncLinkedClasses,
  }) => throw UnimplementedError();
  @override
  Future<int> permanentlyDeleteHomeroomStudent({
    required String homeroomStudentId,
    required bool deleteFromLinkedClasses,
  }) => throw UnimplementedError();
  @override
  Future<int> renumberHomeroomStudents({
    required List<RenumberAssignment> assignments,
    required bool syncLinkedClasses,
  }) => throw UnimplementedError();
  @override
  Future<RosterImportResult> importHomeroomStudents({
    required String teacherId,
    required String homeroomId,
    required List<RosterImportRowPreview> rows,
    required bool syncOverwrittenToLinkedClasses,
    bool autoEnrollNewToLinkedClasses = false,
    DateTime? enrolledAt,
  }) => throw UnimplementedError();
  @override
  Future<UploadedImportFileResult> uploadAndParseRosterWithAi({
    required String teacherId,
    required String academicYearId,
    required String homeroomId,
    required String originalFilename,
    required Uint8List compressedBytes,
    required String mimeType,
    required String fileExtension,
  }) => throw UnimplementedError();
  @override
  Future<Homeroom?> syncUnlinkedRoomGroups({
    required String teacherId,
    required String termId,
    required List<UnlinkedRoomGroup> groups,
    required DateTime enrolledAt,
  }) => throw UnimplementedError();
  @override
  Future<int> linkHomeroomToSubjectClasses({
    required String teacherId,
    required String homeroomId,
    required List<String> subjectClassIds,
    required DateTime enrolledAt,
  }) => throw UnimplementedError();
  @override
  Future<ClassEnrollment> addClassEnrollmentMidTerm({
    required String teacherId,
    required String subjectClassId,
    String? addToHomeroomId,
    required String studentCode,
    required int studentNumber,
    required String prefix,
    required String firstName,
    required String lastName,
    required DateTime enrolledAt,
  }) => throw UnimplementedError();
  @override
  Future<int> updateClassEnrollment({
    required ClassEnrollment existing,
    required String studentCode,
    required int studentNumber,
    required String prefix,
    required String firstName,
    required String lastName,
    required DateTime enrolledAt,
    required bool syncToHomeroomAndAllClasses,
  }) => throw UnimplementedError();
  @override
  Future<void> permanentlyDeleteClassEnrollment({
    required String enrollmentId,
    String? homeroomStudentId,
    required bool alsoDeleteFromHomeroom,
  }) => throw UnimplementedError();
  @override
  Future<void> renumberClassEnrollments({
    required List<ClassEnrollment> currentEnrollments,
    required List<RenumberAssignment> assignments,
  }) => throw UnimplementedError();
}

void main() {
  final now = DateTime.utc(2026, 11, 25);

  _LifecycleState createInitialState() {
    return _LifecycleState(
      ClassEnrollment(
        id: 'enr-1',
        teacherId: 'teacher-1',
        subjectClassId: 'class-1',
        homeroomStudentId: null,
        studentIdentityId: 'ident-1',
        studentCode: '67001',
        studentNumber: 7,
        prefix: 'ด.ช.',
        firstName: 'สมชาย',
        lastName: 'ใจดี',
        status: StudentLifecycleStatus.active,
        enrolledAt: DateTime(2026, 5, 16),
        transferredOutAt: null,
        specialGradeOverride: null,
        wasRResolved: false,
        wasMsResolved: false,
        resolvedGradeAt: null,
        version: 1,
        createdAt: now,
        updatedAt: now,
      ),
      StudentPinStatus(
        studentIdentityId: 'ident-1',
        hasPin: true,
        failedAttempts: 3,
        lockedUntil: now.add(const Duration(minutes: 15)),
        pinUpdatedAt: now,
      ),
    );
  }

  group('Phase 4 QA Gate — Special Grade & Drawer E2E Flows (UC-016, UC-017)', () {
    test(
      'UC-016 & UC-017: full ร lifecycle (confirm -> resolve), PIN reset without exposing hash, and Soft Delete preserves studentNumber',
      () async {
        // Verify StudentPinStatusDto NEVER exposes raw pin_hash
        final dto = StudentPinStatusDto.fromJson(<String, dynamic>{
          'id': 'ident-1',
          'pin_hash': r'$2a$06$super_secret_bcrypt_hash_value',
          'failed_attempts': 2,
          'locked_until': null,
          'pin_updated_at': now.toIso8601String(),
        });
        final entity = dto.toEntity();
        expect(entity.hasPin, isTrue);
        expect(entity.failedAttempts, 2);

        final state = createInitialState();
        final gradingRepo = _FakeSpecialGradeGradingRepo(state);
        final rosterRepo = _FakeRosterRepo(state);

        final container = ProviderContainer(
          overrides: [
            gradingRepositoryProvider.overrideWithValue(gradingRepo),
            homeroomRosterRepositoryProvider.overrideWithValue(rosterRepo),
          ],
        );
        addTearDown(container.dispose);

        final ctrl = container.read(
          studentProfileDrawerControllerProvider.notifier,
        );

        // Step 1: Confirm ร (version 1 -> 2)
        final confirmed = await ctrl.updateSpecialGrade(
          subjectClassId: 'class-1',
          enrollmentId: 'enr-1',
          expectedVersion: 1,
          specialGradeOverride: 'ร',
          markRResolved: false,
          markMsResolved: false,
        );
        expect(confirmed, isTrue);
        expect(state.enrollment.specialGradeOverride, 'ร');
        expect(state.enrollment.version, 2);

        // Step 2: Resolve ร (version 2 -> 3, override=null, wasRResolved=true)
        final resolved = await ctrl.updateSpecialGrade(
          subjectClassId: 'class-1',
          enrollmentId: 'enr-1',
          expectedVersion: 2,
          specialGradeOverride: null,
          markRResolved: true,
          markMsResolved: false,
        );
        expect(resolved, isTrue);
        expect(state.enrollment.specialGradeOverride, isNull);
        expect(state.enrollment.wasRResolved, isTrue);
        expect(state.enrollment.resolvedGradeAt, isNotNull);
        expect(state.enrollment.version, 3);

        // Step 3: Reset PIN clears hasPin & lock
        final pinResetOk = await ctrl.resetStudentPin('ident-1');
        expect(pinResetOk, isTrue);
        expect(state.pinStatus.hasPin, isFalse);
        expect(state.pinStatus.failedAttempts, 0);
        expect(state.pinStatus.lockedUntil, isNull);

        // Step 4: Soft Delete preserves studentNumber #7
        final transferOk = await ctrl.updateTransferStatus(
          enrollment: state.enrollment,
          nextStatus: StudentLifecycleStatus.transferredOut,
          syncToHomeroomAndAllClasses: false,
        );
        expect(transferOk, isTrue);
        expect(state.enrollment.isTransferredOut, isTrue);
        expect(state.enrollment.studentNumber, 7);
      },
    );

    testWidgets(
      'UC-017 Page Safety Guard: tapping row/name in GradingTablePage never opens Drawer; trailing icon opens StudentProfileDrawer',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final state = createInitialState();
        final gradingRepo = _FakeSpecialGradeGradingRepo(state);
        final rosterRepo = _FakeRosterRepo(state);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(_FakeAuthNotifier.new),
              gradingRepositoryProvider.overrideWithValue(gradingRepo),
              homeroomRosterRepositoryProvider.overrideWithValue(rosterRepo),
              allCopyableClassesProvider.overrideWith(
                (ref) async => const <CopyPlanSourceClassOption>[
                  CopyPlanSourceClassOption(
                    subjectClassId: 'class-1',
                    academicYearBe: 2569,
                    termId: 't-1',
                    termLabel: '1',
                    subjectCode: 'ค31101',
                    subjectName: 'คณิตศาสตร์',
                    roomName: 'ม.4/1',
                  ),
                ],
              ),
              classAttendanceSummariesProvider('class-1').overrideWithValue(
                const <String, StudentAttendanceSummary>{},
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const GradingTablePage(initialClassId: 'class-1'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap name & student code -> Drawer MUST NOT open
        await tester.tap(find.text('ด.ช.สมชาย ใจดี'));
        await tester.pumpAndSettle();
        expect(find.byType(StudentProfileDrawer), findsNothing);

        // Tap trailing icon button -> Drawer opens cleanly
        await tester.tap(find.byKey(const ValueKey<String>('open_profile_enr-1')));
        await tester.pumpAndSettle();
        expect(find.byType(StudentProfileDrawer), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(StudentProfileDrawer),
            matching: find.text('งานบังคับส่ง 1'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
