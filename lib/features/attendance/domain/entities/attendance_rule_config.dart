/// Subject-class specific attendance rule settings stored on
/// `public.subject_classes`.
///
/// Pure Dart entity with built-in validation helpers.
class AttendanceRuleConfig {
  const AttendanceRuleConfig({
    required this.subjectClassId,
    required this.absentThresholdPct,
    this.lateToAbsentRatio,
    required this.countLeaveAsAbsent,
    this.attendanceScoreWeight,
  });

  final String subjectClassId;

  /// Percentage of eligible sessions above which a student exceeds the `มส`
  /// threshold (e.g. `20.0` means strictly `> 20%`).
  final double absentThresholdPct;

  /// Optional conversion ratio (`N` lates = `1` absent). `null` disables it.
  final int? lateToAbsentRatio;

  /// When `true`, `leave` (`ลา`) counts toward effective absences.
  final bool countLeaveAsAbsent;

  /// Optional attendance score weight reserved for future grading formulas.
  final double? attendanceScoreWeight;

  /// Returns a Thai validation message if invalid, or `null` when valid.
  String? validate() {
    if (absentThresholdPct < 1 || absentThresholdPct > 100) {
      return 'เกณฑ์ร้อยละการขาดเรียนต้องอยู่ระหว่าง 1 ถึง 100';
    }
    if (lateToAbsentRatio != null && lateToAbsentRatio! <= 0) {
      return 'จำนวนครั้งสายต่อการขาด 1 ครั้งต้องมากกว่า 0';
    }
    if (attendanceScoreWeight != null && attendanceScoreWeight! < 0) {
      return 'น้ำหนักคะแนนเข้าเรียนต้องไม่ติดลบ';
    }
    return null;
  }

  bool get isValid => validate() == null;

  AttendanceRuleConfig copyWith({
    double? absentThresholdPct,
    int? lateToAbsentRatio,
    bool clearLateToAbsentRatio = false,
    bool? countLeaveAsAbsent,
    double? attendanceScoreWeight,
    bool clearAttendanceScoreWeight = false,
  }) {
    return AttendanceRuleConfig(
      subjectClassId: subjectClassId,
      absentThresholdPct: absentThresholdPct ?? this.absentThresholdPct,
      lateToAbsentRatio: clearLateToAbsentRatio
          ? null
          : (lateToAbsentRatio ?? this.lateToAbsentRatio),
      countLeaveAsAbsent: countLeaveAsAbsent ?? this.countLeaveAsAbsent,
      attendanceScoreWeight: clearAttendanceScoreWeight
          ? null
          : (attendanceScoreWeight ?? this.attendanceScoreWeight),
    );
  }
}
