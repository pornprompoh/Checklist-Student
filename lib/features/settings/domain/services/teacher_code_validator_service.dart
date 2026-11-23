/// Pure Dart validator for `public.teachers.teacher_code`.
///
/// Matches the PostgreSQL constraint `CHECK (teacher_code ~ '^[a-z0-9-]{3,30}$')`.
abstract final class TeacherCodeValidatorService {
  static const int minLength = 3;
  static const int maxLength = 30;

  static final RegExp _allowedPattern = RegExp(r'^[a-z0-9-]{3,30}$');

  /// Normalizes user input by trimming whitespace and converting to lowercase.
  static String normalize(String raw) => raw.trim().toLowerCase();

  /// Validates [raw] after normalization.
  ///
  /// Returns a Thai error message when invalid, or `null` when valid.
  static String? validate(String raw) {
    final normalized = normalize(raw);
    if (normalized.isEmpty) {
      return 'กรุณากรอกรหัสครู';
    }
    if (normalized.length < minLength) {
      return 'รหัสครูต้องมีความยาวอย่างน้อย $minLength ตัวอักษร';
    }
    if (normalized.length > maxLength) {
      return 'รหัสครูต้องมีความยาวไม่เกิน $maxLength ตัวอักษร';
    }
    if (!_allowedPattern.hasMatch(normalized)) {
      return 'ใช้ได้เฉพาะตัวอักษรภาษาอังกฤษ (a-z), ตัวเลข (0-9) และขีดกลาง (-) เท่านั้น';
    }
    return null;
  }
}
