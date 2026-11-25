import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/domain/entities/attendance_rule_config.dart';
import '../../../attendance/domain/entities/attendance_session.dart';
import '../../../attendance/domain/repositories/attendance_repository.dart';
import '../../../grading/domain/entities/assignment.dart';
import '../../../grading/domain/entities/grading_scale_config.dart';
import '../../../grading/domain/entities/score_category.dart';
import '../../../grading/domain/entities/student_score.dart';
import '../../../grading/domain/repositories/grading_repository.dart';
import '../../../homeroom_roster/domain/entities/class_enrollment.dart';
import '../../../homeroom_roster/domain/repositories/homeroom_roster_repository.dart';
import '../../domain/entities/export_document_header.dart';
import '../../domain/entities/export_options.dart';
import '../../domain/entities/export_report_bundle.dart';
import '../../domain/repositories/export_reports_repository.dart';
import '../../domain/services/export_report_builder_service.dart';
import '../datasources/export_reports_local_datasource.dart';

/// Repository implementation composing existing Phase 2–4 repositories via
/// parallel `Future.wait` without duplicating PostgREST queries.
///
/// Automatically inherits Phase 6 Offline-First Drift caching once the
/// underlying repositories connect to Drift.
class ExportReportsRepositoryImpl implements ExportReportsRepository {
  const ExportReportsRepositoryImpl({
    required this._rosterRepository,
    required this._attendanceRepository,
    required this._gradingRepository,
    this._builderService = const ExportReportBuilderService(),
    this._localDataSource,
  });

  final HomeroomRosterRepository _rosterRepository;
  final AttendanceRepository _attendanceRepository;
  final GradingRepository _gradingRepository;
  final ExportReportBuilderService _builderService;
  // Reserved for Phase 6 Drift local caching.
  // ignore: unused_field
  final ExportReportsLocalDataSource? _localDataSource;

  @override
  Future<ExportRawClassData> fetchRawClassData(String subjectClassId) async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _rosterRepository.fetchClassEnrollments(subjectClassId),
      _attendanceRepository.fetchSessions(subjectClassId),
      _attendanceRepository.fetchRecordsByClass(subjectClassId),
      _attendanceRepository.fetchRuleConfig(subjectClassId),
      _gradingRepository.fetchScoreCategories(subjectClassId),
      _gradingRepository.fetchAssignments(subjectClassId),
      _gradingRepository.fetchStudentScoresByClass(subjectClassId),
      _gradingRepository.fetchGradingScaleConfig(subjectClassId),
    ]);

    return ExportRawClassData(
      subjectClassId: subjectClassId,
      enrollments: results[0] as List<ClassEnrollment>,
      attendanceSessions: results[1] as List<AttendanceSession>,
      attendanceRecords: results[2] as List<AttendanceRecord>,
      attendanceRuleConfig: results[3] as AttendanceRuleConfig,
      scoreCategories: results[4] as List<ScoreCategory>,
      assignments: results[5] as List<Assignment>,
      studentScores: results[6] as List<StudentScore>,
      gradingScaleConfig: results[7] as GradingScaleConfig,
    );
  }

  @override
  Future<ExportReportBundle> loadReportBundle({
    required String subjectClassId,
    required ExportDocumentHeader header,
    required ExportOptions options,
  }) async {
    final raw = await fetchRawClassData(subjectClassId);
    return _builderService.buildBundle(
      raw: raw,
      header: header,
      options: options,
    );
  }
}
