import 'resolved_teacher_portal.dart';
import 'student_pin_verification_result.dart';
import 'student_portal_class_detail.dart';

/// Term selector option containing only terms where this student is enrolled.
class StudentPortalTermOption {
  const StudentPortalTermOption({
    required this.termId,
    required this.academicYearBe,
    required this.termLabel,
    this.startDate,
    this.endDate,
    required this.isPinnedActive,
  });

  final String termId;
  final int academicYearBe;
  final String termLabel;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isPinnedActive;

  String get displayLabel => 'เทอม $termLabel / ปีการศึกษา $academicYearBe';
}

/// Sanitized student identity header shown after PIN verification.
class StudentPortalStudentInfo {
  const StudentPortalStudentInfo({
    required this.studentCode,
    required this.prefix,
    required this.firstName,
    required this.lastName,
  });

  final String studentCode;
  final String prefix;
  final String firstName;
  final String lastName;

  String get fullName {
    final p = prefix.trim();
    final f = firstName.trim();
    final l = lastName.trim();
    final namePart = l.isEmpty ? f : '$f $l';
    return p.isEmpty ? namePart : '$p$namePart';
  }
}

/// Root payload returned by `public.get_student_portal_summary`.
///
/// Pure Dart entity with zero Flutter or Supabase dependencies.
class StudentPortalSummary {
  const StudentPortalSummary({
    required this.authorized,
    this.errorCode,
    this.errorMessage,
    this.lockedUntil,
    this.teacher,
    this.student,
    this.availableTerms = const <StudentPortalTermOption>[],
    this.selectedTermId,
    this.classes = const <StudentPortalClassDetail>[],
  });

  final bool authorized;
  final StudentPinErrorCode? errorCode;
  final String? errorMessage;
  final DateTime? lockedUntil;
  final ResolvedTeacherPortal? teacher;
  final StudentPortalStudentInfo? student;
  final List<StudentPortalTermOption> availableTerms;
  final String? selectedTermId;
  final List<StudentPortalClassDetail> classes;
}
