import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/domain/entities/attendance_rule_config.dart';
import '../../../attendance/domain/entities/attendance_session.dart';
import '../../../attendance/domain/entities/student_attendance_summary.dart';
import '../../../grading/domain/entities/assignment.dart';
import '../../../grading/domain/entities/grade_result.dart';
import '../../../grading/domain/entities/grading_scale_config.dart';
import '../../../grading/domain/entities/score_category.dart';
import '../../../grading/domain/entities/student_score.dart';
import '../../../homeroom_roster/domain/entities/class_enrollment.dart';
import 'export_document_header.dart';
import 'export_options.dart';
import 'export_orientation.dart';

/// Raw class snapshot fetched once from repositories so live edits to
/// [ExportDocumentHeader] or [ExportOptions] rebuild [ExportReportBundle]
/// instantaneously in memory without re-querying the database.
class ExportRawClassData {
  const ExportRawClassData({
    required this.subjectClassId,
    required this.enrollments,
    required this.attendanceSessions,
    required this.attendanceRecords,
    required this.attendanceRuleConfig,
    required this.scoreCategories,
    required this.assignments,
    required this.studentScores,
    required this.gradingScaleConfig,
  });

  final String subjectClassId;
  final List<ClassEnrollment> enrollments;
  final List<AttendanceSession> attendanceSessions;
  final List<AttendanceRecord> attendanceRecords;
  final AttendanceRuleConfig attendanceRuleConfig;
  final List<ScoreCategory> scoreCategories;
  final List<Assignment> assignments;
  final List<StudentScore> studentScores;
  final GradingScaleConfig gradingScaleConfig;
}

/// Complete, pre-computed report bundle consumed by both Export Preview Canvas
/// (Step 5.1) and Excel/PDF/Word generators (Steps 5.2–5.3).
///
/// Pure Dart entity.
class ExportReportBundle {
  const ExportReportBundle({
    required this.header,
    required this.options,
    required this.orientationDecision,
    required this.students,
    required this.attendanceSessions,
    required this.attendanceMatrix,
    required this.attendanceSummaries,
    required this.scoreCategories,
    required this.assignments,
    required this.scoreMatrix,
    required this.gradingScaleConfig,
    required this.gradeResults,
    required this.gradeDistribution,
  });

  final ExportDocumentHeader header;
  final ExportOptions options;
  final OrientationDecision orientationDecision;
  final List<ClassEnrollment> students;
  final List<AttendanceSession> attendanceSessions;

  /// `enrollmentId -> sessionId -> AttendanceRecord`
  final Map<String, Map<String, AttendanceRecord>> attendanceMatrix;

  /// `enrollmentId -> StudentAttendanceSummary`
  final Map<String, StudentAttendanceSummary> attendanceSummaries;

  final List<ScoreCategory> scoreCategories;
  final List<Assignment> assignments;

  /// `enrollmentId -> assignmentId -> StudentScore`
  final Map<String, Map<String, StudentScore>> scoreMatrix;

  final GradingScaleConfig gradingScaleConfig;

  /// `enrollmentId -> GradeResult`
  final Map<String, GradeResult> gradeResults;

  /// Ordered count of active students per displayed grade (`4, 3.5, ..., 0, ร, มส`).
  final Map<String, int> gradeDistribution;
}
