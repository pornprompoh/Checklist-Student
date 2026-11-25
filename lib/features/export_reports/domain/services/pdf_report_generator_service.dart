import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../entities/export_orientation.dart';
import '../entities/export_report_bundle.dart';
import '../entities/export_section.dart';
import 'pdf_document_chrome_builder.dart';
import 'pdf_grade_summary_builder.dart';
import 'pdf_section_table_builders.dart';

/// Pure Dart Thai PDF generator using Sarabun TrueType fonts (`Regular` +
/// `Bold`), automatic A4 Portrait/Landscape sizing, repeating table headers,
/// and wide-column auto-chunking.
class PdfReportGeneratorService {
  const PdfReportGeneratorService({
    this.chromeBuilder = const PdfDocumentChromeBuilder(),
    this.sectionBuilders = const PdfSectionTableBuilders(),
    this.gradeSummaryBuilder = const PdfGradeSummaryBuilder(),
  });

  final PdfDocumentChromeBuilder chromeBuilder;
  final PdfSectionTableBuilders sectionBuilders;
  final PdfGradeSummaryBuilder gradeSummaryBuilder;

  Future<Uint8List> generate(
    ExportReportBundle bundle, {
    required Uint8List regularFontBytes,
    required Uint8List boldFontBytes,
  }) async {
    final regularFont = pw.Font.ttf(ByteData.sublistView(regularFontBytes));
    final boldFont = pw.Font.ttf(ByteData.sublistView(boldFontBytes));
    final theme = pw.ThemeData.withFont(base: regularFont, bold: boldFont);

    final pageFormat =
        bundle.orientationDecision.orientation ==
            ExportPageOrientation.landscape
        ? PdfPageFormat.a4.landscape
        : PdfPageFormat.a4;

    final selected = bundle.options.selectedSections;
    final contentWidgets = <pw.Widget>[
      if (selected.contains(ExportSection.roster))
        ...sectionBuilders.buildRoster(bundle),
      if (selected.contains(ExportSection.attendance))
        ...sectionBuilders.buildAttendance(bundle),
      if (selected.contains(ExportSection.assignments))
        ...sectionBuilders.buildAssignments(bundle),
      if (selected.contains(ExportSection.gradeSummary))
        ...gradeSummaryBuilder.build(bundle),
      if (bundle.options.includeSignatureLines)
        chromeBuilder.buildSignatureBlock(bundle.header),
    ];

    final document = pw.Document(
      title: bundle.header.reportTitle,
      author: bundle.header.teacherName,
      theme: theme,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 32),
        maxPages: 120,
        header: (context) =>
            chromeBuilder.buildPageHeader(context, bundle.header),
        footer: (context) =>
            chromeBuilder.buildPageFooter(context, bundle.header),
        build: (_) => contentWidgets,
      ),
    );

    return document.save();
  }
}
