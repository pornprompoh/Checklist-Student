/// Level 2 of the 4-level academic hierarchy (`public.terms`).
///
/// [startDate] and [endDate] map to ISO `DATE` columns in PostgreSQL.
/// Pure Dart entity.
class Term {
  const Term({
    required this.id,
    required this.teacherId,
    required this.academicYearId,
    required this.termLabel,
    required this.startDate,
    required this.endDate,
    required this.isPinnedActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String teacherId;
  final String academicYearId;
  final String termLabel;
  final DateTime startDate;
  final DateTime endDate;
  final bool isPinnedActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
