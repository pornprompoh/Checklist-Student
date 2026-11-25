import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/thai_date_formatter.dart';
import '../entities/export_document_header.dart';

/// Reusable PDF document chrome (headers, footers, Thai typography styles, and
/// signature blocks) for [PdfReportGeneratorService]. Pure Dart.
class PdfDocumentChromeBuilder {
  const PdfDocumentChromeBuilder();

  static const double thaiLineHeight = 1.42;

  pw.TextStyle bodyStyle({double fontSize = 9.5, bool bold = false}) {
    return pw.TextStyle(
      fontSize: fontSize,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      height: thaiLineHeight,
    );
  }

  pw.Widget buildPageHeader(pw.Context context, ExportDocumentHeader header) {
    if (context.pageNumber > 1) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 10),
        padding: const pw.EdgeInsets.only(bottom: 4),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.6),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                '${header.reportTitle} · ${header.subjectCode} ${header.subjectName} ห้อง ${header.roomName}',
                style: bodyStyle(fontSize: 8.5, bold: true),
              ),
            ),
            pw.Text(
              'ภาคเรียนที่ ${header.termLabel}/${header.academicYearBe}',
              style: bodyStyle(fontSize: 8.5),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey600, width: 0.8),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            header.schoolName,
            textAlign: pw.TextAlign.center,
            style: bodyStyle(fontSize: 12, bold: true),
          ),
          if (header.department.trim().isNotEmpty)
            pw.Text(
              header.department,
              textAlign: pw.TextAlign.center,
              style: bodyStyle(fontSize: 9.5),
            ),
          pw.SizedBox(height: 2),
          pw.Text(
            header.reportTitle,
            textAlign: pw.TextAlign.center,
            style: bodyStyle(fontSize: 13.5, bold: true),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'รายวิชา ${header.subjectCode} ${header.subjectName} · '
            'ห้อง ${header.roomName} · '
            'ภาคเรียนที่ ${header.termLabel} ปีการศึกษา ${header.academicYearBe}',
            textAlign: pw.TextAlign.center,
            style: bodyStyle(fontSize: 9.5),
          ),
          pw.Text(
            'ครูผู้สอน: ${header.teacherName} · '
            'วันที่ออกเอกสาร: ${ThaiDateFormatter.formatFullDate(header.exportedAt)}',
            textAlign: pw.TextAlign.center,
            style: bodyStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  pw.Widget buildPageFooter(pw.Context context, ExportDocumentHeader header) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'ออกเอกสารเมื่อ ${ThaiDateFormatter.formatShortDate(header.exportedAt)}',
            style: bodyStyle(fontSize: 8),
          ),
          pw.Text(
            'หน้า ${context.pageNumber} / ${context.pagesCount}',
            style: bodyStyle(fontSize: 8, bold: true),
          ),
        ],
      ),
    );
  }

  pw.Widget buildSectionHeading(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10, bottom: 5),
      child: pw.Text(title, style: bodyStyle(fontSize: 11, bold: true)),
    );
  }

  /// Indivisible signature block placed at the end of the PDF when enabled.
  pw.Widget buildSignatureBlock(ExportDocumentHeader header) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 18),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _signatureColumn(role: 'ครูผู้สอน', name: header.teacherName),
          _signatureColumn(role: 'หัวหน้ากลุ่มสาระการเรียนรู้'),
          _signatureColumn(role: 'ผู้อำนวยการสถานศึกษา'),
        ],
      ),
    );
  }

  pw.Widget _signatureColumn({required String role, String? name}) {
    final displayName = name != null && name.trim().isNotEmpty
        ? '($name)'
        : '(.............................................)';
    return pw.Column(
      children: [
        pw.Text(
          'ลงชื่อ .............................................',
          style: bodyStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 3),
        pw.Text(displayName, style: bodyStyle(fontSize: 9)),
        pw.Text(role, style: bodyStyle(fontSize: 8.5)),
      ],
    );
  }
}
