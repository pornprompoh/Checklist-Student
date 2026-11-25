import '../../../../core/constants/submission_status.dart';

/// Individual student score and submission state for an [Assignment].
///
/// Maps to `public.student_scores` including Optimistic Locking [version].
/// Pure Dart entity with zero Flutter or Supabase dependencies.
class StudentScore {
  const StudentScore({
    required this.id,
    required this.teacherId,
    required this.assignmentId,
    required this.enrollmentId,
    required this.submissionStatus,
    this.score,
    this.note = '',
    this.version = 1,
    required this.updatedAt,
  });

  final String id;
  final String teacherId;
  final String assignmentId;
  final String enrollmentId;
  final SubmissionStatus submissionStatus;
  final double? score;
  final String note;
  final int version;
  final DateTime updatedAt;

  static const Object _sentinel = Object();

  StudentScore copyWith({
    String? id,
    String? teacherId,
    String? assignmentId,
    String? enrollmentId,
    SubmissionStatus? submissionStatus,
    Object? score = _sentinel,
    String? note,
    int? version,
    DateTime? updatedAt,
  }) {
    return StudentScore(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      assignmentId: assignmentId ?? this.assignmentId,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      score: identical(score, _sentinel) ? this.score : score as double?,
      note: note ?? this.note,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
