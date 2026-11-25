import '../../domain/entities/student_pin_verification_result.dart';

/// JSON DTO for `public.verify_or_set_student_pin`.
class StudentPinVerificationResultDto {
  const StudentPinVerificationResultDto({
    required this.success,
    this.errorCode,
    this.message,
    this.remainingAttempts,
    this.lockedUntil,
  });

  final bool success;
  final StudentPinErrorCode? errorCode;
  final String? message;
  final int? remainingAttempts;
  final DateTime? lockedUntil;

  factory StudentPinVerificationResultDto.fromJson(Map<String, dynamic> json) {
    return StudentPinVerificationResultDto(
      success: json['success'] as bool? ?? false,
      errorCode: StudentPinErrorCode.fromServerCode(
        json['error_code'] as String?,
      ),
      message: json['message'] as String?,
      remainingAttempts: _parseNullableInt(json['remaining_attempts']),
      lockedUntil: _parseTimestamp(json['locked_until']),
    );
  }

  StudentPinVerificationResult toEntity() {
    return StudentPinVerificationResult(
      success: success,
      errorCode: errorCode,
      message: message,
      remainingAttempts: remainingAttempts,
      lockedUntil: lockedUntil,
    );
  }

  static int? _parseNullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static DateTime? _parseTimestamp(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
