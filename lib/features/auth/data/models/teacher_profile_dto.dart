import '../../domain/entities/teacher_profile.dart';

/// Data Transfer Object mapping PostgreSQL `public.teachers` rows to
/// [TeacherProfile] domain entities.
class TeacherProfileDto {
  const TeacherProfileDto({
    required this.id,
    required this.email,
    required this.displayName,
    required this.schoolName,
    required this.department,
    required this.teacherCode,
    required this.defaultAbsentThresholdPct,
    required this.defaultMissingWorkThreshold,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeacherProfileDto.fromJson(Map<String, dynamic> json) {
    return TeacherProfileDto(
      id: json['id'] as String,
      email: (json['email'] as String?) ?? '',
      displayName: (json['display_name'] as String?) ?? '',
      schoolName: (json['school_name'] as String?) ?? '',
      department: (json['department'] as String?) ?? '',
      teacherCode: (json['teacher_code'] as String?) ?? '',
      defaultAbsentThresholdPct: _parseDouble(
        json['default_absent_threshold_pct'],
        fallback: 20.0,
      ),
      defaultMissingWorkThreshold: _parseInt(
        json['default_missing_work_threshold'],
        fallback: 3,
      ),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  final String id;
  final String email;
  final String displayName;
  final String schoolName;
  final String department;
  final String teacherCode;
  final double defaultAbsentThresholdPct;
  final int defaultMissingWorkThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;

  TeacherProfile toEntity() {
    return TeacherProfile(
      id: id,
      email: email,
      displayName: displayName,
      schoolName: schoolName,
      department: department,
      teacherCode: teacherCode,
      defaultAbsentThresholdPct: defaultAbsentThresholdPct,
      defaultMissingWorkThreshold: defaultMissingWorkThreshold,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static double _parseDouble(Object? value, {required double fallback}) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static int _parseInt(Object? value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
