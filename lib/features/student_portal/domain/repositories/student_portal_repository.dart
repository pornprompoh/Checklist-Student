import '../entities/resolved_teacher_portal.dart';
import '../entities/student_pin_access_status.dart';
import '../entities/student_pin_verification_result.dart';
import '../entities/student_portal_summary.dart';

/// Abstract repository contract for the Student Portal feature.
///
/// Backed exclusively by `SECURITY DEFINER` RPCs — never direct table queries.
/// Pure Dart interface with zero Flutter or Supabase dependencies.
abstract interface class StudentPortalRepository {
  /// Resolves a teacher's current or archived short code for `/student/:teacherCode`.
  Future<ResolvedTeacherPortal> resolveTeacherCode(String teacherCode);

  /// Checks whether [studentCode] exists for [teacherCode] and whether a PIN
  /// is already configured or temporarily locked.
  Future<StudentPinAccessStatus> checkStudentAccess({
    required String teacherCode,
    required String studentCode,
  });

  /// Sets an initial 6-digit PIN (`mode = setup`) or verifies an existing PIN
  /// (`mode = verify`) with 5-attempt / 15-minute lockout enforcement.
  Future<StudentPinVerificationResult> verifyOrSetPin({
    required String teacherCode,
    required String studentCode,
    required String pin,
    StudentPinAuthMode mode = StudentPinAuthMode.verify,
  });

  /// Re-verifies [pin] server-side and returns the student's own attendance,
  /// assignments, masked/visible scores, and masked/visible grades.
  Future<StudentPortalSummary> fetchPortalSummary({
    required String teacherCode,
    required String studentCode,
    required String pin,
    String? termId,
  });
}
