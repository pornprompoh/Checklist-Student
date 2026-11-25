/// Single grade boundary tier stored inside `subject_classes.grading_rules`.
class GradingRuleTier {
  const GradingRuleTier({
    required this.grade,
    required this.min,
  });

  final String grade;
  final double min;
}

/// Level 4 of the 4-level academic hierarchy (`public.subject_classes`).
///
/// Represents one subject taught to one room, including teaching schedule,
/// Student Portal visibility toggles, risk thresholds, and flexible grading rules.
/// Pure Dart entity.
class SubjectClass {
  const SubjectClass({
    required this.id,
    required this.teacherId,
    required this.subjectId,
    required this.homeroomId,
    required this.roomName,
    required this.teachingDays,
    required this.isPinned,
    required this.showScoreToStudent,
    required this.showGradeToStudent,
    required this.absentThresholdPct,
    required this.missingWorkThreshold,
    required this.lateToAbsentRatio,
    required this.countLeaveAsAbsent,
    required this.attendanceScoreWeight,
    required this.gradingScaleType,
    required this.gradingRules,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String teacherId;
  final String subjectId;
  final String? homeroomId;
  final String roomName;

  /// ISO weekday integers (`1` = Monday ... `7` = Sunday).
  final List<int> teachingDays;
  final bool isPinned;
  final bool showScoreToStudent;
  final bool showGradeToStudent;
  final double absentThresholdPct;
  final int missingWorkThreshold;
  final int? lateToAbsentRatio;
  final bool countLeaveAsAbsent;
  final double? attendanceScoreWeight;

  /// Matches PostgreSQL `CHECK (grading_scale_type IN ('0-4', 'A-F', 'custom'))`.
  final String gradingScaleType;
  final List<GradingRuleTier> gradingRules;
  final DateTime createdAt;
  final DateTime updatedAt;
}
