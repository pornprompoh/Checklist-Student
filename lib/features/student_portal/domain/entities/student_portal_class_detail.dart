import '../../../../core/constants/attendance_status.dart';
import '../../../../core/constants/submission_status.dart';

/// Single daily attendance entry visible to the authenticated student.
class StudentPortalAttendanceRecord {
  const StudentPortalAttendanceRecord({
    required this.sessionDate,
    required this.status,
    this.note = '',
  });

  final DateTime sessionDate;
  final AttendanceStatus status;
  final String note;
}

/// Server-computed attendance summary for one class respecting `enrolled_at`,
/// `late_to_absent_ratio`, and `count_leave_as_absent`.
class StudentPortalAttendanceSummary {
  const StudentPortalAttendanceSummary({
    required this.totalEligibleSessions,
    required this.recordedSessions,
    required this.presentCount,
    required this.lateCount,
    required this.leaveCount,
    required this.absentCount,
    required this.convertedLateAbsentCount,
    required this.countedLeaveAbsentCount,
    required this.effectiveAbsentCount,
    required this.absentPercentage,
    required this.absentThresholdPct,
  });

  final int totalEligibleSessions;
  final int recordedSessions;
  final int presentCount;
  final int lateCount;
  final int leaveCount;
  final int absentCount;
  final int convertedLateAbsentCount;
  final int countedLeaveAbsentCount;
  final int effectiveAbsentCount;
  final double absentPercentage;
  final double absentThresholdPct;

  bool get isExceededThreshold =>
      totalEligibleSessions > 0 && absentPercentage >= absentThresholdPct;
}

/// Per-category score breakdown for one class.
///
/// [earnedScore] is `null` when the server masks scores (`show_score_to_student = FALSE`).
class StudentPortalCategoryScore {
  const StudentPortalCategoryScore({
    this.categoryId,
    required this.categoryName,
    this.targetMaxScore,
    required this.maxScore,
    this.earnedScore,
  });

  final String? categoryId;
  final String categoryName;
  final double? targetMaxScore;
  final double maxScore;
  final double? earnedScore;
}

/// Single assignment row visible to the student.
///
/// [score] is `null` either when ungraded or when masked server-side
/// (`show_score_to_student = FALSE`), while [submissionStatus], [dueDate], and
/// [isMandatory] remain visible so students can track missing work.
class StudentPortalAssignmentItem {
  const StudentPortalAssignmentItem({
    required this.assignmentId,
    this.categoryId,
    required this.categoryName,
    required this.title,
    this.description = '',
    required this.maxScore,
    required this.isMandatory,
    this.dueDate,
    required this.submissionStatus,
    this.score,
    this.note = '',
  });

  final String assignmentId;
  final String? categoryId;
  final String categoryName;
  final String title;
  final String description;
  final double maxScore;
  final bool isMandatory;
  final DateTime? dueDate;
  final SubmissionStatus submissionStatus;
  final double? score;
  final String note;
}

/// Complete sanitized subject-class snapshot for one student in one term.
///
/// Pure Dart entity. Contains zero teacher-only fields (`was_r_resolved`,
/// `was_ms_resolved`, `resolved_grade_at`, `grading_rules`, `teacher_id`).
class StudentPortalClassDetail {
  const StudentPortalClassDetail({
    required this.subjectClassId,
    required this.subjectCode,
    required this.subjectName,
    required this.roomName,
    required this.studentNumber,
    required this.enrollmentStatus,
    this.enrolledAt,
    required this.showScoreToStudent,
    required this.showGradeToStudent,
    this.totalScore,
    required this.totalMaxScore,
    this.displayedGrade,
    this.specialGradeOverride,
    required this.attendanceSummary,
    required this.attendanceRecords,
    required this.categoryScores,
    required this.assignments,
  });

  final String subjectClassId;
  final String subjectCode;
  final String subjectName;
  final String roomName;
  final int studentNumber;
  final String enrollmentStatus;
  final DateTime? enrolledAt;
  final bool showScoreToStudent;
  final bool showGradeToStudent;
  final double? totalScore;
  final double totalMaxScore;
  final String? displayedGrade;
  final String? specialGradeOverride;
  final StudentPortalAttendanceSummary attendanceSummary;
  final List<StudentPortalAttendanceRecord> attendanceRecords;
  final List<StudentPortalCategoryScore> categoryScores;
  final List<StudentPortalAssignmentItem> assignments;

  int get missingAssignmentsCount => assignments
      .where((item) => item.submissionStatus == SubmissionStatus.missing)
      .length;
}
