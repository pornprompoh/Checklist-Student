import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../grading/presentation/providers/grading_providers.dart';
import '../../../homeroom_roster/presentation/providers/homeroom_roster_providers.dart';
import '../../data/datasources/sarabun_pdf_font_loader.dart';
import '../../data/repositories/export_reports_repository_impl.dart';
import '../../domain/entities/export_report_bundle.dart';
import '../../domain/repositories/export_reports_repository.dart';
import '../../domain/services/docx_report_generator_service.dart';
import '../../domain/services/excel_report_generator_service.dart';
import '../../domain/services/export_layout_advisor_service.dart';
import '../../domain/services/export_report_builder_service.dart';
import '../../domain/services/pdf_report_generator_service.dart';

final excelReportGeneratorServiceProvider =
    Provider<ExcelReportGeneratorService>(
      (ref) => const ExcelReportGeneratorService(),
    );

final pdfReportGeneratorServiceProvider = Provider<PdfReportGeneratorService>(
  (ref) => const PdfReportGeneratorService(),
);

final docxReportGeneratorServiceProvider = Provider<DocxReportGeneratorService>(
  (ref) => const DocxReportGeneratorService(),
);

final sarabunPdfFontLoaderProvider = Provider<SarabunPdfFontLoader>(
  (ref) => SarabunPdfFontLoader(),
);

final exportLayoutAdvisorServiceProvider = Provider<ExportLayoutAdvisorService>(
  (ref) => const ExportLayoutAdvisorService(),
);

final exportReportBuilderServiceProvider = Provider<ExportReportBuilderService>(
  (ref) => ExportReportBuilderService(
    attendanceStatsService: ref.watch(attendanceStatisticsServiceProvider),
    scoreCalculatorService: ref.watch(scoreCalculatorServiceProvider),
    gradeEvaluatorService: ref.watch(gradeEvaluatorServiceProvider),
    specialGradeAdvisorService: ref.watch(specialGradeAdvisorServiceProvider),
    layoutAdvisorService: ref.watch(exportLayoutAdvisorServiceProvider),
  ),
);

final exportReportsRepositoryProvider = Provider<ExportReportsRepository>((
  ref,
) {
  return ExportReportsRepositoryImpl(
    rosterRepository: ref.watch(homeroomRosterRepositoryProvider),
    attendanceRepository: ref.watch(attendanceRepositoryProvider),
    gradingRepository: ref.watch(gradingRepositoryProvider),
    builderService: ref.watch(exportReportBuilderServiceProvider),
  );
});

/// Fetches raw class data once per [subjectClassId] so live header/option edits
/// recompute [ExportReportBundle] purely in memory with zero extra DB calls.
final exportRawClassDataProvider = FutureProvider.autoDispose
    .family<ExportRawClassData, String>((ref, subjectClassId) async {
      return ref
          .watch(exportReportsRepositoryProvider)
          .fetchRawClassData(subjectClassId);
    });
