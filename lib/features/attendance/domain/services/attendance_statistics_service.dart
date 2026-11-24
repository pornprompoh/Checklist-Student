import '../../../../core/constants/attendance_status.dart';
import '../../../homeroom_roster/domain/entities/class_enrollment.dart';
import '../entities/attendance_record.dart';
import '../entities/attendance_rule_config.dart';
import '../entities/attendance_session.dart';
import '../entities/student_attendance_summary.dart';

/// Pure Dart business logic service computing per-student attendance totals,
/// effective absences, `มส` risk levels, and session status counters.
///
/// Handles mid-term enrollments (`enrolledAt`) and soft-deleted students
/// (`transferredOutAt`) strictly via date-only comparisons.
class AttendanceStatisticsService {
  const AttendanceStatisticsService();

  static const double _approachingRatio = 0.75;

  /// Computes attendance statistics for one student across [sessions] and
  /// [records] according to [ruleConfig].
  StudentAttendanceSummary calculateStudentSummary({
    required String enrollmentId,
    required DateTime enrolledAt,
    DateTime? transferredOutAt,
    required List<AttendanceSession> sessions,
    required List<AttendanceRecord> records,
    required AttendanceRuleConfig ruleConfig,
  }) {
    final enrolledDate = _dateOnly(enrolledAt);
    final transferredDate = transferredOutAt == null
        ? null
        : _dateOnly(transferredOutAt);

    final eligibleSessionIds = <String>{};
    for (final session in sessions) {
      final sessionDate = _dateOnly(session.sessionDate);
      if (sessionDate.isBefore(enrolledDate)) {
        continue;
      }
      if (transferredDate != null && sessionDate.isAfter(transferredDate)) {
        continue;
      }
      eligibleSessionIds.add(session.id);
    }

    var presentCount = 0;
    var lateCount = 0;
    var leaveCount = 0;
    var absentCount = 0;
    var recordedSessions = 0;

    for (final record in records) {
      if (record.enrollmentId != enrollmentId) continue;
      if (!eligibleSessionIds.contains(record.sessionId)) continue;
      recordedSessions++;
      switch (record.status) {
        case AttendanceStatus.present:
          presentCount++;
        case AttendanceStatus.late:
          lateCount++;
        case AttendanceStatus.leave:
          leaveCount++;
        case AttendanceStatus.absent:
          absentCount++;
      }
    }

    final totalEligibleSessions = eligibleSessionIds.length;
    final ratio = ruleConfig.lateToAbsentRatio;
    final convertedLateAbsentCount =
        (ratio != null && ratio > 0) ? (lateCount ~/ ratio) : 0;
    final countedLeaveAbsentCount =
        ruleConfig.countLeaveAsAbsent ? leaveCount : 0;
    final effectiveAbsentCount =
        absentCount + convertedLateAbsentCount + countedLeaveAbsentCount;

    final absentPercentage = totalEligibleSessions == 0
        ? 0.0
        : (effectiveAbsentCount / totalEligibleSessions) * 100.0;

    final riskLevel = _evaluateRiskLevel(
      totalEligibleSessions: totalEligibleSessions,
      effectiveAbsentCount: effectiveAbsentCount,
      absentPercentage: absentPercentage,
      absentThresholdPct: ruleConfig.absentThresholdPct,
    );

    return StudentAttendanceSummary(
      enrollmentId: enrollmentId,
      totalEligibleSessions: totalEligibleSessions,
      recordedSessions: recordedSessions,
      presentCount: presentCount,
      lateCount: lateCount,
      leaveCount: leaveCount,
      absentCount: absentCount,
      convertedLateAbsentCount: convertedLateAbsentCount,
      countedLeaveAbsentCount: countedLeaveAbsentCount,
      effectiveAbsentCount: effectiveAbsentCount,
      absentPercentage: absentPercentage,
      riskLevel: riskLevel,
    );
  }

  /// Batch-computes summaries for every student in [enrollments] keyed by
  /// `enrollment.id`.
  Map<String, StudentAttendanceSummary> calculateClassSummaries({
    required List<ClassEnrollment> enrollments,
    required List<AttendanceSession> sessions,
    required List<AttendanceRecord> records,
    required AttendanceRuleConfig ruleConfig,
  }) {
    final recordsByEnrollment = <String, List<AttendanceRecord>>{};
    for (final record in records) {
      recordsByEnrollment
          .putIfAbsent(record.enrollmentId, () => <AttendanceRecord>[])
          .add(record);
    }

    final summaries = <String, StudentAttendanceSummary>{};
    for (final student in enrollments) {
      summaries[student.id] = calculateStudentSummary(
        enrollmentId: student.id,
        enrolledAt: student.enrolledAt,
        transferredOutAt: student.transferredOutAt,
        sessions: sessions,
        records:
            recordsByEnrollment[student.id] ?? const <AttendanceRecord>[],
        ruleConfig: ruleConfig,
      );
    }
    return Map<String, StudentAttendanceSummary>.unmodifiable(summaries);
  }

  /// Counts [records] by fixed 4-state [AttendanceStatus].
  Map<AttendanceStatus, int> countByStatus(List<AttendanceRecord> records) {
    final counts = <AttendanceStatus, int>{
      for (final status in AttendanceStatus.values) status: 0,
    };
    for (final record in records) {
      counts[record.status] = (counts[record.status] ?? 0) + 1;
    }
    return Map<AttendanceStatus, int>.unmodifiable(counts);
  }

  AttendanceRiskLevel _evaluateRiskLevel({
    required int totalEligibleSessions,
    required int effectiveAbsentCount,
    required double absentPercentage,
    required double absentThresholdPct,
  }) {
    if (totalEligibleSessions == 0 || effectiveAbsentCount == 0) {
      return AttendanceRiskLevel.normal;
    }
    if (absentPercentage > absentThresholdPct) {
      return AttendanceRiskLevel.exceededMs;
    }
    if (absentPercentage >= (absentThresholdPct * _approachingRatio)) {
      return AttendanceRiskLevel.approachingMs;
    }
    return AttendanceRiskLevel.normal;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
