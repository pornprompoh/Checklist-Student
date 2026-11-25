import 'package:checklist_student/core/constants/attendance_status.dart';
import 'package:checklist_student/core/constants/submission_status.dart';
import 'package:checklist_student/core/network/connectivity_provider.dart';
import 'package:checklist_student/features/academic_structure/domain/entities/academic_year.dart';
import 'package:checklist_student/features/academic_structure/domain/entities/subject.dart';
import 'package:checklist_student/features/academic_structure/domain/entities/subject_class.dart';
import 'package:checklist_student/features/academic_structure/domain/entities/term.dart';
import 'package:checklist_student/features/academic_structure/domain/repositories/academic_structure_repository.dart';
import 'package:checklist_student/features/academic_structure/presentation/providers/academic_structure_providers.dart';
import 'package:checklist_student/features/attendance/domain/entities/attendance_record.dart';
import 'package:checklist_student/features/attendance/domain/entities/attendance_rule_config.dart';
import 'package:checklist_student/features/attendance/domain/entities/attendance_session.dart';
import 'package:checklist_student/features/attendance/domain/entities/student_attendance_summary.dart';
import 'package:checklist_student/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:checklist_student/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:checklist_student/features/audit_log/domain/entities/audit_log_target_type.dart';
import 'package:checklist_student/features/audit_log/domain/entities/audit_log_year_summary.dart';
import 'package:checklist_student/features/audit_log/domain/entities/score_audit_log_entry.dart';
import 'package:checklist_student/features/audit_log/presentation/providers/audit_log_providers.dart';
import 'package:checklist_student/features/auth/domain/entities/auth_state.dart';
import 'package:checklist_student/features/auth/domain/entities/teacher_feature_flags.dart';
import 'package:checklist_student/features/auth/domain/entities/teacher_profile.dart';
import 'package:checklist_student/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:checklist_student/features/dashboard/domain/entities/dashboard_class_item.dart';
import 'package:checklist_student/features/dashboard/domain/entities/dashboard_overview.dart';
import 'package:checklist_student/features/dashboard/domain/entities/today_attendance_summary.dart';
import 'package:checklist_student/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:checklist_student/features/export_reports/domain/entities/export_report_bundle.dart';
import 'package:checklist_student/features/export_reports/presentation/providers/export_reports_providers.dart';
import 'package:checklist_student/features/grading/domain/entities/assignment.dart';
import 'package:checklist_student/features/grading/domain/entities/grade_result.dart';
import 'package:checklist_student/features/grading/domain/entities/grading_scale_config.dart'
    hide GradingRuleTier;
import 'package:checklist_student/features/grading/domain/entities/score_category.dart';
import 'package:checklist_student/features/grading/domain/entities/student_pin_status.dart';
import 'package:checklist_student/features/grading/domain/entities/student_score.dart';
import 'package:checklist_student/features/grading/presentation/providers/grading_filter_provider.dart';
import 'package:checklist_student/features/grading/presentation/providers/grading_providers.dart';
import 'package:checklist_student/features/grading/presentation/providers/student_profile_drawer_controller.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/class_enrollment.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/homeroom.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/homeroom_student.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/student_lifecycle_status.dart';
import 'package:checklist_student/features/homeroom_roster/presentation/providers/homeroom_roster_providers.dart';
import 'package:checklist_student/features/settings/domain/entities/import_file_record.dart';
import 'package:checklist_student/features/settings/domain/entities/teacher_code_history_entry.dart';
import 'package:checklist_student/features/settings/presentation/providers/settings_providers.dart';
import 'package:checklist_student/features/sync_queue/domain/entities/sync_entity_type.dart';
import 'package:checklist_student/features/sync_queue/domain/entities/sync_item_status.dart';
import 'package:checklist_student/features/sync_queue/domain/entities/sync_operation_type.dart';
import 'package:checklist_student/features/sync_queue/domain/entities/sync_queue_item.dart';
import 'package:checklist_student/features/sync_queue/presentation/providers/sync_queue_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';

/// Named viewport entry for the 6-Viewport Stress Matrix.
class StressViewport {
  const StressViewport(this.label, this.size);

  final String label;
  final Size size;
}

