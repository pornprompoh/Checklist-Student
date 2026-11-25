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
    test('returns no recommendation when work and attendance are normal', () {
      final advice = service.evaluateAdvice(
        missingMandatoryCount: 0,
        missingAssignmentsCount: 2,
        missingWorkThreshold: 3,
        attendanceSummary: buildAttendance(
          riskLevel: AttendanceRiskLevel.normal,
          absentPercentage: 5.0,
        ),
      );

      expect(advice.recommendR, isFalse);
      expect(advice.recommendMs, isFalse);
      expect(advice.hasRecommendation, isFalse);
      expect(advice.primaryRecommendedCode, isNull);
      expect(advice.reasons, isEmpty);
    });

    test('recommends ร when student misses at least one mandatory task', () {
      final advice = service.evaluateAdvice(
        missingMandatoryCount: 1,
        missingAssignmentsCount: 1,
        missingWorkThreshold: 5,
      );

      expect(advice.recommendR, isTrue);
      expect(advice.recommendMs, isFalse);
      expect(advice.primaryRecommendedCode, 'ร');
      expect(advice.reasons, hasLength(1));
      expect(advice.reasons.first, contains('ค้างงานบังคับส่ง 1 ชิ้น'));
    });

    test('recommends ร when total missing assignments meets threshold', () {
      final advice = service.evaluateAdvice(
        missingMandatoryCount: 0,
        missingAssignmentsCount: 3,
        missingWorkThreshold: 3,
      );

      expect(advice.recommendR, isTrue);
      expect(advice.recommendMs, isFalse);
      expect(advice.primaryRecommendedCode, 'ร');
      expect(advice.reasons, hasLength(1));
      expect(advice.reasons.first, contains('ค้างส่งงาน 3 ชิ้น'));
      expect(advice.reasons.first, contains('เกณฑ์ 3 ชิ้น'));
    });

    test('does not trigger general missing threshold when threshold is 0', () {
      final advice = service.evaluateAdvice(
        missingMandatoryCount: 0,
        missingAssignmentsCount: 4,
        missingWorkThreshold: 0,
      );

      expect(advice.recommendR, isFalse);
      expect(advice.primaryRecommendedCode, isNull);
    });

    test('recommends มส when attendance exceeds threshold', () {
      final advice = service.evaluateAdvice(
        missingMandatoryCount: 0,
        missingAssignmentsCount: 0,
        missingWorkThreshold: 3,
        attendanceSummary: buildAttendance(
          riskLevel: AttendanceRiskLevel.exceededMs,
          absentPercentage: 25.0,
        ),
      );

      expect(advice.recommendMs, isTrue);
      expect(advice.recommendR, isFalse);
      expect(advice.primaryRecommendedCode, 'มส');
      expect(advice.reasons, hasLength(1));
      expect(advice.reasons.first, contains('25%'));
    });

    test('does not recommend มส when only approaching threshold', () {
      final advice = service.evaluateAdvice(
        missingMandatoryCount: 0,
        missingAssignmentsCount: 0,
        missingWorkThreshold: 3,
        attendanceSummary: buildAttendance(
          riskLevel: AttendanceRiskLevel.approachingMs,
          absentPercentage: 18.0,
        ),
      );

      expect(advice.recommendMs, isFalse);
      expect(advice.primaryRecommendedCode, isNull);
    });

    test(
      'prioritizes มส while preserving both reasons when both ร and มส apply',
      () {
        final advice = service.evaluateAdvice(
          missingMandatoryCount: 2,
          missingAssignmentsCount: 4,
          missingWorkThreshold: 3,
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
      },
    );
  });
}
