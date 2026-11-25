import '../../../../core/utils/thai_date_formatter.dart';
import '../../../grading/domain/services/score_calculator_service.dart';
import '../entities/export_orientation.dart';
import '../entities/export_report_bundle.dart';
import 'docx_attendance_table_builder.dart';
import 'docx_xml_primitives.dart';

/// Builds Word OOXML tables for `roster`, `attendance`, and `assignments`,
/// automatically chunking wide tables so A4 pages remain crisp and readable
/// in Microsoft Word and Google Docs. Pure Dart.
class DocxSectionTableBuilders {
  const DocxSectionTableBuilders({
    this.xml = const DocxXmlPrimitives(),
    this.attendanceBuilder = const DocxAttendanceTableBuilder(),
  });

  final DocxXmlPrimitives xml;
  final DocxAttendanceTableBuilder attendanceBuilder;

  static const _calculator = ScoreCalculatorService();

  String buildRosterSection(ExportReportBundle bundle, int contentWidth) {
    final buffer = StringBuffer()
      ..write(
        xml.buildSectionHeading('ใบรายชื่อนักเรียน (${bundle.students.length} คน)'),
      );
    if (bundle.students.isEmpty) {
      buffer.write(
        xml.buildParagraph(text: 'ยังไม่มีรายชื่อนักเรียน', spaceAfter: 80),
      );
      return buffer.toString();
    }

    final rows = bundle.students
        .map(
          (s) => <String>[
            '${s.studentNumber}',
            s.studentCode,
            s.prefix.isEmpty ? '-' : s.prefix,
            s.firstName,
            s.lastName,
            s.isTransferredOut ? 'ย้ายออก' : 'กำลังเรียน',
            ThaiDateFormatter.formatShortDate(s.enrolledAt),
          ],
        )
        .toList(growable: false);

    buffer.write(
      xml.buildTable(
        headers: const <String>[
          'เลขที่',
          'รหัสนักเรียน',
          'คำนำหน้า',
          'ชื่อ',
          'นามสกุล',
          'สถานะ',
          'เข้าเรียน (พ.ศ.)',
        ],
        rows: rows,
        columnWidthsTwips: xml.allocateColumnWidths(
          const <int>[8, 15, 11, 20, 20, 12, 14],
          contentWidth,
        ),
        columnAlignments: const <String>[
          'center',
          'center',
          'left',
          'left',
          'left',
          'center',
          'center',
        ],
        fontSizePt: 13,
      ),
    );
    return buffer.toString();
  }

  String buildAttendanceSection(ExportReportBundle bundle, int contentWidth) {
    return attendanceBuilder.build(bundle, contentWidth);
  }

  String buildAssignmentsSection(ExportReportBundle bundle, int contentWidth) {
    final assignments = bundle.assignments;
    final buffer = StringBuffer()
      ..write(
        xml.buildSectionHeading(
          'รายการงานและคะแนนรายชิ้น (${assignments.length} ชิ้น)',
        ),
      );
    if (bundle.students.isEmpty || assignments.isEmpty) {
      buffer.write(
        xml.buildParagraph(
          text: 'ยังไม่มีรายการชิ้นงานในห้องเรียนนี้',
          spaceAfter: 80,
        ),
      );
      return buffer.toString();
    }

    final isLandscape =
        bundle.orientationDecision.orientation == ExportPageOrientation.landscape;
    final chunkSize = isLandscape ? 9 : 5;
    final totalChunks = (assignments.length / chunkSize).ceil();

    for (var chunk = 0; chunk < totalChunks; chunk++) {
      final start = chunk * chunkSize;
      final end = (start + chunkSize > assignments.length)
          ? assignments.length
          : start + chunkSize;
      final slice = assignments.sublist(start, end);
      final isLastChunk = chunk == totalChunks - 1;

      if (totalChunks > 1) {
        buffer.write(
          xml.buildParagraph(
            text: 'รายการงาน (ชุดที่ ${chunk + 1}: ชิ้นที่ ${start + 1}–$end)',
            fontSizePt: 13.5,
            bold: true,
            spaceBefore: 100,
            spaceAfter: 40,
            keepNext: true,
          ),
        );
      }

      final headers = <String>[
        'เลขที่',
        'ชื่อ-นามสกุล',
        for (final a in slice)
          '${a.title}\n(เต็ม ${_calculator.formatExactScore(a.maxScore)})',
        if (isLastChunk) 'รวม',
      ];

      final rows = <List<String>>[];
      for (final student in bundle.students) {
        final total = bundle.gradeResults[student.id]?.totalScore ?? 0.0;
        rows.add(<String>[
          '${student.studentNumber}',
          student.fullName,
          for (final a in slice)
            bundle.scoreMatrix[student.id]?[a.id]?.score == null
                ? 'ยังไม่ส่ง'
                : _calculator.formatExactScore(
                    bundle.scoreMatrix[student.id]![a.id]!.score!,
                  ),
          if (isLastChunk) _calculator.formatExactScore(total),
        ]);
      }

      final weights = <int>[
        7,
        28,
        for (var i = 0; i < slice.length; i++) 12,
        if (isLastChunk) 10,
      ];
      final aligns = <String>[
        'center',
        'left',
        for (var i = 2; i < headers.length; i++) 'center',
      ];

      buffer.write(
        xml.buildTable(
          headers: headers,
          rows: rows,
          columnWidthsTwips: xml.allocateColumnWidths(weights, contentWidth),
          columnAlignments: aligns,
          fontSizePt: slice.length > 6 ? 11.5 : 12.5,
        ),
      );
    }
    return buffer.toString();
  }
}
