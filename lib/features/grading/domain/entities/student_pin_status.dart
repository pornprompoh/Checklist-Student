/// Safe student Portal PIN status summary derived from `public.student_identities`.
///
/// Pure Dart entity. NEVER exposes raw `pin_hash` strings to Domain or UI layers.
class StudentPinStatus {
  const StudentPinStatus({
    required this.studentIdentityId,
    required this.hasPin,
    required this.failedAttempts,
    this.lockedUntil,
    this.pinUpdatedAt,
  });

  final String studentIdentityId;
  final bool hasPin;
  final int failedAttempts;
  final DateTime? lockedUntil;
  final DateTime? pinUpdatedAt;

  /// Returns `true` when [lockedUntil] is set and strictly in the future.
  bool isCurrentlyLocked({DateTime? now}) {
    final until = lockedUntil;
    if (until == null) return false;
    final reference = now ?? DateTime.now().toUtc();
    return until.isAfter(reference);
  }
}
