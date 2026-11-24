/// Structural hierarchy target types accepted by PostgreSQL RPC
/// `public.get_delete_impact_summary(p_entity_type, p_entity_id)`.
enum StructuralEntityType {
  academicYear('academic_year'),
  term('term'),
  subject('subject'),
  subjectClass('subject_class');

  const StructuralEntityType(this.dbValue);

  final String dbValue;

  static StructuralEntityType fromDbValue(String value) {
    for (final type in StructuralEntityType.values) {
      if (type.dbValue == value) {
        return type;
      }
    }
    throw ArgumentError.value(
      value,
      'value',
      'Unknown structural entity type',
    );
  }
}

/// Real cascading deletion impact counts returned by
/// `public.get_delete_impact_summary`. Pure Dart entity.
class DeleteImpactSummary {
  const DeleteImpactSummary({
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
}
