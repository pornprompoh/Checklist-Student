/// Level 3 of the 4-level academic hierarchy (`public.subjects`).
///
/// Pure Dart entity.
class Subject {
  const Subject({
    required this.id,
    required this.teacherId,
    required this.termId,
    required this.subjectCode,
    required this.subjectName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String teacherId;
  final String termId;
  final String subjectCode;
  final String subjectName;
  final DateTime createdAt;
  final DateTime updatedAt;
}
