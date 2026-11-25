import '../../domain/entities/academic_year.dart';
import '../../domain/entities/subject.dart';
import '../../domain/entities/subject_class.dart';
import '../../domain/entities/term.dart';

/// Local Drift cache contract for Academic Structure offline read-through.
abstract interface class AcademicStructureLocalDataSource {
  Future<void> saveAcademicYears(String teacherId, List<AcademicYear> years);

  Future<List<AcademicYear>?> readAcademicYears(String teacherId);

  Future<void> saveTerms(
    String teacherId,
    List<Term> terms, {
    String? academicYearId,
  });

  Future<List<Term>?> readTerms(String teacherId, {String? academicYearId});

  Future<void> saveSubjects(
    String teacherId,
    String termId,
    List<Subject> subjects,
  );

  Future<List<Subject>?> readSubjects(String teacherId, String termId);

  Future<void> saveSubjectClasses(
    String teacherId,
    String subjectId,
    List<SubjectClass> classes,
  );

  Future<List<SubjectClass>?> readSubjectClasses(
    String teacherId,
    String subjectId,
  );

  Future<void> saveSubjectClassesByTerm(
    String teacherId,
    String termId,
    List<SubjectClass> classes,
  );

  Future<List<SubjectClass>?> readSubjectClassesByTerm(
    String teacherId,
    String termId,
  );
}
