import 'dart:typed_data';

import '../entities/class_enrollment.dart';
import '../entities/homeroom.dart';
import '../entities/homeroom_student.dart';
import '../entities/roster_import_result.dart';
import '../entities/roster_import_row_preview.dart';
import '../entities/student_lifecycle_status.dart';
import '../entities/uploaded_import_file.dart';
import '../services/roster_renumber_service.dart';

/// Abstract repository contract for term-level homeroom master rosters,
/// subject-class enrollment linking, mid-term additions, soft deletes,
/// renumbering, and cross-class sync via `sync_homeroom_student_update`.
///
/// Pure Dart interface following the Repository Pattern.
abstract interface class HomeroomRosterRepository {
  // Homerooms
  Future<List<Homeroom>> fetchHomerooms(String termId);
  Future<Homeroom> createHomeroom({
    required String teacherId,
    required String termId,
    required String name,
  });
  Future<Homeroom> renameHomeroom({
    required String homeroomId,
    required String name,
  });
  Future<void> deleteHomeroom(String homeroomId);

  // Homeroom Master Students
  Future<List<HomeroomStudent>> fetchHomeroomStudents(String homeroomId);
  Future<HomeroomStudent> addHomeroomStudent({
    required String teacherId,
    required String homeroomId,
    required String studentCode,
    required int studentNumber,
    required String prefix,
    required String firstName,
    required String lastName,
  });
  Future<int> updateHomeroomStudent({
    required String homeroomStudentId,
    required String teacherId,
    required String studentCode,
    required int studentNumber,
    required String prefix,
    required String firstName,
    required String lastName,
    required bool syncLinkedClasses,
  });
  Future<int> setHomeroomStudentStatus({
    required String homeroomStudentId,
    required StudentLifecycleStatus status,
    DateTime? transferredOutAt,
    required bool syncLinkedClasses,
  });
  Future<int> renumberHomeroomStudents({
    required List<RenumberAssignment> assignments,
    required bool syncLinkedClasses,
  });
  Future<RosterImportResult> importHomeroomStudents({
    required String teacherId,
    required String homeroomId,
    required List<RosterImportRowPreview> rows,
    required bool syncOverwrittenToLinkedClasses,
  });
  Future<UploadedImportFileResult> uploadAndParseRosterWithAi({
    required String teacherId,
    required String academicYearId,
    required String homeroomId,
    required String originalFilename,
    required Uint8List compressedBytes,
    required String mimeType,
    required String fileExtension,
  });

  // Linking & Subject-Class Enrollments
  Future<int> linkHomeroomToSubjectClasses({
    required String teacherId,
    required String homeroomId,
    required List<String> subjectClassIds,
    required DateTime enrolledAt,
  });
  Future<List<ClassEnrollment>> fetchClassEnrollments(String subjectClassId);
  Future<ClassEnrollment> addClassEnrollmentMidTerm({
    required String teacherId,
    required String subjectClassId,
    String? addToHomeroomId,
    required String studentCode,
    required int studentNumber,
    required String prefix,
    required String firstName,
    required String lastName,
    required DateTime enrolledAt,
  });
  Future<int> updateClassEnrollment({
    required ClassEnrollment existing,
    required String studentCode,
    required int studentNumber,
    required String prefix,
    required String firstName,
    required String lastName,
    required DateTime enrolledAt,
    required bool syncToHomeroomAndAllClasses,
  });
  Future<int> setClassEnrollmentStatus({
    required ClassEnrollment existing,
    required StudentLifecycleStatus status,
    DateTime? transferredOutAt,
    required bool syncToHomeroomAndAllClasses,
  });
  Future<void> renumberClassEnrollments({
    required List<ClassEnrollment> currentEnrollments,
    required List<RenumberAssignment> assignments,
  });
}
