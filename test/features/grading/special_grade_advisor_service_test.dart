import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/features/attendance/domain/entities/student_attendance_summary.dart';
import 'package:checklist_student/features/grading/domain/services/special_grade_advisor_service.dart';

void main() {
  const service = SpecialGradeAdvisorService();

  StudentAttendanceSummary buildAttendance({
    required AttendanceRiskLevel riskLevel,
    required double absentPercentage,
  }) {
    return StudentAttendanceSummary(
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
      absentPercentage: absentPercentage,
      riskLevel: riskLevel,
    );
  }

  group('SpecialGradeAdvisorService', () {
    test('Case 1 (0/5 assessed): suppresses ร even when student misses mandatory and threshold work', () {
      final advice = service.evaluateAdvice(
        missingMandatoryCount: 2,
        missingAssignmentsCount: 5,
        missingWorkThreshold: 3,
        totalAssignmentsCount: 5,
        assessedAssignmentsCount: 0,
        attendanceSummary: buildAttendance(
          riskLevel: AttendanceRiskLevel.normal,
          absentPercentage: 5.0,
        ),
      );

      expect(advice.isAllAssignmentsAssessed, isFalse);
      expect(advice.recommendR, isFalse);
      expect(advice.recommendMs, isFalse);
      expect(advice.hasRecommendation, isFalse);
      expect(advice.primaryRecommendedCode, isNull);
      expect(advice.reasons, isEmpty);
      expect(advice.assessedAssignmentsCount, 0);
      expect(advice.totalAssignmentsCount, 5);
    });

    test('Case 2 (3/5 partially assessed): suppresses ร even with missing mandatory work', () {
      final advice = service.evaluateAdvice(
        missingMandatoryCount: 1,
        missingAssignmentsCount: 4,
        missingWorkThreshold: 3,
        totalAssignmentsCount: 5,
        assessedAssignmentsCount: 3,
      );

      expect(advice.isAllAssignmentsAssessed, isFalse);
      expect(advice.recommendR, isFalse);
      expect(advice.recommendMs, isFalse);
      expect(advice.primaryRecommendedCode, isNull);
      expect(advice.reasons, isEmpty);
    });

    test('Case 3 (0/5 unassessed + exceeds มส): recommends ONLY มส (never ร/มส)', () {
      final advice = service.evaluateAdvice(
        missingMandatoryCount: 2,
        missingAssignmentsCount: 5,
        missingWorkThreshold: 3,
        totalAssignmentsCount: 5,
        assessedAssignmentsCount: 0,
        attendanceSummary: buildAttendance(
          riskLevel: AttendanceRiskLevel.exceededMs,
          absentPercentage: 25.0,
        ),
      );

      expect(advice.recommendR, isFalse);
      expect(advice.recommendMs, isTrue);
      expect(advice.primaryRecommendedCode, 'มส');
      expect(advice.reasons, hasLength(1));
      expect(advice.reasons.first, contains('25%'));
    });

    test('Case 4a (5/5 fully assessed): recommends ร when student misses mandatory task', () {
      final advice = service.evaluateAdvice(
        missingMandatoryCount: 1,
        missingAssignmentsCount: 1,
        missingWorkThreshold: 5,
        totalAssignmentsCount: 5,
        assessedAssignmentsCount: 5,
      );

      expect(advice.isAllAssignmentsAssessed, isTrue);
      expect(advice.recommendR, isTrue);
      expect(advice.recommendMs, isFalse);
      expect(advice.primaryRecommendedCode, 'ร');
      expect(advice.reasons, hasLength(1));
      expect(advice.reasons.first, contains('ค้างงานบังคับส่ง 1 ชิ้น'));
    });

    test('Case 4b (5/5 fully assessed): recommends ร when total missing meets threshold', () {
      final advice = service.evaluateAdvice(
        missingMandatoryCount: 0,
        missingAssignmentsCount: 3,
        missingWorkThreshold: 3,
        totalAssignmentsCount: 5,
        assessedAssignmentsCount: 5,
      );

      expect(advice.recommendR, isTrue);
      expect(advice.recommendMs, isFalse);
      expect(advice.primaryRecommendedCode, 'ร');
      expect(advice.reasons, hasLength(1));
      expect(advice.reasons.first, contains('ค้างส่งงาน 3 ชิ้น'));
      expect(advice.reasons.first, contains('เกณฑ์ 3 ชิ้น'));
    });

    test('Case 4c (5/5 fully assessed + exceeds มส): recommends both ร and มส, prioritizing มส', () {
      final advice = service.evaluateAdvice(
        missingMandatoryCount: 2,
        missingAssignmentsCount: 4,
        missingWorkThreshold: 3,
        totalAssignmentsCount: 5,
        assessedAssignmentsCount: 5,
        attendanceSummary: buildAttendance(
          riskLevel: AttendanceRiskLevel.exceededMs,
          absentPercentage: 22.5,
        ),
      );

      expect(advice.recommendMs, isTrue);
      expect(advice.recommendR, isTrue);
      expect(advice.hasRecommendation, isTrue);
      expect(advice.primaryRecommendedCode, 'มส');
      expect(advice.reasons, hasLength(3));
      expect(advice.reasons[0], contains('22.5%'));
      expect(advice.reasons[1], contains('ค้างงานบังคับส่ง 2 ชิ้น'));
      expect(advice.reasons[2], contains('ค้างส่งงาน 4 ชิ้น'));
    });

    test('Case 5 (0/0 no assignments configured): never recommends ร', () {
      final advice = service.evaluateAdvice(
        missingMandatoryCount: 0,
        missingAssignmentsCount: 0,
        missingWorkThreshold: 3,
        totalAssignmentsCount: 0,
        assessedAssignmentsCount: 0,
      );

      expect(advice.isAllAssignmentsAssessed, isFalse);
      expect(advice.recommendR, isFalse);
      expect(advice.recommendMs, isFalse);
      expect(advice.primaryRecommendedCode, isNull);
    });

    test('does not trigger general missing threshold when threshold is 0', () {
      final advice = service.evaluateAdvice(
        missingMandatoryCount: 0,
        missingAssignmentsCount: 4,
        missingWorkThreshold: 0,
        totalAssignmentsCount: 5,
        assessedAssignmentsCount: 5,
      );

      expect(advice.recommendR, isFalse);
      expect(advice.primaryRecommendedCode, isNull);
    });

    test('does not recommend มส when only approaching threshold', () {
      final advice = service.evaluateAdvice(
        missingMandatoryCount: 0,
        missingAssignmentsCount: 0,
        missingWorkThreshold: 3,
        totalAssignmentsCount: 5,
        assessedAssignmentsCount: 5,
        attendanceSummary: buildAttendance(
          riskLevel: AttendanceRiskLevel.approachingMs,
          absentPercentage: 18.0,
        ),
      );

      expect(advice.recommendMs, isFalse);
      expect(advice.primaryRecommendedCode, isNull);
    });
  });
}
