import '../entities/export_document_header.dart';
import '../entities/export_options.dart';
import '../entities/export_report_bundle.dart';

/// Repository contract loading raw class data and assembling
/// [ExportReportBundle] across roster, attendance, and grading repositories.
///
/// Pure Dart interface.
abstract interface class ExportReportsRepository {
  Future<ExportRawClassData> fetchRawClassData(String subjectClassId);

  Future<ExportReportBundle> loadReportBundle({
    required String subjectClassId,
    required ExportDocumentHeader header,
    required ExportOptions options,
  });
}
