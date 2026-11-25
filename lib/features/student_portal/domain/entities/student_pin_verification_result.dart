/// Operation mode sent to `public.verify_or_set_student_pin`.
enum StudentPinAuthMode {
  verify('verify'),
  setup('setup');

  const StudentPinAuthMode(this.rpcValue);

  final String rpcValue;
}

/// Structured error codes returned by Student Portal PIN & summary RPCs.
enum StudentPinErrorCode {
  invalidPinFormat('INVALID_PIN_FORMAT'),
  studentNotFound('STUDENT_NOT_FOUND'),
  pinLocked('PIN_LOCKED'),
  pinAlreadySet('PIN_ALREADY_SET'),
  pinNotSet('PIN_NOT_SET'),
  invalidPin('INVALID_PIN'),
  unknown('UNKNOWN');

  const StudentPinErrorCode(this.serverCode);

  final String serverCode;

  /// Parses a server `error_code` string into [StudentPinErrorCode].
  static StudentPinErrorCode? fromServerCode(String? code) {
    if (code == null || code.trim().isEmpty) {
      return null;
    }
    final normalized = code.trim().toUpperCase();
    for (final value in StudentPinErrorCode.values) {
      if (value.serverCode == normalized) {
        return value;
      }
    }
    return StudentPinErrorCode.unknown;
  }
}

/// Result returned by `public.verify_or_set_student_pin`.
///
/// Pure Dart entity with zero Flutter or Supabase dependencies.
class StudentPinVerificationResult {
  const StudentPinVerificationResult({
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

  bool get isLocked => errorCode == StudentPinErrorCode.pinLocked;
}
