import '../../domain/entities/subject_class.dart';

/// Data Transfer Object mapping `public.subject_classes` rows to [SubjectClass].
class SubjectClassDto {
  const SubjectClassDto({
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

  factory SubjectClassDto.fromJson(Map<String, dynamic> json) {
    return SubjectClassDto(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      subjectId: json['subject_id'] as String,
      homeroomId: json['homeroom_id'] as String?,
      roomName: (json['room_name'] as String?) ?? '',
      teachingDays: _parseIntList(json['teaching_days']),
      isPinned: (json['is_pinned'] as bool?) ?? false,
      showScoreToStudent: (json['show_score_to_student'] as bool?) ?? true,
      showGradeToStudent: (json['show_grade_to_student'] as bool?) ?? true,
      absentThresholdPct: _parseDouble(
        json['absent_threshold_pct'],
        fallback: 20.0,
      ),
      missingWorkThreshold: _parseInt(
        json['missing_work_threshold'],
        fallback: 3,
      ),
      lateToAbsentRatio: _parseNullableInt(json['late_to_absent_ratio']),
      countLeaveAsAbsent: (json['count_leave_as_absent'] as bool?) ?? false,
      attendanceScoreWeight: _parseNullableDouble(
        json['attendance_score_weight'],
      ),
      gradingScaleType: (json['grading_scale_type'] as String?) ?? '0-4',
      gradingRules: _parseGradingRules(json['grading_rules']),
      createdAt: _parseTimestamp(json['created_at']),
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

  final String id;
  final String teacherId;
  final String subjectId;
  final String? homeroomId;
  final String roomName;
  final List<int> teachingDays;
  final bool isPinned;
  final bool showScoreToStudent;
  final bool showGradeToStudent;
  final double absentThresholdPct;
  final int missingWorkThreshold;
  final int? lateToAbsentRatio;
  final bool countLeaveAsAbsent;
  final double? attendanceScoreWeight;
  final String gradingScaleType;
  final List<GradingRuleTier> gradingRules;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Builds the `UPDATE` payload for `public.subject_classes`.
  static Map<String, dynamic> toUpdateJson(SubjectClass entity) {
    return <String, dynamic>{
      'homeroom_id': entity.homeroomId,
      'room_name': entity.roomName.trim(),
      'teaching_days': entity.teachingDays,
      'is_pinned': entity.isPinned,
      'show_score_to_student': entity.showScoreToStudent,
      'show_grade_to_student': entity.showGradeToStudent,
      'absent_threshold_pct': entity.absentThresholdPct,
      'missing_work_threshold': entity.missingWorkThreshold,
      'late_to_absent_ratio': entity.lateToAbsentRatio,
      'count_leave_as_absent': entity.countLeaveAsAbsent,
      'attendance_score_weight': entity.attendanceScoreWeight,
      'grading_scale_type': entity.gradingScaleType,
      'grading_rules': entity.gradingRules
          .map((tier) => <String, dynamic>{'grade': tier.grade, 'min': tier.min})
          .toList(growable: false),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  SubjectClass toEntity() {
    return SubjectClass(
      id: id,
      teacherId: teacherId,
      subjectId: subjectId,
      homeroomId: homeroomId,
      roomName: roomName,
      teachingDays: teachingDays,
      isPinned: isPinned,
      showScoreToStudent: showScoreToStudent,
      showGradeToStudent: showGradeToStudent,
      absentThresholdPct: absentThresholdPct,
      missingWorkThreshold: missingWorkThreshold,
      lateToAbsentRatio: lateToAbsentRatio,
      countLeaveAsAbsent: countLeaveAsAbsent,
      attendanceScoreWeight: attendanceScoreWeight,
      gradingScaleType: gradingScaleType,
      gradingRules: gradingRules,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static List<int> _parseIntList(Object? value) {
    if (value is! List) return const <int>[];
    return value
        .map((item) => _parseNullableInt(item))
        .whereType<int>()
        .toList(growable: false);
  }

  static List<GradingRuleTier> _parseGradingRules(Object? value) {
    if (value is! List) return const <GradingRuleTier>[];
    final tiers = <GradingRuleTier>[];
    for (final item in value) {
      if (item is Map) {
        final grade = item['grade']?.toString();
        final min = _parseNullableDouble(item['min']);
        if (grade != null && min != null) {
          tiers.add(GradingRuleTier(grade: grade, min: min));
        }
      }
    }
    return List<GradingRuleTier>.unmodifiable(tiers);
  }

  static double _parseDouble(Object? value, {required double fallback}) {
    return _parseNullableDouble(value) ?? fallback;
  }

  static double? _parseNullableDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int _parseInt(Object? value, {required int fallback}) {
    return _parseNullableInt(value) ?? fallback;
  }

  static int? _parseNullableInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime _parseTimestamp(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
