/// Public teacher metadata resolved via `public.resolve_teacher_code` for the
/// unauthenticated Student Portal (`/student/:teacherCode`).
///
/// Pure Dart entity with zero Flutter or Supabase dependencies.
class ResolvedTeacherPortal {
  const ResolvedTeacherPortal({
    required this.found,
    required this.isRedirected,
    required this.requestedCode,
    this.currentTeacherCode,
    this.teacherDisplayName,
    this.schoolName,
    this.department,
  });

  final bool found;
  final bool isRedirected;
  final String requestedCode;
  final String? currentTeacherCode;
  final String? teacherDisplayName;
  final String? schoolName;
  final String? department;

  /// Effective teacher display label when teacher profile name is blank.
  String get effectiveTeacherName {
    final name = teacherDisplayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return currentTeacherCode ?? requestedCode;
  }
}