/// 6-Viewport Stress Matrix covering extra-narrow mobile, standard mobile,
/// short split-screen / DevTools docked, desktop breakpoint boundary, and desktop.
const List<StressViewport> kStressViewports = <StressViewport>[
  StressViewport('320x568 Extra-narrow Mobile', Size(320, 568)),
  StressViewport('390x844 Standard Mobile', Size(390, 844)),
  StressViewport('640x460 Short Split-Screen', Size(640, 460)),
  StressViewport('899x520 Pre-Desktop Short', Size(899, 520)),
  StressViewport('900x520 Desktop Breakpoint Short', Size(900, 520)),
  StressViewport('1280x800 Standard Desktop', Size(1280, 800)),
];

class FakeStressAuthNotifier extends AuthStateNotifier {
  FakeStressAuthNotifier(this._state);
  final AuthSessionState _state;

  @override
  AuthSessionState build() => _state;
}

class FakeStressAcademicRepo implements AcademicStructureRepository {
  FakeStressAcademicRepo(this.fixtures);
  final ResponsiveTestFixtures fixtures;

  @override
  Future<List<AcademicYear>> fetchAcademicYears() async => fixtures.years;

  @override
  Future<List<Term>> fetchTerms({String? academicYearId}) async =>
      fixtures.terms;

  @override
  Future<List<Subject>> fetchSubjects(String termId) async => fixtures.subjects;

