import 'package:drift/drift.dart';

/// Multi-tenant JSON snapshot cache for frequently read teacher entities
/// (academic years, terms, subjects, classes, homeroom rosters, dashboard,
/// grading plans).
class LocalEntityCaches extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get teacherId => text()();
  TextColumn get entityGroup => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {teacherId, cacheKey};
}
