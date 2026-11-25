import 'student_lifecycle_status.dart';

/// Master roster student record belonging to a term-level [Homeroom]
/// (`public.homeroom_students`).
///
/// Pure Dart entity.
class HomeroomStudent {
  const HomeroomStudent({
    required this.id,
    required this.teacherId,
    required this.homeroomId,
    required this.studentIdentityId,
    required this.studentCode,
    required this.studentNumber,
    required this.prefix,
    required this.firstName,
    required this.lastName,
    required this.status,
    required this.transferredOutAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String teacherId;
  final String homeroomId;
  final String studentIdentityId;
  final String studentCode;
  final int studentNumber;
  final String prefix;
  final String firstName;
  final String lastName;
  final StudentLifecycleStatus status;
  final DateTime? transferredOutAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTransferredOut => status == StudentLifecycleStatus.transferredOut;

  /// Concatenated Thai display name (`prefix` + `firstName` + `lastName`).
  String get fullName {
    final p = prefix.trim();
    final f = firstName.trim();
    final l = lastName.trim();
    final namePart = l.isEmpty ? f : '$f $l';
    return p.isEmpty ? namePart : '$p$namePart';
  }
}
