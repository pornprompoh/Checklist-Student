import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/class_enrollment.dart';
import '../../domain/entities/student_lifecycle_status.dart';

/// Data Transfer Object mapping `public.class_enrollments` rows to
/// [ClassEnrollment], preserving `version` and ISO date fields.
class ClassEnrollmentDto {
  const ClassEnrollmentDto({
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

  factory ClassEnrollmentDto.fromJson(Map<String, dynamic> json) {
    final fallbackDate = DateTime.now();
    return ClassEnrollmentDto(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      subjectClassId: json['subject_class_id'] as String,
      homeroomStudentId: json['homeroom_student_id'] as String?,
      studentIdentityId: json['student_identity_id'] as String,
      studentCode: (json['student_code'] as String?) ?? '',
      studentNumber: (json['student_number'] as num).toInt(),
      prefix: (json['prefix'] as String?) ?? '',
      firstName: (json['first_name'] as String?) ?? '',
      lastName: (json['last_name'] as String?) ?? '',
      status: StudentLifecycleStatus.fromDbValue(
        (json['status'] as String?) ?? 'active',
      ),
      enrolledAt:
          ThaiDateFormatter.parseIsoDate(json['enrolled_at'] as String?) ??
          DateTime(fallbackDate.year, fallbackDate.month, fallbackDate.day),
      transferredOutAt: ThaiDateFormatter.parseIsoDate(
        json['transferred_out_at'] as String?,
      ),
      specialGradeOverride: json['special_grade_override'] as String?,
      wasRResolved: (json['was_r_resolved'] as bool?) ?? false,
      wasMsResolved: (json['was_ms_resolved'] as bool?) ?? false,
      resolvedGradeAt: _parseNullableTimestamp(json['resolved_grade_at']),
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt: _parseTimestamp(json['created_at']),
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

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

  ClassEnrollment toEntity() {
    return ClassEnrollment(
      id: id,
      teacherId: teacherId,
      subjectClassId: subjectClassId,
      homeroomStudentId: homeroomStudentId,
      studentIdentityId: studentIdentityId,
      studentCode: studentCode,
      studentNumber: studentNumber,
      prefix: prefix,
      firstName: firstName,
      lastName: lastName,
      status: status,
      enrolledAt: enrolledAt,
      transferredOutAt: transferredOutAt,
      specialGradeOverride: specialGradeOverride,
      wasRResolved: wasRResolved,
      wasMsResolved: wasMsResolved,
      resolvedGradeAt: resolvedGradeAt,
      version: version,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime _parseTimestamp(Object? value) {
    return _parseNullableTimestamp(value) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _parseNullableTimestamp(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