  @override
  Future<List<SubjectClass>> fetchSubjectClassesByTerm(String termId) async =>
      fixtures.classes;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStressAttendanceRepo implements AttendanceRepository {
  FakeStressAttendanceRepo(this.fixtures);
  final ResponsiveTestFixtures fixtures;

  @override
  Future<List<AttendanceSession>> fetchSessions(String subjectClassId) async =>
      fixtures.sessions;

  @override
  Future<AttendanceSession?> fetchSessionByDate({
    required String subjectClassId,
    required DateTime sessionDate,
  }) async => fixtures.sessions.first;

  @override
  Future<List<AttendanceRecord>> fetchRecordsBySession(
    String sessionId,
  ) async => fixtures.attendanceRecords;

  @override
  Future<List<AttendanceRecord>> fetchRecordsByClass(
    String subjectClassId,
  ) async => fixtures.attendanceRecords;

  @override
  Future<AttendanceRuleConfig> fetchRuleConfig(String subjectClassId) async =>
      fixtures.attendanceRuleConfig;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Realistic long Thai fixtures for stress-testing responsive layouts across
/// all pages, banners, drawers, and dialogs.
class ResponsiveTestFixtures {
  ResponsiveTestFixtures() {
    final now = DateTime(2026, 11, 25, 10, 30);
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(2026, 5, 16);

    profile = TeacherProfile(
      id: 'teacher-1',
      email: 'somchai.kru@school-example.ac.th',
      displayName: 'ครูสมชาย ประเสริฐศรีวิทยา',
      schoolName: 'โรงเรียนมัธยมสาธิตตัวอย่างเฉลิมพระเกียรติ',
      department: 'กลุ่มสาระการเรียนรู้วิทยาศาสตร์และเทคโนโลยี',
      teacherCode: 't-8492',
      defaultAbsentThresholdPct: 20.0,
      defaultMissingWorkThreshold: 3,
      createdAt: start,
      updatedAt: now,
    );
    authState = AuthSessionState.authenticated(
      userId: 'teacher-1',
      profile: profile,
      featureFlags: TeacherFeatureFlags(
        teacherId: 'teacher-1',
        canUseAi: true,
        updatedAt: now,
      ),
    );

    years = <AcademicYear>[
      AcademicYear(
        id: 'y-2569',
        teacherId: 'teacher-1',
        yearBe: 2569,
        createdAt: start,
        updatedAt: now,
      ),
      AcademicYear(
        id: 'y-2567',
        teacherId: 'teacher-1',
        yearBe: 2567,
        createdAt: DateTime(2024, 5, 1),
        updatedAt: DateTime(2025, 3, 30),
      ),
    ];

    terms = <Term>[
      Term(
        id: 'term-1',
        teacherId: 'teacher-1',
        academicYearId: 'y-2569',
        termLabel: '1',
        startDate: start,
        endDate: DateTime(2026, 10, 10),
        isPinnedActive: true,
        createdAt: start,
        updatedAt: now,
      ),
    ];

    subjects = <Subject>[
      Subject(
        id: 'sub-1',
        teacherId: 'teacher-1',
        termId: 'term-1',
        subjectCode: 'ว31101',
        subjectName: 'วิทยาการคำนวณและการออกแบบเทคโนโลยี 1',
        createdAt: start,
        updatedAt: now,
      ),
    ];

    classes = <SubjectClass>[
      SubjectClass(
        id: 'class-1',
        teacherId: 'teacher-1',
        subjectId: 'sub-1',
        homeroomId: 'hr-1',
        roomName: 'ม.4/1 ห้องเรียนพิเศษวิทย์-คณิต',
        teachingDays: const <int>[1, 2, 3, 4, 5],
        isPinned: true,
        showScoreToStudent: true,
        showGradeToStudent: true,
        absentThresholdPct: 20,
        missingWorkThreshold: 3,
        lateToAbsentRatio: 3,
        countLeaveAsAbsent: false,
        attendanceScoreWeight: 10,
        gradingScaleType: '0-4',
        gradingRules: const <GradingRuleTier>[],
        createdAt: start,
        updatedAt: now,
      ),
      SubjectClass(
        id: 'class-2',
        teacherId: 'teacher-1',
        subjectId: 'sub-1',
        homeroomId: null,
        roomName: 'ม.4/2',
        teachingDays: const <int>[2, 4],
        isPinned: false,
        showScoreToStudent: true,
        showGradeToStudent: true,
        absentThresholdPct: 20,
        missingWorkThreshold: 3,
        lateToAbsentRatio: null,
        countLeaveAsAbsent: false,
        attendanceScoreWeight: null,
        gradingScaleType: '0-4',
        gradingRules: const <GradingRuleTier>[],
        createdAt: start,
        updatedAt: now,
      ),
    ];

    copyableClasses = <CopyPlanSourceClassOption>[
      const CopyPlanSourceClassOption(
        subjectClassId: 'class-1',
        academicYearBe: 2569,
        termId: 'term-1',
        termLabel: '1',
        subjectCode: 'ว31101',
        subjectName: 'วิทยาการคำนวณและการออกแบบเทคโนโลยี 1',
        roomName: 'ม.4/1 ห้องเรียนพิเศษวิทย์-คณิต',
      ),
      const CopyPlanSourceClassOption(
        subjectClassId: 'class-2',
        academicYearBe: 2569,
        termId: 'term-1',
        termLabel: '1',
        subjectCode: 'ว31101',
        subjectName: 'วิทยาการคำนวณและการออกแบบเทคโนโลยี 1',
        roomName: 'ม.4/2',
      ),
    ];

    dashboardOverview = DashboardOverview(
      termId: 'term-1',
      referenceDate: today,
      classes: <DashboardClassItem>[
        DashboardClassItem(
          subjectClassId: 'class-1',
          subjectId: 'sub-1',
          subjectCode: 'ว31101',
          subjectName: 'วิทยาการคำนวณและการออกแบบเทคโนโลยี 1',
          roomName: 'ม.4/1 ห้องเรียนพิเศษวิทย์-คณิต',
          teachingDays: const <int>[1, 2, 3, 4, 5],
          isPinned: true,
          activeStudentCount: 38,
          todayAttendance: const TodayAttendanceSummary(
            sessionId: 'sess-1',
            isLocked: true,
            presentCount: 34,
            lateCount: 2,
            leaveCount: 1,
            absentCount: 1,
          ),
        ),
        const DashboardClassItem(
          subjectClassId: 'class-2',
          subjectId: 'sub-1',
          subjectCode: 'ว31101',
          subjectName: 'วิทยาการคำนวณและการออกแบบเทคโนโลยี 1',
          roomName: 'ม.4/2',
          teachingDays: <int>[2, 4],
          isPinned: false,
          activeStudentCount: 0,
          todayAttendance: null,
        ),
      ],
    );

    homerooms = <Homeroom>[
      Homeroom(
        id: 'hr-1',
        teacherId: 'teacher-1',
        termId: 'term-1',
        name: 'ม.4/1 ห้องเรียนพิเศษวิทย์-คณิต',
        createdAt: start,
        updatedAt: now,
      ),
    ];

    homeroomStudents = List<HomeroomStudent>.generate(
      6,
      (i) => HomeroomStudent(
        id: 'hs-${i + 1}',
        teacherId: 'teacher-1',
        homeroomId: 'hr-1',
        studentIdentityId: 'sid-${i + 1}',
        studentCode: '6700${i + 1}',
        studentNumber: i + 1,
        prefix: i.isEven ? 'นาย' : 'นางสาว',
        firstName: 'กิตติพงศ์วัฒนากูล${i + 1}',
        lastName: 'รัตนประเสริฐศักดิ์',
        status: StudentLifecycleStatus.active,
        transferredOutAt: null,
        createdAt: start,
        updatedAt: now,
      ),
    );

    enrollments = List<ClassEnrollment>.generate(
      6,
      (i) => ClassEnrollment(
        id: 'enr-${i + 1}',
        teacherId: 'teacher-1',
        subjectClassId: 'class-1',
        homeroomStudentId: 'hs-${i + 1}',
        studentIdentityId: 'sid-${i + 1}',
        studentCode: '6700${i + 1}',
        studentNumber: i + 1,
        prefix: i.isEven ? 'นาย' : 'นางสาว',
        firstName: 'กิตติพงศ์วัฒนากูล${i + 1}',
        lastName: 'รัตนประเสริฐศักดิ์',
        status: i == 5
            ? StudentLifecycleStatus.transferredOut
            : StudentLifecycleStatus.active,
        enrolledAt: start,
        transferredOutAt: i == 5 ? today : null,
        specialGradeOverride: i == 0 ? 'ร' : null,
        wasRResolved: i == 1,
        wasMsResolved: false,
        resolvedGradeAt: i == 1 ? now : null,
        version: 1,
        createdAt: start,
        updatedAt: now,
      ),
    );

    attendanceRuleConfig = const AttendanceRuleConfig(
      subjectClassId: 'class-1',
      absentThresholdPct: 20.0,
      lateToAbsentRatio: 3,
      countLeaveAsAbsent: false,
      attendanceScoreWeight: 10,
    );

    sessions = <AttendanceSession>[
      AttendanceSession(
        id: 'sess-1',
        teacherId: 'teacher-1',
        subjectClassId: 'class-1',
        sessionDate: today,
        isLocked: false,
        note: 'คาบเรียนปฏิบัติการทดลอง',
        version: 1,
        createdAt: today,
        updatedAt: today,
      ),
    ];

    attendanceRecords = <AttendanceRecord>[
      for (final e in enrollments)
        AttendanceRecord(
          id: 'rec-${e.id}',
          teacherId: 'teacher-1',
          sessionId: 'sess-1',
          enrollmentId: e.id,
          status: e.studentNumber == 2
              ? AttendanceStatus.absent
              : AttendanceStatus.present,
          note: e.studentNumber == 2 ? 'ลาป่วยมีใบรับรองแพทย์' : '',
          version: 1,
          updatedAt: today,
        ),
    ];

    scoreCategories = <ScoreCategory>[
      ScoreCategory(
        id: 'cat-1',
        teacherId: 'teacher-1',
        subjectClassId: 'class-1',
        name: 'คะแนนเก็บระหว่างภาคเรียน (งานปฏิบัติการ)',
        targetMaxScore: 50,
        sortOrder: 0,
        createdAt: start,
        updatedAt: now,
      ),
      ScoreCategory(
        id: 'cat-2',
        teacherId: 'teacher-1',
        subjectClassId: 'class-1',
        name: 'สอบกลางภาคและสอบปลายภาค',
        targetMaxScore: 50,
        sortOrder: 1,
        createdAt: start,
        updatedAt: now,
      ),
    ];

    assignments = <Assignment>[
      Assignment(
        id: 'asg-1',
        teacherId: 'teacher-1',
        subjectClassId: 'class-1',
        categoryId: 'cat-1',
        title: 'ใบงานที่ 1 การวิเคราะห์ขั้นตอนวิธีและอัลกอริทึม',
        maxScore: 20,
        isMandatory: true,
        dueDate: today,
        sortOrder: 0,
        createdAt: start,
        updatedAt: now,
      ),
      Assignment(
        id: 'asg-2',
        teacherId: 'teacher-1',
        subjectClassId: 'class-1',
        categoryId: 'cat-2',
        title: 'สอบกลางภาคเรียนที่ 1',
        maxScore: 30,
        isMandatory: true,
        dueDate: today,
        sortOrder: 1,
        createdAt: start,
        updatedAt: now,
      ),
    ];

    studentScores = <StudentScore>[
      StudentScore(
        id: 'sc-1',
        teacherId: 'teacher-1',
        assignmentId: 'asg-1',
        enrollmentId: 'enr-1',
        submissionStatus: SubmissionStatus.submitted,
        score: 18.75,
        note: 'ส่งครบเรียบร้อย',
        version: 1,
        updatedAt: now,
      ),
      StudentScore(
        id: 'sc-2',
        teacherId: 'teacher-1',
        assignmentId: 'asg-1',
        enrollmentId: 'enr-2',
        submissionStatus: SubmissionStatus.missing,
        score: null,
        note: 'ค้างส่งงาน',
        version: 1,
        updatedAt: now,
      ),
    ];

    gradingScaleConfig = const GradingScaleConfig(
      subjectClassId: 'class-1',
      scaleType: GradingScaleType.scale0To4,
      rules: GradingScaleConfig.defaultZeroToFourRules,
      missingWorkThreshold: 3,
    );

    auditLogEntries = <ScoreAuditLogEntry>[
      ScoreAuditLogEntry(
        id: 'log-1',
        teacherId: 'teacher-1',
        academicYearId: 'y-2569',
        targetType: AuditLogTargetType.score,
        studentScoreId: 'sc-1',
        enrollmentId: 'enr-1',
        oldValue: '15.0',
        newValue: '18.75',
        isInitialEntry: false,
        changedAt: now,
        yearBe: 2569,
        subjectClassId: 'class-1',
        subjectCode: 'ว31101',
        subjectName: 'วิทยาการคำนวณและการออกแบบเทคโนโลยี 1',
        roomName: 'ม.4/1 ห้องเรียนพิเศษวิทย์-คณิต',
        studentNumber: 1,
        studentCode: '67001',
        studentFullName: 'นายกิตติพงศ์วัฒนากูล1 รัตนประเสริฐศักดิ์',
        assignmentTitle: 'ใบงานที่ 1 การวิเคราะห์ขั้นตอนวิธีและอัลกอริทึม',
      ),
      ScoreAuditLogEntry(
        id: 'log-2',
        teacherId: 'teacher-1',
        academicYearId: 'y-2569',
        targetType: AuditLogTargetType.gradeStatus,
        enrollmentId: 'enr-1',
        oldValue: 'เกรดปกติ',
        newValue: 'ร',
        isInitialEntry: false,
        changedAt: now,
        yearBe: 2569,
        subjectClassId: 'class-1',
        subjectCode: 'ว31101',
        subjectName: 'วิทยาการคำนวณและการออกแบบเทคโนโลยี 1',
        roomName: 'ม.4/1 ห้องเรียนพิเศษวิทย์-คณิต',
        studentNumber: 1,
        studentCode: '67001',
        studentFullName: 'นายกิตติพงศ์วัฒนากูล1 รัตนประเสริฐศักดิ์',
      ),
    ];

    auditLogSummaries = <AuditLogYearSummary>[
      AuditLogYearSummary(
        academicYearId: 'y-2567',
        yearBe: 2567,
        totalLogsCount: 1520,
        scoreLogsCount: 1400,
        gradeStatusLogsCount: 120,
        oldestChangedAt: DateTime(2024, 5, 20),
        newestChangedAt: DateTime(2025, 3, 15),
      ),
    ];

    syncQueueItems = <SyncQueueItem>[
      SyncQueueItem(
        id: 'sync-conflict-1',
        teacherId: 'teacher-1',
        entityType: SyncEntityType.studentScore,
        entityId: 'sc-1',
        displayLabel: 'คะแนน นายกิตติพงศ์วัฒนากูล1 — ใบงานที่ 1 การวิเคราะห์ขั้นตอนวิธี',
        operation: SyncOperationType.update,
        payload: const <String, dynamic>{
          'submission_status': 'submitted',
          'score': 18.75,
          'note': 'บันทึกออฟไลน์จากแท็บเล็ตในห้องเรียน',
        },
        expectedVersion: 1,
        status: SyncItemStatus.conflict,
        retryCount: 0,
        nextRetryAt: null,
        lastError: 'พบการแก้ไขจากเครื่องอื่น (version ไม่ตรงกัน)',
        serverSnapshot: const <String, dynamic>{
          'submission_status': 'submitted',
          'score': 19.5,
          'note': 'แก้ไขล่าสุดบนคอมพิวเตอร์ห้องพักครู',
          'version': 3,
        },
        createdAt: now,
        updatedAt: now,
      ),
      SyncQueueItem(
        id: 'sync-pending-1',
        teacherId: 'teacher-1',
        entityType: SyncEntityType.attendanceSession,
        entityId: 'sess-1',
        displayLabel: 'เช็คชื่อ ม.4/1 ห้องเรียนพิเศษวิทย์-คณิต วันที่ 25 พ.ย. 2569',
        operation: SyncOperationType.create,
        payload: const <String, dynamic>{'is_locked': true},
        expectedVersion: 1,
        status: SyncItemStatus.pending,
        retryCount: 0,
        nextRetryAt: null,
        lastError: null,
        serverSnapshot: null,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    exportRawClassData = ExportRawClassData(
      subjectClassId: 'class-1',
      enrollments: enrollments,
      attendanceSessions: sessions,
      attendanceRecords: attendanceRecords,
      attendanceRuleConfig: attendanceRuleConfig,
      scoreCategories: scoreCategories,
      assignments: assignments,
      studentScores: studentScores,
      gradingScaleConfig: gradingScaleConfig,
    );

    drawerRowData = GradingTableRowData(
      enrollment: enrollments.first,
      gradeResult: GradeResult(
        enrollmentId: enrollments.first.id,
        totalScore: 79.75,
        totalMaxScore: 100.0,
        percentage: 79.75,
        categorySummaries: const <CategoryScoreSummary>[],
        missingAssignmentsCount: 1,
        missingMandatoryCount: 1,
        overMaxAssignmentIds: const <String>[],
        evaluatedGrade: '3.5',
        specialGradeOverride: null,
        displayedGrade: '3.5',
        specialGradeAdvice: const SpecialGradeAdvice(
          recommendR: true,
          recommendMs: true,
          primaryRecommendedCode: 'มส',
          reasons: <String>[
            'ขาดเรียนเกินเกณฑ์ มส (25.0% >= 20.0%)',
            'ค้างส่งงานบังคับ 1 ชิ้น (ใบงานที่ 1)',
          ],
          assessedAssignmentsCount: 2,
          totalAssignmentsCount: 2,
        ),
        wasRResolved: true,
        wasMsResolved: false,
        resolvedGradeAt: now,
      ),
      attendanceSummary: const StudentAttendanceSummary(
        enrollmentId: 'enr-1',
        totalEligibleSessions: 20,
        recordedSessions: 20,
        presentCount: 14,
        lateCount: 1,
        leaveCount: 0,
        absentCount: 5,
        convertedLateAbsentCount: 0,
        countedLeaveAbsentCount: 0,
        effectiveAbsentCount: 5,
        absentPercentage: 25.0,
        riskLevel: AttendanceRiskLevel.exceededMs,
      ),
    );

    codeHistory = <TeacherCodeHistoryEntry>[
      TeacherCodeHistoryEntry(
        oldCode: 't-1001',
        teacherId: 'teacher-1',
        changedAt: start,
      ),
    ];

    importFiles = <ImportFileRecord>[
      ImportFileRecord(
        id: 'imp-1',
        teacherId: 'teacher-1',
        academicYearId: 'y-2567',
        academicYearBe: 2567,
        storagePath: 'teacher-1/2567/roster-m4-1.pdf',
        originalFilename: 'รายชื่อนักเรียน_ม4-1_ปี2567.pdf',
        mimeType: 'application/pdf',
        fileSizeBytes: 512000,
        createdAt: DateTime(2024, 5, 16),
      ),
    ];
  }

  late final TeacherProfile profile;
  late final AuthSessionState authState;
  late final List<AcademicYear> years;
  late final List<Term> terms;
  late final List<Subject> subjects;
  late final List<SubjectClass> classes;
  late final List<CopyPlanSourceClassOption> copyableClasses;
  late final DashboardOverview dashboardOverview;
  late final List<Homeroom> homerooms;
  late final List<HomeroomStudent> homeroomStudents;
  late final List<ClassEnrollment> enrollments;
  late final AttendanceRuleConfig attendanceRuleConfig;
  late final List<AttendanceSession> sessions;
  late final List<AttendanceRecord> attendanceRecords;
  late final List<ScoreCategory> scoreCategories;
  late final List<Assignment> assignments;
  late final List<StudentScore> studentScores;
  late final GradingScaleConfig gradingScaleConfig;
  late final List<ScoreAuditLogEntry> auditLogEntries;
  late final List<AuditLogYearSummary> auditLogSummaries;
  late final List<SyncQueueItem> syncQueueItems;
  late final ExportRawClassData exportRawClassData;
  late final GradingTableRowData drawerRowData;
  late final List<TeacherCodeHistoryEntry> codeHistory;
  late final List<ImportFileRecord> importFiles;

  List<Override> buildOverrides({bool isOnline = true}) {
    final academicRepo = FakeStressAcademicRepo(this);
    final attendanceRepo = FakeStressAttendanceRepo(this);
    return <Override>[
      connectivityStatusProvider.overrideWith((ref) => Stream.value(isOnline)),
      authStateProvider.overrideWith(() => FakeStressAuthNotifier(authState)),
      syncQueueItemsStreamProvider.overrideWith(
        (ref) => Stream.value(syncQueueItems),
      ),
      academicStructureRepositoryProvider.overrideWithValue(academicRepo),
      academicYearsProvider.overrideWith((ref) async => years),
      allTermsProvider.overrideWith((ref) async => terms),
      subjectsByTermProvider('term-1').overrideWith((ref) async => subjects),
      subjectClassesByTermProvider(
        'term-1',
      ).overrideWith((ref) async => classes),
      allCopyableClassesProvider.overrideWith((ref) async => copyableClasses),
      dashboardOverviewProvider.overrideWith((ref) async => dashboardOverview),
      homeroomsByTermProvider('term-1').overrideWith((ref) async => homerooms),
      homeroomStudentsProvider(
        'hr-1',
      ).overrideWith((ref) async => homeroomStudents),
      classEnrollmentsProvider(
        'class-1',
      ).overrideWith((ref) async => enrollments),
      attendanceRepositoryProvider.overrideWithValue(attendanceRepo),
      scoreCategoriesProvider(
        'class-1',
      ).overrideWith((ref) async => scoreCategories),
      assignmentsProvider('class-1').overrideWith((ref) async => assignments),
      studentScoresByClassProvider(
        'class-1',
      ).overrideWith((ref) async => studentScores),
      gradingScaleConfigProvider(
        'class-1',
      ).overrideWith((ref) async => gradingScaleConfig),
      classPlanSummaryProvider('class-2').overrideWith(
        (ref) async => const CopyPlanSourcePreview(
          categoryCount: 2,
          assignmentCount: 5,
          gradingScaleType: GradingScaleType.scale0To4,
        ),
      ),
      studentPinStatusProvider('sid-1').overrideWith(
        (ref) async => StudentPinStatus(
          studentIdentityId: 'sid-1',
          hasPin: true,
          failedAttempts: 0,
          pinUpdatedAt: DateTime(2026, 11, 25),
        ),
      ),
      auditLogEntriesProvider.overrideWith((ref) async => auditLogEntries),
      auditLogYearSummariesProvider.overrideWith(
        (ref) async => auditLogSummaries,
      ),
      exportRawClassDataProvider(
        'class-1',
      ).overrideWith((ref) async => exportRawClassData),
      teacherCodeHistoryProvider.overrideWith((ref) async => codeHistory),
      activeImportFilesProvider.overrideWith((ref) async => importFiles),
    ];
  }
}
