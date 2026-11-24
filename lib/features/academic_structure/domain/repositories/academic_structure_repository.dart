import '../entities/academic_year.dart';
import '../entities/delete_impact_summary.dart';
import '../entities/subject.dart';
import '../entities/subject_class.dart';
import '../entities/term.dart';

/// Abstract repository contract for the 4-level academic hierarchy
/// (`AcademicYear -> Term -> Subject -> SubjectClass`) and structural RPCs.
///
/// Pure Dart interface following the Repository Pattern.
abstract interface class AcademicStructureRepository {
  // Level 1: Academic Years
  Future<List<AcademicYear>> fetchAcademicYears();
  Future<AcademicYear> createAcademicYear({
    required String teacherId,
    required int yearBe,
  });
  Future<void> deleteAcademicYear(String academicYearId);

  // Level 2: Terms
  Future<List<Term>> fetchTerms({String? academicYearId});
  Future<Term> createTerm({
    required String teacherId,
    required String academicYearId,
    required String termLabel,
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<Term> updateTerm({
    required String termId,
    required String termLabel,
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<void> setPinnedActiveTerm(String? termId);
  Future<void> deleteTerm(String termId);

  // Level 3: Subjects
  Future<List<Subject>> fetchSubjects(String termId);
  Future<Subject> createSubject({
    required String teacherId,
    required String termId,
    required String subjectCode,
    required String subjectName,
  });
  Future<Subject> updateSubject({
    required String subjectId,
    required String subjectCode,
    required String subjectName,
  });
  Future<void> deleteSubject(String subjectId);

  // Level 4: Subject Classes
  Future<List<SubjectClass>> fetchSubjectClasses(String subjectId);
  Future<List<SubjectClass>> fetchSubjectClassesByTerm(String termId);
  Future<SubjectClass> createSubjectClass({
    required String teacherId,
    required String subjectId,
    String? homeroomId,
    required String roomName,
    List<int> teachingDays = const <int>[],
    bool isPinned = false,
    double? absentThresholdPct,
    int? missingWorkThreshold,
  });
  Future<SubjectClass> updateSubjectClass(SubjectClass subjectClass);
  Future<void> deleteSubjectClass(String subjectClassId);

  // Structural Deletion Impact RPC
  Future<DeleteImpactSummary> getDeleteImpactSummary({
    required StructuralEntityType entityType,
    required String entityId,
  });
}
