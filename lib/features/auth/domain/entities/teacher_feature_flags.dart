/// Read-only feature flags for a teacher from `public.teacher_feature_flags`.
///
/// Pure Dart entity. `canUseAi` is controlled exclusively by the project owner
/// in Supabase Dashboard and cannot be modified by teachers via RLS.
class TeacherFeatureFlags {
  const TeacherFeatureFlags({
    required this.teacherId,
    required this.canUseAi,
    required this.updatedAt,
  });

  final String teacherId;
  final bool canUseAi;
  final DateTime updatedAt;
}
