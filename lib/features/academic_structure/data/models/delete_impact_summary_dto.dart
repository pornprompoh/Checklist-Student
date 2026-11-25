import '../../domain/entities/delete_impact_summary.dart';

/// Data Transfer Object mapping the JSONB response of PostgreSQL RPC
/// `public.get_delete_impact_summary` to [DeleteImpactSummary].
class DeleteImpactSummaryDto {
  const DeleteImpactSummaryDto({
    required this.entityType,
    required this.entityId,
    required this.termsCount,
    required this.homeroomsCount,
    required this.subjectsCount,
    required this.subjectClassesCount,
    required this.studentsCount,
    required this.attendanceSessionsCount,
    required this.assignmentsCount,
    required this.scoredAssignmentsCount,
  });

  factory DeleteImpactSummaryDto.fromJson(Map<String, dynamic> json) {
    return DeleteImpactSummaryDto(
      entityType: StructuralEntityType.fromDbValue(
        json['entity_type'] as String,
      ),
      entityId: json['entity_id'] as String,
      termsCount: _parseInt(json['terms_count']),
      homeroomsCount: _parseInt(json['homerooms_count']),
      subjectsCount: _parseInt(json['subjects_count']),
      subjectClassesCount: _parseInt(json['subject_classes_count']),
      studentsCount: _parseInt(json['students_count']),
      attendanceSessionsCount: _parseInt(json['attendance_sessions_count']),
      assignmentsCount: _parseInt(json['assignments_count']),
      scoredAssignmentsCount: _parseInt(json['scored_assignments_count']),
    );
  }

  final StructuralEntityType entityType;
  final String entityId;
  final int termsCount;
  final int homeroomsCount;
  final int subjectsCount;
  final int subjectClassesCount;
  final int studentsCount;
  final int attendanceSessionsCount;
  final int assignmentsCount;
  final int scoredAssignmentsCount;

  DeleteImpactSummary toEntity() {
    return DeleteImpactSummary(
      entityType: entityType,
      entityId: entityId,
      termsCount: termsCount,
      homeroomsCount: homeroomsCount,
      subjectsCount: subjectsCount,
      subjectClassesCount: subjectClassesCount,
      studentsCount: studentsCount,
      attendanceSessionsCount: attendanceSessionsCount,
      assignmentsCount: assignmentsCount,
      scoredAssignmentsCount: scoredAssignmentsCount,
    );
  }

  static int _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
