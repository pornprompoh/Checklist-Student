import '../../domain/entities/class_enrollment.dart';
import '../../domain/entities/homeroom.dart';
import '../../domain/entities/homeroom_student.dart';

/// Local Drift cache contract for Homeroom Roster & Class Enrollments.
abstract interface class HomeroomRosterLocalDataSource {
  Future<void> saveHomerooms(
    String teacherId,
    String termId,
    List<Homeroom> homerooms,
  );

  Future<List<Homeroom>?> readHomerooms(String teacherId, String termId);

  Future<void> saveHomeroomStudents(
    String teacherId,
    String homeroomId,
    List<HomeroomStudent> students,
  );

  Future<List<HomeroomStudent>?> readHomeroomStudents(
    String teacherId,
    String homeroomId,
  );

  Future<void> saveClassEnrollments(
    String teacherId,
    String subjectClassId,
    List<ClassEnrollment> enrollments,
  );

  Future<List<ClassEnrollment>?> readClassEnrollments(
    String teacherId,
    String subjectClassId,
  );

  /// Updates the cached `special_grade_override` / resolution flags / version
  /// for [enrollmentId] when changed offline or resolved from a server snapshot.
  Future<void> patchCachedEnrollmentSpecialGrade({
    required String teacherId,
    required String enrollmentId,
    required String? specialGradeOverride,
    bool? wasRResolved,
    bool? wasMsResolved,
    int? version,
    DateTime? resolvedGradeAt,
  });
}
