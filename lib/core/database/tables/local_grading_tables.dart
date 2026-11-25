import 'package:drift/drift.dart';

/// Structured local Drift mirror of `public.student_scores` preserving exact
/// decimal scores and Optimistic Locking (`version`) for offline grade entry.
class LocalStudentScores extends Table {
  TextColumn get id => text()();
  TextColumn get teacherId => text()();
  TextColumn get assignmentId => text()();
  TextColumn get enrollmentId => text()();
  TextColumn get subjectClassId => text()();
  TextColumn get submissionStatus =>
      text().withDefault(const Constant('missing'))();
  RealColumn get score => real().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {assignmentId, enrollmentId},
  ];
}
