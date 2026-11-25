/// Level 1 of the 4-level academic hierarchy (`public.academic_years`).
///
/// Stores the Thai Buddhist Era year ([yearBe], e.g. `2569`). Pure Dart entity.
class AcademicYear {
  const AcademicYear({
    required this.id,
    required this.teacherId,
    required this.yearBe,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String teacherId;
  final int yearBe;
  final DateTime createdAt;
  final DateTime updatedAt;
}
