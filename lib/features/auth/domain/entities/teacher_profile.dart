/// Domain entity representing a teacher profile from `public.teachers`.
///
/// Pure Dart class with zero Flutter or Supabase dependencies.
class TeacherProfile {
  const TeacherProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.schoolName,
    required this.department,
    required this.teacherCode,
    required this.defaultAbsentThresholdPct,
    required this.defaultMissingWorkThreshold,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String schoolName;
  final String department;
  final String teacherCode;
  final double defaultAbsentThresholdPct;
  final int defaultMissingWorkThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns [displayName] if non-empty, otherwise falls back to [email].
  String get effectiveDisplayName {
    final trimmed = displayName.trim();
    return trimmed.isNotEmpty ? trimmed : email;
  }

  TeacherProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? schoolName,
    String? department,
    String? teacherCode,
    double? defaultAbsentThresholdPct,
    int? defaultMissingWorkThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeacherProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      schoolName: schoolName ?? this.schoolName,
      department: department ?? this.department,
      teacherCode: teacherCode ?? this.teacherCode,
      defaultAbsentThresholdPct:
          defaultAbsentThresholdPct ?? this.defaultAbsentThresholdPct,
      defaultMissingWorkThreshold:
          defaultMissingWorkThreshold ?? this.defaultMissingWorkThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
