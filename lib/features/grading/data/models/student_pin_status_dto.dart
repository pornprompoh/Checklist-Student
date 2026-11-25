import '../../domain/entities/student_pin_status.dart';

/// Data Transfer Object reading `public.student_identities` PIN metadata.
///
/// Converts `pin_hash != null` immediately into a boolean [hasPin] so raw
/// password hashes never leave the Data Layer.
class StudentPinStatusDto {
  const StudentPinStatusDto({
    required this.studentIdentityId,
    required this.hasPin,
    required this.failedAttempts,
    required this.lockedUntil,
    required this.pinUpdatedAt,
  });

  final String studentIdentityId;
  final bool hasPin;
  final int failedAttempts;
  final DateTime? lockedUntil;
  final DateTime? pinUpdatedAt;

  factory StudentPinStatusDto.fromJson(Map<String, dynamic> json) {
    final rawHash = json['pin_hash'];
    final hasPin =
        rawHash != null && (rawHash is! String || rawHash.trim().isNotEmpty);
    final rawLocked = json['locked_until'] as String?;
    final rawUpdated = json['pin_updated_at'] as String?;

    return StudentPinStatusDto(
      studentIdentityId: json['id'] as String,
      hasPin: hasPin,
      failedAttempts: (json['failed_attempts'] as num?)?.toInt() ?? 0,
      lockedUntil: rawLocked == null ? null : DateTime.tryParse(rawLocked),
      pinUpdatedAt: rawUpdated == null ? null : DateTime.tryParse(rawUpdated),
    );
  }

  StudentPinStatus toEntity() {
    return StudentPinStatus(
      studentIdentityId: studentIdentityId,
      hasPin: hasPin,
      failedAttempts: failedAttempts,
      lockedUntil: lockedUntil,
      pinUpdatedAt: pinUpdatedAt,
    );
  }
}
