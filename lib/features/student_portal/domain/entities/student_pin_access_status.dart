/// Pre-PIN access check result returned by `public.check_student_portal_access`.
///
/// Intentionally contains zero student PII (`first_name`/`last_name`) and zero
/// `pin_hash` data prior to 6-digit PIN verification. Pure Dart entity.
class StudentPinAccessStatus {
  const StudentPinAccessStatus({
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

  /// Returns `true` when the student exists and must set a 6-digit PIN for
  /// the first time (or after a teacher PIN reset).
  bool get requiresInitialPinSetup => teacherFound && studentFound && !hasPin;
}
