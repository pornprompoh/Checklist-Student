/// Immutable domain entity representing a historical teacher code entry from
/// `public.teacher_code_history` used for automatic Student Portal redirects.
///
/// Pure Dart entity with zero Flutter or Supabase dependencies.
class TeacherCodeHistoryEntry {
  const TeacherCodeHistoryEntry({
    required this.oldCode,
    required this.teacherId,
    required this.changedAt,
  });

  final String oldCode;
  final String teacherId;
  final DateTime changedAt;
}
