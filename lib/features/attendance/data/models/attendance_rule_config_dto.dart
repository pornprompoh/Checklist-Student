import '../../domain/entities/attendance_rule_config.dart';

/// Data transfer object mapping attendance rule columns on
/// `public.subject_classes` to [AttendanceRuleConfig].
class AttendanceRuleConfigDto {
  const AttendanceRuleConfigDto({
    required this.subjectClassId,
    required this.absentThresholdPct,
    this.lateToAbsentRatio,
    required this.countLeaveAsAbsent,
    this.attendanceScoreWeight,
  });

  factory AttendanceRuleConfigDto.fromJson(Map<String, dynamic> json) {
    return AttendanceRuleConfigDto(
      subjectClassId: json['id'] as String,
      absentThresholdPct: _parseDouble(json['absent_threshold_pct']) ?? 20.0,
      lateToAbsentRatio: (json['late_to_absent_ratio'] as num?)?.toInt(),
      countLeaveAsAbsent: json['count_leave_as_absent'] as bool? ?? false,
      attendanceScoreWeight: _parseDouble(json['attendance_score_weight']),
    );
  }

  final String subjectClassId;
  final double absentThresholdPct;
  final int? lateToAbsentRatio;
  final bool countLeaveAsAbsent;
  final double? attendanceScoreWeight;

  AttendanceRuleConfig toEntity() {
    return AttendanceRuleConfig(
      subjectClassId: subjectClassId,
      absentThresholdPct: absentThresholdPct,
      lateToAbsentRatio: lateToAbsentRatio,
      countLeaveAsAbsent: countLeaveAsAbsent,
      attendanceScoreWeight: attendanceScoreWeight,
    );
  }

  static Map<String, dynamic> toUpdateJson(AttendanceRuleConfig config) {
    return <String, dynamic>{
      'absent_threshold_pct': config.absentThresholdPct,
      'late_to_absent_ratio': config.lateToAbsentRatio,
      'count_leave_as_absent': config.countLeaveAsAbsent,
      'attendance_score_weight': config.attendanceScoreWeight,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static double? _parseDouble(Object? raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw.trim());
    return null;
  }
}
