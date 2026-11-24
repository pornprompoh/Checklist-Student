import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/homeroom_student.dart';
import '../../domain/entities/student_lifecycle_status.dart';

/// Data Transfer Object mapping `public.homeroom_students` rows to
/// [HomeroomStudent].
class HomeroomStudentDto {
  const HomeroomStudentDto({
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

  factory HomeroomStudentDto.fromJson(Map<String, dynamic> json) {
    return HomeroomStudentDto(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      homeroomId: json['homeroom_id'] as String,
      studentIdentityId: json['student_identity_id'] as String,
      studentCode: (json['student_code'] as String?) ?? '',
      studentNumber: (json['student_number'] as num).toInt(),
      prefix: (json['prefix'] as String?) ?? '',
      firstName: (json['first_name'] as String?) ?? '',
      lastName: (json['last_name'] as String?) ?? '',
      status: StudentLifecycleStatus.fromDbValue(
        (json['status'] as String?) ?? 'active',
      ),
      transferredOutAt: ThaiDateFormatter.parseIsoDate(
        json['transferred_out_at'] as String?,
      ),
      createdAt: _parseTimestamp(json['created_at']),
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

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

  HomeroomStudent toEntity() {
    return HomeroomStudent(
      id: id,
      teacherId: teacherId,
      homeroomId: homeroomId,
      studentIdentityId: studentIdentityId,
      studentCode: studentCode,
      studentNumber: studentNumber,
      prefix: prefix,
      firstName: firstName,
      lastName: lastName,
      status: status,
      transferredOutAt: transferredOutAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime _parseTimestamp(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
