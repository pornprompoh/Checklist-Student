import '../../../../core/constants/submission_status.dart';
import '../../domain/entities/student_score.dart';

/// Data Transfer Object mapping `public.student_scores` rows to [StudentScore].
class StudentScoreDto {
  const StudentScoreDto({
    required this.id,
    required this.teacherId,
    required this.assignmentId,
    required this.enrollmentId,
    required this.submissionStatus,
    required this.score,
    required this.note,
    required this.version,
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

  factory StudentScoreDto.fromJson(Map<String, dynamic> json) {
    final rawScore = json['score'];
    return StudentScoreDto(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      assignmentId: json['assignment_id'] as String,
      enrollmentId: json['enrollment_id'] as String,
      submissionStatus: SubmissionStatus.fromDbValue(
        (json['submission_status'] as String?) ??
            SubmissionStatus.missing.dbValue,
      ),
      score: rawScore == null ? null : (rawScore as num).toDouble(),
      note: (json['note'] as String?) ?? '',
      version: (json['version'] as num?)?.toInt() ?? 1,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  StudentScore toEntity() {
    return StudentScore(
      id: id,
      teacherId: teacherId,
      assignmentId: assignmentId,
      enrollmentId: enrollmentId,
      submissionStatus: submissionStatus,
      score: score,
      note: note,
      version: version,
      updatedAt: updatedAt,
    );
  }
}
