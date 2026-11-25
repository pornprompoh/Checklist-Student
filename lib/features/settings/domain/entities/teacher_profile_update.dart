/// Immutable value object carrying editable teacher profile fields and
/// default classroom risk thresholds for `public.teachers`.
///
/// Pure Dart entity with zero Flutter or Supabase dependencies.
class TeacherProfileUpdate {
  const TeacherProfileUpdate({
    required this.displayName,
    required this.schoolName,
    required this.department,
    required this.defaultAbsentThresholdPct,
    required this.defaultMissingWorkThreshold,
  });

  final String displayName;
  final String schoolName;
  final String department;
  final double defaultAbsentThresholdPct;
  final int defaultMissingWorkThreshold;
}
