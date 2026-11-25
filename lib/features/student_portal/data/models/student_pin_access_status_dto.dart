import '../../domain/entities/student_pin_access_status.dart';

/// JSON DTO for `public.check_student_portal_access`.
class StudentPinAccessStatusDto {
  const StudentPinAccessStatusDto({
    required this.teacherFound,
    required this.studentFound,
    required this.hasPin,
    required this.isLocked,
    this.lockedUntil,
    required this.remainingAttempts,
  });

  final bool teacherFound;
  final bool studentFound;
  final bool hasPin;
  final bool isLocked;
  final DateTime? lockedUntil;
  final int remainingAttempts;

  factory StudentPinAccessStatusDto.fromJson(Map<String, dynamic> json) {
    return StudentPinAccessStatusDto(
      teacherFound: json['teacher_found'] as bool? ?? false,
      studentFound: json['student_found'] as bool? ?? false,
      hasPin: json['has_pin'] as bool? ?? false,
      isLocked: json['is_locked'] as bool? ?? false,
      lockedUntil: _parseTimestamp(json['locked_until']),
      remainingAttempts: _parseInt(json['remaining_attempts']),
    );
  }

  StudentPinAccessStatus toEntity() {
    return StudentPinAccessStatus(
      teacherFound: teacherFound,
      studentFound: studentFound,
      hasPin: hasPin,
      isLocked: isLocked,
      lockedUntil: lockedUntil,
      remainingAttempts: remainingAttempts,
    );
  }

  static DateTime? _parseTimestamp(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static int _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }
}
