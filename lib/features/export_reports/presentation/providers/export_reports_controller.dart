import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/utils/export_filename_builder.dart';
import '../../../../core/utils/web_file_downloader.dart';
import '../../../auth/domain/entities/teacher_profile.dart';
import '../../../grading/presentation/providers/grading_providers.dart';
import '../../domain/entities/export_document_header.dart';
import '../../domain/entities/export_options.dart';
import '../../domain/entities/export_orientation.dart';
import '../../domain/entities/export_report_bundle.dart';
import '../../domain/entities/export_section.dart';
import 'export_reports_providers.dart';

/// In-memory configuration state for `ExportReportsPage`.
///
/// Header edits stay strictly in memory for the current export document and
/// NEVER overwrite `public.teachers`.
class ExportReportsConfigState {
  const ExportReportsConfigState({
    this.selectedClassId,
    this.headerOverride,
    this.options = const ExportOptions(),
    this.isExportingExcel = false,
    this.isExportingPdf = false,
    this.isExportingDocx = false,
    this.lastExportError,
  });

  final String? selectedClassId;
  final ExportDocumentHeader? headerOverride;
  final ExportOptions options;
  final bool isExportingExcel;
  final bool isExportingPdf;
  final bool isExportingDocx;
  final String? lastExportError;

  bool get isExportingAny =>
      isExportingExcel || isExportingPdf || isExportingDocx;

  static const Object _sentinel = Object();

  ExportReportsConfigState copyWith({
    Object? selectedClassId = _sentinel,
    Object? headerOverride = _sentinel,
    ExportOptions? options,
    bool? isExportingExcel,
    bool? isExportingPdf,
    bool? isExportingDocx,
    Object? lastExportError = _sentinel,
  }) {
    return ExportReportsConfigState(
      selectedClassId: identical(selectedClassId, _sentinel)
          ? this.selectedClassId
          : selectedClassId as String?,
      headerOverride: identical(headerOverride, _sentinel)
          ? this.headerOverride
          : headerOverride as ExportDocumentHeader?,
      options: options ?? this.options,
      isExportingExcel: isExportingExcel ?? this.isExportingExcel,
      isExportingPdf: isExportingPdf ?? this.isExportingPdf,
      isExportingDocx: isExportingDocx ?? this.isExportingDocx,
      lastExportError: identical(lastExportError, _sentinel)
          ? this.lastExportError
          : lastExportError as String?,
    );
  }
}

class ExportReportsController extends Notifier<ExportReportsConfigState> {
  @override
  ExportReportsConfigState build() => const ExportReportsConfigState();

  void selectClass(String? classId) {
    final trimmed = classId?.trim();
    final nextId = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    if (nextId == state.selectedClassId) return;
    state = state.copyWith(selectedClassId: nextId, headerOverride: null);
  }

  /// Toggles [section] on/off. Returns `false` if the user attempts to disable
  /// the last remaining section so at least 1 section is always selected.
  bool toggleSection(ExportSection section) {
    final current = Set<ExportSection>.of(state.options.selectedSections);
    if (current.contains(section)) {
      if (current.length <= 1) {
        return false;
      }
      current.remove(section);
    } else {
      current.add(section);
    }
    state = state.copyWith(
      options: state.options.copyWith(
        selectedSections: Set<ExportSection>.unmodifiable(current),
      ),
    );
    return true;
  }

  void setOrientationMode(ExportOrientationMode mode) {
    state = state.copyWith(
      options: state.options.copyWith(orientationMode: mode),
    );
  }

  void setIncludeTransferredOut(bool value) {
    state = state.copyWith(
      options: state.options.copyWith(includeTransferredOut: value),
    );
  }

  void setIncludeSignatureLines(bool value) {
    state = state.copyWith(
      options: state.options.copyWith(includeSignatureLines: value),
    );
  }

  void updateHeader(ExportDocumentHeader updated) {
    state = state.copyWith(headerOverride: updated);
  }

  void resetHeaderToProfileDefaults() {
    state = state.copyWith(headerOverride: null);
  }

  /// Resolves the active [ExportDocumentHeader], falling back cleanly to
  /// defaults derived from [profile] and [classOption] when not overridden.
  ExportDocumentHeader resolveEffectiveHeader({
    required TeacherProfile? profile,
    required CopyPlanSourceClassOption classOption,
  }) {
    final override = state.headerOverride;
    if (override != null) {
      return override;
    }
    return buildDefaultHeader(
      profile: profile,
      classOption: classOption,
      sections: state.options.selectedSections,
    );
  }

