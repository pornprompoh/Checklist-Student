import '../../domain/entities/resolved_teacher_portal.dart';

/// JSON DTO for `public.resolve_teacher_code(p_teacher_code)`.
class ResolvedTeacherPortalDto {
  const ResolvedTeacherPortalDto({
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

  factory ResolvedTeacherPortalDto.fromJson(Map<String, dynamic> json) {
    return ResolvedTeacherPortalDto(
      found: json['found'] as bool? ?? false,
      isRedirected: json['is_redirected'] as bool? ?? false,
      requestedCode: (json['requested_code'] as String? ?? '').trim(),
      currentTeacherCode: _optionalString(json['current_teacher_code']),
      teacherDisplayName: _optionalString(json['teacher_display_name']),
      schoolName: _optionalString(json['school_name']),
      department: _optionalString(json['department']),
    );
  }

  ResolvedTeacherPortal toEntity() {
    return ResolvedTeacherPortal(
      found: found,
      isRedirected: isRedirected,
      requestedCode: requestedCode,
      currentTeacherCode: currentTeacherCode,
      teacherDisplayName: teacherDisplayName,
      schoolName: schoolName,
      department: department,
    );
  }

  static String? _optionalString(Object? value) {
    if (value is! String) return null;
    return value;
  }
}
