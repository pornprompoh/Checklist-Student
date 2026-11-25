import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/core/constants/attendance_status.dart';
import 'package:checklist_student/core/constants/submission_status.dart';
import 'package:checklist_student/features/attendance/domain/entities/attendance_record.dart';
import 'package:checklist_student/features/attendance/domain/entities/attendance_rule_config.dart';
import 'package:checklist_student/features/attendance/domain/entities/attendance_session.dart';
import 'package:checklist_student/features/export_reports/domain/entities/export_document_header.dart';
import 'package:checklist_student/features/export_reports/domain/entities/export_options.dart';
import 'package:checklist_student/features/export_reports/domain/entities/export_orientation.dart';
import 'package:checklist_student/features/export_reports/domain/entities/export_report_bundle.dart';
import 'package:checklist_student/features/export_reports/domain/entities/export_section.dart';
import 'package:checklist_student/features/export_reports/domain/services/export_report_builder_service.dart';
import 'package:checklist_student/features/grading/domain/entities/assignment.dart';
import 'package:checklist_student/features/grading/domain/entities/grading_scale_config.dart';
import 'package:checklist_student/features/grading/domain/entities/score_category.dart';
import 'package:checklist_student/features/grading/domain/entities/student_score.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/class_enrollment.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/student_lifecycle_status.dart';

