import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../grading/domain/services/score_calculator_service.dart';
import '../entities/export_report_bundle.dart';
import 'pdf_document_chrome_builder.dart';

/// Builds the `สรุปคะแนน-เกรด ปพ.5` multi-page table and grade distribution
/// box for [PdfReportGeneratorService]. Pure Dart.
class PdfGradeSummaryBuilder {
  const PdfGradeSummaryBuilder({
    this.chrome = const PdfDocumentChromeBuilder(),
  });

  final PdfDocumentChromeBuilder chrome;

  static const _calculator = ScoreCalculatorService();

  List<pw.Widget> build(ExportReportBundle bundle) {
    final widgets = <pw.Widget>[
      chrome.buildSectionHeading('สรุปคะแนนและผลการเรียน (ปพ.5)'),
    ];

    if (bundle.students.isEmpty) {
      widgets.add(
        pw.Text(
          'ยังไม่มีรายชื่อนักเรียนในห้องเรียนนี้',
          style: chrome.bodyStyle(fontSize: 9),
        ),
      );
      return widgets;
    }

    final categories = bundle.scoreCategories;
    final headers = <String>[
      'เลขที่',
      'รหัส',
      'ชื่อ-นามสกุล',
      for (final cat in categories)
        cat.targetMaxScore == null
            ? cat.name
            : '${cat.name}\n(${_calculator.formatExactScore(cat.targetMaxScore!)})',
      'รวม',
      'เกรด',
    ];

    final rows = <List<String>>[];
    for (final student in bundle.students) {
      final result = bundle.gradeResults[student.id];
      final byCat = <String?, double>{
        if (result != null)
          for (final item in result.categorySummaries)
            item.categoryId: item.earnedScore,
      };
      final displayed = result?.displayedGrade ?? '-';
      final showResolved =
          bundle.options.includeTeacherResolvedBadges &&
          result != null &&
          result.specialGradeOverride == null &&
          (result.wasRResolved || result.wasMsResolved);

      rows.add(<String>[
        '${student.studentNumber}',
        student.studentCode,
        student.isTransferredOut
            ? '${student.fullName} (ย้ายออก)'
            : student.fullName,
        for (final cat in categories)
          _calculator.formatExactScore(byCat[cat.id] ?? 0.0),
        result == null ? '0' : _calculator.formatExactScore(result.totalScore),
        showResolved ? '$displayed (เคยแก้)' : displayed,
      ]);
    }

    final alignments = <int, pw.Alignment>{
      0: pw.Alignment.center,
      1: pw.Alignment.center,
      2: pw.Alignment.centerLeft,
      for (var i = 3; i < headers.length; i++) i: pw.Alignment.center,
    };

    widgets.add(
      pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows,
        headerCount: 1,
        headerStyle: chrome.bodyStyle(fontSize: 8.5, bold: true),
        cellStyle: chrome.bodyStyle(fontSize: 8.5),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        cellAlignments: alignments,
      ),
    );

    widgets.add(pw.SizedBox(height: 10));
    widgets.add(
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'สรุปแจกแจงระดับผลการเรียน (นักเรียนกำลังเรียน)',
              style: chrome.bodyStyle(fontSize: 9, bold: true),
            ),
            pw.SizedBox(height: 4),
            pw.Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final entry in bundle.gradeDistribution.entries)
                  pw.Text(
                    'เกรด ${entry.key}: ${entry.value} คน',
                    style: chrome.bodyStyle(fontSize: 8.5),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    return widgets;
  }
}