  ExportDocumentHeader buildDefaultHeader({
    required TeacherProfile? profile,
    required CopyPlanSourceClassOption classOption,
    required Set<ExportSection> sections,
  }) {
    final title = sections.length == 1
        ? 'รายงาน${sections.first.thaiTitle}'
        : (sections.contains(ExportSection.gradeSummary)
              ? 'แบบบันทึกผลการพัฒนาคุณภาพผู้เรียน (ปพ.5)'
              : 'รายงานข้อมูลการจัดการเรียนรู้รายวิชา');
    final now = DateTime.now();
    return ExportDocumentHeader(
      reportTitle: title,
      schoolName: profile?.schoolName.trim().isNotEmpty == true
          ? profile!.schoolName.trim()
          : 'สถานศึกษา',
      department: profile?.department.trim().isNotEmpty == true
          ? profile!.department.trim()
          : 'กลุ่มสาระการเรียนรู้',
      teacherName: profile?.effectiveDisplayName ?? 'ครูผู้สอน',
      academicYearBe: classOption.academicYearBe,
      termLabel: classOption.termLabel,
      subjectCode: classOption.subjectCode,
      subjectName: classOption.subjectName,
      roomName: classOption.roomName,
      exportedAt: DateTime(now.year, now.month, now.day),
    );
  }

  /// Generates a preview filename for [extension] (`xlsx`, `pdf`, `docx`).
  String buildPreviewFilename({
    required ExportDocumentHeader header,
    required String extension,
  }) {
    final prefix = ExportFilenameBuilder.resolveReportPrefix(
      state.options.selectedSections.map((s) => s.key),
    );
    return ExportFilenameBuilder.build(
      reportPrefix: prefix,
      subjectCode: header.subjectCode,
      roomName: header.roomName,
      termLabel: header.termLabel,
      yearBe: header.academicYearBe,
      extension: extension,
      exportedAt: header.exportedAt,
    );
  }

  /// Generates and downloads an Excel (`.xlsx`) workbook from [bundle].
  /// Returns the generated filename on success, or `null` if busy/failed.
  Future<String?> exportToExcel(ExportReportBundle bundle) async {
    if (state.isExportingExcel) return null;
    state = state.copyWith(isExportingExcel: true, lastExportError: null);
    try {
      final bytes = ref.read(excelReportGeneratorServiceProvider).generate(bundle);
      final filename = buildPreviewFilename(
        header: bundle.header,
        extension: 'xlsx',
      );
      downloadBytesInBrowser(
        bytes: bytes,
        filename: filename,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      state = state.copyWith(isExportingExcel: false);
      return filename;
    } catch (error) {
      state = state.copyWith(
        isExportingExcel: false,
        lastExportError: ThaiErrorMapper.map(error),
      );
      return null;
    }
  }

  /// Loads Sarabun fonts, generates a Thai A4 PDF, and triggers browser download.
  /// Returns the generated filename on success, or `null` if busy/failed.
  Future<String?> exportToPdf(ExportReportBundle bundle) async {
    if (state.isExportingPdf) return null;
    state = state.copyWith(isExportingPdf: true, lastExportError: null);
    try {
      final fonts = await ref.read(sarabunPdfFontLoaderProvider).load();
      final bytes = await ref
          .read(pdfReportGeneratorServiceProvider)
          .generate(
            bundle,
            regularFontBytes: fonts.regular,
            boldFontBytes: fonts.bold,
          );
      final filename = buildPreviewFilename(
        header: bundle.header,
        extension: 'pdf',
      );
      downloadBytesInBrowser(
        bytes: bytes,
        filename: filename,
        mimeType: 'application/pdf',
      );
      state = state.copyWith(isExportingPdf: false);
      return filename;
    } catch (error) {
      state = state.copyWith(
        isExportingPdf: false,
        lastExportError: ThaiErrorMapper.map(error),
      );
      return null;
    }
  }

  /// Generates a Thai A4 Word (`.docx`) document and triggers browser download.
  /// Returns the generated filename on success, or `null` if busy/failed.
  Future<String?> exportToDocx(ExportReportBundle bundle) async {
    if (state.isExportingDocx) return null;
    state = state.copyWith(isExportingDocx: true, lastExportError: null);
    try {
      final bytes = ref.read(docxReportGeneratorServiceProvider).generate(bundle);
      final filename = buildPreviewFilename(
        header: bundle.header,
        extension: 'docx',
      );
      downloadBytesInBrowser(
        bytes: bytes,
        filename: filename,
        mimeType:
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
      state = state.copyWith(isExportingDocx: false);
      return filename;
    } catch (error) {
      state = state.copyWith(
        isExportingDocx: false,
        lastExportError: ThaiErrorMapper.map(error),
      );
      return null;
    }
  }
}

final exportReportsControllerProvider =
    NotifierProvider<ExportReportsController, ExportReportsConfigState>(
      ExportReportsController.new,
    );
