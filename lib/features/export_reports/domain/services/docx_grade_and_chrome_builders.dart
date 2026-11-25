import '../../../../core/utils/thai_date_formatter.dart';
import '../../../grading/domain/services/score_calculator_service.dart';
import '../entities/export_document_header.dart';
import '../entities/export_report_bundle.dart';
import 'docx_xml_primitives.dart';

/// Builds Thai document header, `สรุปคะแนน-เกรด ปพ.5` (with exact unrounded
/// decimals & distribution table), and 3-column non-splitting signature lines
/// for `.docx` exports. Pure Dart.
class DocxGradeAndChromeBuilders {
  const DocxGradeAndChromeBuilders({this.xml = const DocxXmlPrimitives()});

  final DocxXmlPrimitives xml;

  static const _calculator = ScoreCalculatorService();

  String buildDocumentHeader(ExportDocumentHeader header) {
    final buffer = StringBuffer()
      ..write(
        xml.buildParagraph(
          text: header.schoolName,
          fontSizePt: 18,
          bold: true,
          align: 'center',
          spaceAfter: 20,
        ),
      );
    if (header.department.trim().isNotEmpty) {
      buffer.write(
        xml.buildParagraph(
          text: header.department,
          fontSizePt: 14,
          align: 'center',
          spaceAfter: 40,
        ),
      );
    }
    buffer
      ..write(
        xml.buildParagraph(
          text: header.reportTitle,
          fontSizePt: 17,
          bold: true,
          align: 'center',
          spaceAfter: 60,
        ),
      )
      ..write(
        xml.buildParagraph(
          text:
              'รายวิชา ${header.subjectCode} ${header.subjectName} · '
              'ห้อง ${header.roomName} · '
              'ภาคเรียนที่ ${header.termLabel} ปีการศึกษา ${header.academicYearBe}',
          fontSizePt: 14,
          bold: true,
          align: 'center',
          spaceAfter: 20,
        ),
      )
      ..write(
        xml.buildParagraph(
          text:
              'ครูผู้สอน: ${header.teacherName} · '
              'วันที่ออกเอกสาร: ${ThaiDateFormatter.formatFullDate(header.exportedAt)}',
          fontSizePt: 13,
          align: 'center',
          spaceAfter: 120,
        ),
      );
    return buffer.toString();
  }

  String buildGradeSummarySection(ExportReportBundle bundle, int contentWidth) {
    final buffer = StringBuffer()
      ..write(xml.buildSectionHeading('สรุปคะแนนและผลการเรียน (ปพ.5)'));

    if (bundle.students.isEmpty) {
      buffer.write(
        xml.buildParagraph(
          text: 'ยังไม่มีรายชื่อนักเรียนในห้องเรียนนี้',
          fontSizePt: 14,
          spaceAfter: 80,
        ),
      );
      return buffer.toString();
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

    final weights = <int>[
      8,
      14,
      36,
      for (var i = 0; i < categories.length; i++) 12,
      12,
      10,
    ];
    final alignments = <String>[
      'center',
      'center',
      'left',
      for (var i = 0; i < categories.length; i++) 'center',
      'center',
      'center',
    ];

    buffer.write(
      xml.buildTable(
        headers: headers,
        rows: rows,
        columnWidthsTwips: xml.allocateColumnWidths(weights, contentWidth),
        columnAlignments: alignments,
        fontSizePt: categories.length > 5 ? 11.5 : 13,
      ),
    );

    if (bundle.gradeDistribution.isNotEmpty) {
      final entries = bundle.gradeDistribution.entries.toList(growable: false);
      final distHeaders = <String>[
        'ระดับผลการเรียน',
        for (final e in entries) e.key,
      ];
      final distRow = <String>[
        'จำนวน (คน)',
        for (final e in entries) '${e.value}',
      ];
      final distWeights = <int>[22, for (var i = 0; i < entries.length; i++) 8];
      final distAligns = <String>[
        'left',
        for (var i = 0; i < entries.length; i++) 'center',
      ];

      buffer
        ..write(
          xml.buildParagraph(
            text: 'สรุปแจกแจงระดับผลการเรียน (นักเรียนกำลังเรียน)',
            fontSizePt: 14,
            bold: true,
            spaceBefore: 120,
            spaceAfter: 40,
            keepNext: true,
          ),
        )
        ..write(
          xml.buildTable(
            headers: distHeaders,
            rows: <List<String>>[distRow],
            columnWidthsTwips: xml.allocateColumnWidths(
              distWeights,
              contentWidth,
            ),
            columnAlignments: distAligns,
            fontSizePt: 12.5,
          ),
        );
    }

    return buffer.toString();
  }

  /// Builds a 3-column borderless signature block with `<w:cantSplit/>` so the
  /// approval lines never break awkwardly across pages.
  String buildSignatureBlock(ExportDocumentHeader header, int contentWidth) {
    final teacherDisplay = header.teacherName.trim().isNotEmpty
        ? '(${header.teacherName.trim()})'
        : '(.......................................)';
    final rows = <List<String>>[
      <String>[
        'ลงชื่อ .......................................\n$teacherDisplay\nครูผู้สอน',
        'ลงชื่อ .......................................\n(.......................................)\nหัวหน้ากลุ่มสาระการเรียนรู้',
        'ลงชื่อ .......................................\n(.......................................)\nผู้อำนวยการสถานศึกษา',
      ],
    ];

    final spacer = xml.buildParagraph(
      text: '',
      fontSizePt: 12,
      spaceBefore: 240,
      spaceAfter: 40,
    );
    final table = xml.buildTable(
      headers: const <String>[],
      rows: rows,
      columnWidthsTwips: xml.allocateColumnWidths(
        const <int>[1, 1, 1],
        contentWidth,
      ),
      columnAlignments: const <String>['center', 'center', 'center'],
      fontSizePt: 13.5,
      borderless: true,
    );
    return '$spacer$table';
  }
}
