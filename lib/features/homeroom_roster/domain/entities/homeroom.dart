/// Term-level shared homeroom master roster (`public.homerooms`).
///
/// Pure Dart entity.
class Homeroom {
  const Homeroom({
    required this.id,
    required this.teacherId,
    required this.termId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String teacherId;
  final String termId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
}
