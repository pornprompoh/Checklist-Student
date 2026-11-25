/// Pure Dart validator and lockout countdown formatter for the Student Portal
/// 6-digit PIN flow.
///
/// Zero Flutter or Supabase dependencies so it can be unit-tested directly.
class StudentPinValidatorService {
  const StudentPinValidatorService();

  static const int maxStudentCodeLength = 50;
  static const int pinLength = 6;
  static final RegExp _pinRegex = RegExp(r'^[0-9]{6}$');

  /// Validates student code input before calling `check_student_portal_access`.
  String? validateStudentCode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'กรุณากรอกเลขประจำตัวนักเรียน';
    }
    if (trimmed.length > maxStudentCodeLength) {
      return 'เลขประจำตัวนักเรียนต้องมีความยาวไม่เกิน $maxStudentCodeLength ตัวอักษร';
    }
    return null;
  }

  /// Validates that [raw] is strictly a 6-digit numeric PIN (`^[0-9]{6}$`).
  String? validatePin(String raw) {
    if (raw.isEmpty) {
      return 'กรุณากรอกรหัส PIN 6 หลัก';
    }
    if (!_pinRegex.hasMatch(raw)) {
      return 'รหัส PIN ต้องเป็นตัวเลข 6 หลักเท่านั้น';
    }
    return null;
  }

  /// Validates both PIN and confirmation PIN during first-time setup.
  String? validatePinSetup({
    required String pin,
    required String confirmPin,
  }) {
    final pinError = validatePin(pin);
    if (pinError != null) {
      return pinError;
    }
    if (confirmPin.isEmpty) {
      return 'กรุณายืนยันรหัส PIN อีกครั้ง';
    }
    if (pin != confirmPin) {
      return 'รหัส PIN ทั้งสองช่องไม่ตรงกัน กรุณาตรวจสอบอีกครั้ง';
    }
    return null;
  }

  /// Formats the remaining lockout countdown in Thai, e.g.
  /// `"เหลืออีก 14 นาที 30 วินาที"` or `"หมดเวลาล็อกแล้ว กรุณาลองใหม่"`.
  String formatLockoutRemainingThai(DateTime lockedUntil, {DateTime? now}) {
    final reference = (now ?? DateTime.now()).toUtc();
    final target = lockedUntil.toUtc();
    final diffSeconds = target.difference(reference).inSeconds;
    if (diffSeconds <= 0) {
      return 'หมดเวลาล็อกแล้ว กรุณาลองใหม่';
    }

    final minutes = diffSeconds ~/ 60;
    final seconds = diffSeconds % 60;
    if (minutes > 0 && seconds > 0) {
      return 'เหลืออีก $minutes นาที $seconds วินาที';
    }
    if (minutes > 0) {
      return 'เหลืออีก $minutes นาที';
    }
    return 'เหลืออีก $seconds วินาที';
  }
}