void main() {
  const builder = ExportReportBuilderService();
  final now = DateTime.utc(2026, 11, 25);

  ClassEnrollment makeStudent({
    required String id,
    required int number,
    required String code,
    required String firstName,
    StudentLifecycleStatus status = StudentLifecycleStatus.active,
    String? specialGradeOverride,
  }) {
    return ClassEnrollment(
      id: id,
      teacherId: 'teacher-1',
      subjectClassId: 'class-1',
      homeroomStudentId: null,
      studentIdentityId: 'ident-$id',
      studentCode: code,
      studentNumber: number,
      prefix: 'ด.ช.',
      firstName: firstName,
      lastName: 'ทดสอบ',
      status: status,
      enrolledAt: DateTime(2026, 5, 16),
      transferredOutAt: status == StudentLifecycleStatus.transferredOut
          ? DateTime(2026, 8, 1)
          : null,
      specialGradeOverride: specialGradeOverride,
      wasRResolved: false,
      wasMsResolved: false,
      resolvedGradeAt: null,
      version: 1,
      createdAt: now,
      updatedAt: now,
    );
  }

  final raw = ExportRawClassData(
    subjectClassId: 'class-1',
    enrollments: <ClassEnrollment>[
      makeStudent(id: 'e2', number: 2, code: '67002', firstName: 'คนที่สอง', specialGradeOverride: 'ร'),
      makeStudent(id: 'e1', number: 1, code: '67001', firstName: 'คนแรก'),
      makeStudent(
        id: 'e3',
        number: 2,
        code: '67099',
        firstName: 'ย้ายออก',
        status: StudentLifecycleStatus.transferredOut,
      ),
    ],
    attendanceSessions: <AttendanceSession>[
      AttendanceSession(
        id: 'sess-2',
        teacherId: 'teacher-1',
        subjectClassId: 'class-1',
        sessionDate: DateTime(2026, 5, 20),
        isLocked: true,
        note: '',
        version: 1,
        createdAt: now,
        updatedAt: now,
      ),
      AttendanceSession(
        id: 'sess-1',
        teacherId: 'teacher-1',
        subjectClassId: 'class-1',
        sessionDate: DateTime(2026, 5, 18),
        isLocked: true,
        note: '',
        version: 1,
        createdAt: now,
        updatedAt: now,
      ),
    ],
    attendanceRecords: <AttendanceRecord>[
      AttendanceRecord(
        id: 'rec-1',
        teacherId: 'teacher-1',
        sessionId: 'sess-1',
        enrollmentId: 'e1',
        status: AttendanceStatus.present,
        note: '',
        version: 1,
        updatedAt: now,
      ),
      AttendanceRecord(
        id: 'rec-2',
        teacherId: 'teacher-1',
        sessionId: 'sess-2',
        enrollmentId: 'e1',
        status: AttendanceStatus.absent,
        note: '',
        version: 1,
        updatedAt: now,
      ),
    ],
    attendanceRuleConfig: const AttendanceRuleConfig(
      subjectClassId: 'class-1',
      absentThresholdPct: 20,
      lateToAbsentRatio: null,
      countLeaveAsAbsent: false,
    ),
    scoreCategories: <ScoreCategory>[
      ScoreCategory(
        id: 'cat-1',
        teacherId: 'teacher-1',
        subjectClassId: 'class-1',
        name: 'คะแนนเก็บ',
        targetMaxScore: 50,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      ),
      ScoreCategory(
        id: 'cat-2',
        teacherId: 'teacher-1',
        subjectClassId: 'class-1',
        name: 'สอบปลายภาค',
        targetMaxScore: 50,
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      ),
    ],
    assignments: <Assignment>[
      Assignment(
        id: 'a1',
        teacherId: 'teacher-1',
        subjectClassId: 'class-1',
        categoryId: 'cat-1',
        title: 'ใบงาน 1',
        maxScore: 50,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      ),
      Assignment(
        id: 'a2',
        teacherId: 'teacher-1',
        subjectClassId: 'class-1',
        categoryId: 'cat-2',
        title: 'สอบปลายภาค',
        maxScore: 50,
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      ),
    ],
    studentScores: <StudentScore>[
      // e1 gets 40.50 + 39.49 = 79.99 -> MUST evaluate to '3.5' (never rounded to '4')
      StudentScore(
        id: 'sc-1',
        teacherId: 'teacher-1',
        assignmentId: 'a1',
        enrollmentId: 'e1',
        submissionStatus: SubmissionStatus.submitted,
        score: 40.50,
        updatedAt: now,
      ),
      StudentScore(
        id: 'sc-2',
        teacherId: 'teacher-1',
        assignmentId: 'a2',
        enrollmentId: 'e1',
        submissionStatus: SubmissionStatus.submitted,
        score: 39.49,
        updatedAt: now,
      ),
    ],
    gradingScaleConfig: const GradingScaleConfig(
      subjectClassId: 'class-1',
      scaleType: GradingScaleType.scale0To4,
      rules: GradingScaleConfig.defaultZeroToFourRules,
      missingWorkThreshold: 3,
    ),
  );

  final header = ExportDocumentHeader(
    reportTitle: 'แบบบันทึก ปพ.5',
    schoolName: 'โรงเรียนทดสอบ',
    department: 'กลุ่มสาระวิทยาศาสตร์',
    teacherName: 'ครูทดสอบ',
    academicYearBe: 2569,
    termLabel: '1',
    subjectCode: 'ว31101',
    subjectName: 'วิทยาศาสตร์',
    roomName: 'ม.4/1',
    exportedAt: DateTime(2026, 11, 25),
  );

  group('ExportReportBuilderService', () {
    test(
      'assembles 4-section bundle with exact unrounded 79.99 -> 3.5, chronological sessions, and grade distribution',
      () {
        final bundle = builder.buildBundle(
          raw: raw,
          header: header,
          options: const ExportOptions(
            selectedSections: <ExportSection>{
              ExportSection.roster,
              ExportSection.attendance,
              ExportSection.assignments,
              ExportSection.gradeSummary,
            },
            includeTransferredOut: false,
          ),
        );

        // Excludes transferred_out by default & sorts by studentNumber ASC
        expect(bundle.students.map((s) => s.id), <String>['e1', 'e2']);

        // Attendance sessions sorted chronologically (ASC)
        expect(bundle.attendanceSessions.map((s) => s.id), <String>[
          'sess-1',
          'sess-2',
        ]);

        // Exact unrounded decimal score & grade
        final e1Result = bundle.gradeResults['e1']!;
        expect(e1Result.totalScore, 79.99);
        expect(e1Result.evaluatedGrade, '3.5');
        expect(e1Result.displayedGrade, '3.5');

        // Special grade override preserved for e2
        expect(bundle.gradeResults['e2']!.displayedGrade, 'ร');

        // Attendance summary for e1 (1 present, 1 absent / 2 eligible = 50%)
        expect(bundle.attendanceSummaries['e1']!.absentPercentage, 50.0);

        // Grade distribution counts active students
        expect(bundle.gradeDistribution['3.5'], 1);
        expect(bundle.gradeDistribution['ร'], 1);
        expect(bundle.gradeDistribution['4'], 0);

        // Auto orientation: <=6 sessions, <=4 assignments, <4 categories -> portrait
        expect(
          bundle.orientationDecision.orientation,
          ExportPageOrientation.portrait,
        );
      },
    );

    test(
      'includes transferred_out at the end when includeTransferredOut is true without polluting gradeDistribution',
      () {
        final bundle = builder.buildBundle(
          raw: raw,
          header: header,
          options: const ExportOptions(includeTransferredOut: true),
        );

        expect(bundle.students.map((s) => s.id), <String>['e1', 'e2', 'e3']);
        // Distribution still counts only active students (e1='3.5', e2='ร')
        final totalCounted = bundle.gradeDistribution.values.fold<int>(
          0,
          (a, b) => a + b,
        );
        expect(totalCounted, 2);
      },
    );
  });
}
