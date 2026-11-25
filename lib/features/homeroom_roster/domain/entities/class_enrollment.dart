import 'student_lifecycle_status.dart';

/// Student enrollment bound to a specific Subject + Room (`public.class_enrollments`).
///
/// Includes [enrolledAt] (for mid-term additions), [transferredOutAt] (soft delete),
/// and [version] for Optimistic Locking. Pure Dart entity.
class ClassEnrollment {
  const ClassEnrollment({
    required this.id,
    required this.teacherId,
    required this.subjectClassId,
    required this.homeroomStudentId,
    required this.studentIdentityId,
    required this.studentCode,
    required this.studentNumber,
    required this.prefix,
    required this.firstName,
    required this.lastName,
    required this.status,
    required this.enrolledAt,
    required this.transferredOutAt,
    required this.specialGradeOverride,
    required this.wasRResolved,
    required this.wasMsResolved,
    required this.resolvedGradeAt,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String teacherId;
  final String subjectClassId;
  final String? homeroomStudentId;
  final String studentIdentityId;
  final String studentCode;
  final int studentNumber;
  final String prefix;
  final String firstName;
  final String lastName;
  final StudentLifecycleStatus status;
  final DateTime enrolledAt;
  final DateTime? transferredOutAt;
  final String? specialGradeOverride;
  final bool wasRResolved;
  final bool wasMsResolved;
  final DateTime? resolvedGradeAt;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTransferredOut => status == StudentLifecycleStatus.transferredOut;
  bool get isLinkedToHomeroom => homeroomStudentId != null;

  /// Concatenated Thai display name (`prefix` + `firstName` + `lastName`).
  String get fullName {
    final p = prefix.trim();
    final f = firstName.trim();
    final l = lastName.trim();
    final namePart = l.isEmpty ? f : '$f $l';
    return p.isEmpty ? namePart : '$p$namePart';
  }
}
