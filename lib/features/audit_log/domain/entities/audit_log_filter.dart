import 'audit_log_target_type.dart';
import 'score_audit_log_entry.dart';

/// Immutable filter criteria for `AuditLogPage`. Pure Dart.
class AuditLogFilter {
  const AuditLogFilter({
    this.academicYearId,
    this.subjectClassId,
    this.enrollmentId,
    this.targetType,
    this.searchQuery = '',
  });

  final String? academicYearId;
  final String? subjectClassId;
  final String? enrollmentId;
  final AuditLogTargetType? targetType;
  final String searchQuery;

  static const Object _sentinel = Object();

  AuditLogFilter copyWith({
    Object? academicYearId = _sentinel,
    Object? subjectClassId = _sentinel,
    Object? enrollmentId = _sentinel,
    Object? targetType = _sentinel,
    String? searchQuery,
  }) {
    return AuditLogFilter(
      academicYearId: identical(academicYearId, _sentinel)
          ? this.academicYearId
          : academicYearId as String?,
      subjectClassId: identical(subjectClassId, _sentinel)
          ? this.subjectClassId
          : subjectClassId as String?,
      enrollmentId: identical(enrollmentId, _sentinel)
          ? this.enrollmentId
          : enrollmentId as String?,
      targetType: identical(targetType, _sentinel)
          ? this.targetType
          : targetType as AuditLogTargetType?,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Client-side search match against student name, student code, student
  /// number, assignment title, subject code/name, and room name.
  bool matchesSearch(ScoreAuditLogEntry entry) {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return true;
    return entry.studentFullName.toLowerCase().contains(q) ||
        entry.studentCode.toLowerCase().contains(q) ||
        entry.studentNumber.toString() == q ||
        (entry.assignmentTitle?.toLowerCase().contains(q) ?? false) ||
        entry.subjectCode.toLowerCase().contains(q) ||
        entry.subjectName.toLowerCase().contains(q) ||
        entry.roomName.toLowerCase().contains(q);
  }
}
