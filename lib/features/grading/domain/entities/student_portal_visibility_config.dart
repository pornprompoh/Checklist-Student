/// Per-subject-class Student Portal visibility switches stored on
/// `public.subject_classes` (`show_score_to_student`, `show_grade_to_student`).
///
/// Pure Dart entity with zero Flutter or Supabase dependencies.
class StudentPortalVisibilityConfig {
  const StudentPortalVisibilityConfig({
    required this.subjectClassId,
    required this.showScoreToStudent,
    required this.showGradeToStudent,
  });

  final String subjectClassId;
  final bool showScoreToStudent;
  final bool showGradeToStudent;

  StudentPortalVisibilityConfig copyWith({
    bool? showScoreToStudent,
    bool? showGradeToStudent,
  }) {
    return StudentPortalVisibilityConfig(
      subjectClassId: subjectClassId,
      showScoreToStudent: showScoreToStudent ?? this.showScoreToStudent,
      showGradeToStudent: showGradeToStudent ?? this.showGradeToStudent,
    );
  }
}
