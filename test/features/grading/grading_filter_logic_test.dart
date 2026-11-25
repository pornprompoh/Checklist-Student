import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/features/attendance/domain/entities/student_attendance_summary.dart';
import 'package:checklist_student/features/grading/domain/entities/grade_result.dart';
import 'package:checklist_student/features/grading/presentation/providers/grading_filter_provider.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/class_enrollment.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/student_lifecycle_status.dart';

void main() {
  final now = DateTime.utc(2026, 11, 25);

  GradingTableRowData buildRow({
    required String id,
    required int number,
    required String code,
    required String firstName,
    required String lastName,
    StudentLifecycleStatus status = StudentLifecycleStatus.active,
    int missingAssignments = 0,
    String? specialGradeOverride,
    bool recommendR = false,
    bool recommendMs = false,
    AttendanceRiskLevel? riskLevel,
  }) {
    final enrollment = ClassEnrollment(
      id: id,
      teacherId: 'teacher-1',
      subjectClassId: 'class-1',
      homeroomStudentId: null,
      studentIdentityId: 'ident-$id',
      studentCode: code,
      studentNumber: number,
      prefix: 'ด.ช.',
      firstName: firstName,
      lastName: lastName,
      status: status,
      enrolledAt: now,
      transferredOutAt: status == StudentLifecycleStatus.transferredOut
          ? now
          : null,
      specialGradeOverride: specialGradeOverride,
      wasRResolved: false,
      wasMsResolved: false,
      resolvedGradeAt: null,
      version: 1,
      createdAt: now,
      updatedAt: now,
    );

    final advice = SpecialGradeAdvice(
      recommendR: recommendR,
      recommendMs: recommendMs,
      primaryRecommendedCode: recommendMs ? 'มส' : (recommendR ? 'ร' : null),
      reasons: const <String>[],
    );

    final result = GradeResult(
      enrollmentId: id,
      totalScore: 75.5,
      totalMaxScore: 100.0,
      percentage: 75.5,
      categorySummaries: const <CategoryScoreSummary>[],
      missingAssignmentsCount: missingAssignments,
      missingMandatoryCount: recommendR ? 1 : 0,
      overMaxAssignmentIds: const <String>[],
      evaluatedGrade: '3.5',
      specialGradeOverride: specialGradeOverride,
      displayedGrade: specialGradeOverride ?? '3.5',
      specialGradeAdvice: advice,
    );

    final attendance = riskLevel == null
        ? null
        : StudentAttendanceSummary(
            enrollmentId: id,
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
            riskLevel: riskLevel,
          );

    return GradingTableRowData(
      enrollment: enrollment,
      gradeResult: result,
      attendanceSummary: attendance,
    );
  }

  final rows = <GradingTableRowData>[
    buildRow(
      id: 'e1',
      number: 1,
      code: '67001',
      firstName: 'สมชาย',
      lastName: 'ใจดี',
      missingAssignments: 0,
      riskLevel: AttendanceRiskLevel.normal,
    ),
    buildRow(
      id: 'e2',
      number: 2,
      code: '67002',
      firstName: 'สมหญิง',
      lastName: 'รักเรียน',
      missingAssignments: 2,
      recommendR: true,
      riskLevel: AttendanceRiskLevel.normal,
    ),
    buildRow(
      id: 'e3',
      number: 3,
      code: '67003',
      firstName: 'กิตติ',
      lastName: 'มาสาย',
      missingAssignments: 0,
      riskLevel: AttendanceRiskLevel.approachingMs,
    ),
    buildRow(
      id: 'e4',
      number: 4,
      code: '67004',
      firstName: 'นภา',
      lastName: 'ขาดบ่อย',
      specialGradeOverride: 'มส',
      recommendMs: true,
      riskLevel: AttendanceRiskLevel.exceededMs,
    ),
    buildRow(
      id: 'e5',
      number: 2,
      code: '67099',
      firstName: 'ย้ายออก',
      lastName: 'กลางเทอม',
      status: StudentLifecycleStatus.transferredOut,
      missingAssignments: 5,
    ),
  ];

  group('filterGradingRows & countQuickFilterBuckets', () {
    test('hides transferred_out by default and includes them when toggled', () {
      final activeOnly = filterGradingRows(
        rows: rows,
        filter: const GradingFilterState(),
      );
      expect(activeOnly.map((r) => r.enrollment.id), <String>[
        'e1',
        'e2',
        'e3',
        'e4',
      ]);

      final withTransferred = filterGradingRows(
        rows: rows,
        filter: const GradingFilterState(showTransferredOut: true),
      );
      expect(withTransferred.length, 5);
    });

    test('searches by Thai full name, student code, and student number', () {
      expect(
        filterGradingRows(
          rows: rows,
          filter: const GradingFilterState(searchQuery: 'สมหญิง'),
        ).map((r) => r.enrollment.id),
        <String>['e2'],
      );
      expect(
        filterGradingRows(
          rows: rows,
          filter: const GradingFilterState(searchQuery: '67003'),
        ).map((r) => r.enrollment.id),
        <String>['e3'],
      );
      expect(
        filterGradingRows(
          rows: rows,
          filter: const GradingFilterState(searchQuery: '1'),
        ).map((r) => r.enrollment.id),
        <String>['e1'],
      );
    });

    test('filters accurately for missingWork, atRiskMs, and hasSpecialGrade', () {
      expect(
        filterGradingRows(
          rows: rows,
          filter: const GradingFilterState(
            quickFilter: GradingQuickFilter.missingWork,
          ),
        ).map((r) => r.enrollment.id),
        <String>['e2'],
      );
      expect(
        filterGradingRows(
          rows: rows,
          filter: const GradingFilterState(
            quickFilter: GradingQuickFilter.atRiskMs,
          ),
        ).map((r) => r.enrollment.id),
        <String>['e3', 'e4'],
      );
      expect(
        filterGradingRows(
          rows: rows,
          filter: const GradingFilterState(
            quickFilter: GradingQuickFilter.hasSpecialGrade,
          ),
        ).map((r) => r.enrollment.id),
        <String>['e2', 'e4'],
      );

      final counts = countQuickFilterBuckets(
        rows: rows,
        showTransferredOut: false,
      );
      expect(counts[GradingQuickFilter.all], 4);
      expect(counts[GradingQuickFilter.missingWork], 1);
      expect(counts[GradingQuickFilter.atRiskMs], 2);
      expect(counts[GradingQuickFilter.hasSpecialGrade], 2);
    });
  });
}
