import 'package:drift/drift.dart';

/// Structured local Drift mirror of `public.attendance_sessions` for fast
/// offline classroom attendance checking with Optimistic Locking (`version`).
class LocalAttendanceSessions extends Table {
  TextColumn get id => text()();
  TextColumn get teacherId => text()();
  TextColumn get subjectClassId => text()();
  TextColumn get sessionDateIso => text()();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {subjectClassId, sessionDateIso},
  ];
}

/// Structured local Drift mirror of `public.attendance_records` aligned with
/// Supabase columns and Optimistic Locking (`version`).
class LocalAttendanceRecords extends Table {
  TextColumn get id => text()();
  TextColumn get teacherId => text()();
  TextColumn get sessionId => text()();
  TextColumn get enrollmentId => text()();
  TextColumn get status => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {sessionId, enrollmentId},
  ];
}
