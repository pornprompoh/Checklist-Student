import 'package:excel/excel.dart';

import '../../../../core/constants/attendance_status.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../attendance/domain/entities/student_attendance_summary.dart';
import '../../../grading/domain/services/score_calculator_service.dart';
import '../entities/export_document_header.dart';
import '../entities/export_report_bundle.dart';

/// Pure Dart sheet builders populating individual worksheets for
/// [ExcelReportGeneratorService].
class ExcelSheetSectionBuilders {
  const ExcelSheetSectionBuilders();

  static const _calculator = ScoreCalculatorService();

  static final CellStyle _titleStyle = CellStyle(bold: true, fontSize: 13);
  static final CellStyle _headerStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#E8ECF8'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );
  static final CellStyle _centerStyle = CellStyle(
    horizontalAlign: HorizontalAlign.Center,
  );
  static final CellStyle _boldCenterStyle = CellStyle(
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
  );

  void buildRosterSheet(Excel excel, ExportReportBundle bundle) {
    final sheet = excel['ใบรายชื่อ'];
    var row = _writeDocumentHeader(sheet, bundle.header, 'ใบรายชื่อนักเรียน');

    final headers = <String>[
      'เลขที่',
      'รหัสนักเรียน',
      'คำนำหน้า',
      'ชื่อ',
      'นามสกุล',
      'สถานะ',
      'วันที่เข้าเรียน (พ.ศ.)',
    ];
    _writeTableHeader(sheet, row++, headers);

    for (final student in bundle.students) {
      _setCell(sheet, 0, row, IntCellValue(student.studentNumber), _centerStyle);
      _setCell(sheet, 1, row, TextCellValue(student.studentCode), _centerStyle);
      _setCell(sheet, 2, row, TextCellValue(student.prefix));
      _setCell(sheet, 3, row, TextCellValue(student.firstName));
      _setCell(sheet, 4, row, TextCellValue(student.lastName));
      _setCell(
        sheet,
        5,
        row,
        TextCellValue(student.isTransferredOut ? 'ย้ายออก' : 'กำลังเรียน'),
        _centerStyle,
      );
      _setCell(
        sheet,
        6,
        row,
        TextCellValue(ThaiDateFormatter.formatShortDate(student.enrolledAt)),
        _centerStyle,
      );
      row++;
    }
    _applyWidths(sheet, const <double>[10, 16, 12, 18, 18, 14, 20]);
    if (bundle.options.includeSignatureLines) {
      _writeSignatureBlock(sheet, bundle.header, row + 2);
    }
  }

  void buildAttendanceSheet(Excel excel, ExportReportBundle bundle) {
    final sheet = excel['เวลาเรียน'];
    var row = _writeDocumentHeader(
      sheet,
      bundle.header,
      'สถิติและตารางเวลาเรียน',
    );
    final sessions = bundle.attendanceSessions;
    final headers = <String>[
      'เลขที่',
      'รหัสนักเรียน',
      'ชื่อ-นามสกุล',
      for (final s in sessions)
        ThaiDateFormatter.formatNumericDate(s.sessionDate).substring(0, 5),
      'มา',
      'สาย',
      'ลา',
      'ขาด',
      '% ขาดเรียน',
      'สถานะเวลาเรียน',
    ];
    _writeTableHeader(sheet, row++, headers);

    for (final student in bundle.students) {
      var col = 0;
      _setCell(sheet, col++, row, IntCellValue(student.studentNumber), _centerStyle);
      _setCell(sheet, col++, row, TextCellValue(student.studentCode), _centerStyle);
      _setCell(sheet, col++, row, TextCellValue(student.fullName));
      for (final session in sessions) {
        final mark = _shortMark(
          bundle.attendanceMatrix[student.id]?[session.id]?.status,
        );
        _setCell(sheet, col++, row, TextCellValue(mark), _centerStyle);
      }
      final summary = bundle.attendanceSummaries[student.id];
      _setCell(sheet, col++, row, IntCellValue(summary?.presentCount ?? 0), _centerStyle);
      _setCell(sheet, col++, row, IntCellValue(summary?.lateCount ?? 0), _centerStyle);
      _setCell(sheet, col++, row, IntCellValue(summary?.leaveCount ?? 0), _centerStyle);
      _setCell(sheet, col++, row, IntCellValue(summary?.absentCount ?? 0), _centerStyle);
      final pct = ((summary?.absentPercentage ?? 0) * 100).round() / 100.0;
      _setCell(sheet, col++, row, DoubleCellValue(pct), _centerStyle);
      _setCell(
        sheet,
        col++,
        row,
        TextCellValue(_riskLabel(summary?.riskLevel)),
        _centerStyle,
      );
      row++;
    }
    _applyWidths(sheet, <double>[
      8,
      15,
      24,
      for (var i = 0; i < sessions.length; i++) 8,
      8,
      8,
      8,
      8,
      12,
      16,
    ]);
    if (bundle.options.includeSignatureLines) {
      _writeSignatureBlock(sheet, bundle.header, row + 2);
    }
  }

  void buildAssignmentsSheet(Excel excel, ExportReportBundle bundle) {
    final sheet = excel['รายการงาน'];
    var row = _writeDocumentHeader(
      sheet,
      bundle.header,
      'รายการงานและคะแนนรายชิ้น',
    );
    final assignments = bundle.assignments;
    final headers = <String>[
      'เลขที่',
      'รหัสนักเรียน',
      'ชื่อ-นามสกุล',
      for (final a in assignments)
        '${a.title} (เต็ม ${_calculator.formatExactScore(a.maxScore)})',
      'คะแนนรวม',
    ];
    _writeTableHeader(sheet, row++, headers);

    for (final student in bundle.students) {
      var col = 0;
      _setCell(sheet, col++, row, IntCellValue(student.studentNumber), _centerStyle);
      _setCell(sheet, col++, row, TextCellValue(student.studentCode), _centerStyle);
      _setCell(sheet, col++, row, TextCellValue(student.fullName));
      for (final assign in assignments) {
        final record = bundle.scoreMatrix[student.id]?[assign.id];
        if (record?.score != null) {
          _setCell(sheet, col++, row, DoubleCellValue(record!.score!), _centerStyle);
        } else {
          _setCell(sheet, col++, row, TextCellValue('ยังไม่ส่ง'), _centerStyle);
        }
      }
      final total = bundle.gradeResults[student.id]?.totalScore ?? 0.0;
      _setCell(sheet, col++, row, DoubleCellValue(total), _boldCenterStyle);
      row++;
    }
    _applyWidths(sheet, <double>[
      8,
      15,
      24,
      for (var i = 0; i < assignments.length; i++) 16,
      14,
    ]);
    if (bundle.options.includeSignatureLines) {
      _writeSignatureBlock(sheet, bundle.header, row + 2);
    }
  }

  void buildGradeSummarySheet(Excel excel, ExportReportBundle bundle) {
    final sheet = excel['สรุปคะแนน-เกรด ปพ.5'];
    var row = _writeDocumentHeader(
      sheet,
      bundle.header,
      'สรุปคะแนนและเกรด (ปพ.5)',
    );
    final categories = bundle.scoreCategories;
    final headers = <String>[
      'เลขที่',
      'รหัสนักเรียน',
      'ชื่อ-นามสกุล',
      for (final cat in categories)
        cat.targetMaxScore == null
            ? cat.name
            : '${cat.name} (${_calculator.formatExactScore(cat.targetMaxScore!)})',
      'คะแนนรวม',
      'เกรดที่ได้',
    ];
    _writeTableHeader(sheet, row++, headers);

    for (final student in bundle.students) {
      final result = bundle.gradeResults[student.id];
      final byCat = <String?, double>{
        if (result != null)
          for (final item in result.categorySummaries)
            item.categoryId: item.earnedScore,
      };
      var col = 0;
      _setCell(sheet, col++, row, IntCellValue(student.studentNumber), _centerStyle);
      _setCell(sheet, col++, row, TextCellValue(student.studentCode), _centerStyle);
      _setCell(sheet, col++, row, TextCellValue(student.fullName));
      for (final cat in categories) {
        _setCell(sheet, col++, row, DoubleCellValue(byCat[cat.id] ?? 0.0), _centerStyle);
      }
      _setCell(
        sheet,
        col++,
        row,
        DoubleCellValue(result?.totalScore ?? 0.0),
        _boldCenterStyle,
      );
      final displayed = result?.displayedGrade ?? '-';
      final showResolved =
          bundle.options.includeTeacherResolvedBadges &&
          result != null &&
          result.specialGradeOverride == null &&
          (result.wasRResolved || result.wasMsResolved);
      _setCell(
        sheet,
        col++,
        row,
        TextCellValue(showResolved ? '$displayed (เคยแก้)' : displayed),
        _boldCenterStyle,
      );
      row++;
    }

    row++;
    _setCell(sheet, 0, row++, TextCellValue('สรุปแจกแจงระดับผลการเรียน'), _titleStyle);
    _writeTableHeader(sheet, row++, const <String>['ระดับผลการเรียน', 'จำนวน (คน)']);
    for (final entry in bundle.gradeDistribution.entries) {
      _setCell(sheet, 0, row, TextCellValue(entry.key), _centerStyle);
      _setCell(sheet, 1, row, IntCellValue(entry.value), _centerStyle);
      row++;
    }

    _applyWidths(sheet, <double>[
      16,
      16,
      24,
      for (var i = 0; i < categories.length; i++) 16,
      14,
      14,
    ]);
    if (bundle.options.includeSignatureLines) {
      _writeSignatureBlock(sheet, bundle.header, row + 2);
    }
  }

  int _writeDocumentHeader(
    Sheet sheet,
    ExportDocumentHeader header,
    String subtitle,
  ) {
    _setCell(sheet, 0, 0, TextCellValue(header.schoolName), _titleStyle);
    _setCell(
      sheet,
      0,
      1,
      TextCellValue('${header.reportTitle} — $subtitle'),
      _titleStyle,
    );
    _setCell(
      sheet,
      0,
      2,
      TextCellValue(
        'กลุ่มสาระ: ${header.department} · รายวิชา ${header.subjectCode} '
        '${header.subjectName} · ห้อง ${header.roomName}',
      ),
    );
    _setCell(
      sheet,
      0,
      3,
      TextCellValue(
        'ภาคเรียนที่ ${header.termLabel} ปีการศึกษา ${header.academicYearBe} '
        '· ครูผู้สอน: ${header.teacherName} '
        '· วันที่ออกเอกสาร: ${ThaiDateFormatter.formatFullDate(header.exportedAt)}',
      ),
    );
    return 5;
  }

  void _writeTableHeader(Sheet sheet, int row, List<String> headers) {
    for (var col = 0; col < headers.length; col++) {
      _setCell(sheet, col, row, TextCellValue(headers[col]), _headerStyle);
    }
  }

  void _writeSignatureBlock(
    Sheet sheet,
    ExportDocumentHeader header,
    int startRow,
  ) {
    _setCell(sheet, 0, startRow, TextCellValue('ลงชื่อ ....................................... ครูผู้สอน'));
    _setCell(sheet, 0, startRow + 1, TextCellValue('(${header.teacherName})'));
    _setCell(sheet, 3, startRow, TextCellValue('ลงชื่อ ....................................... หัวหน้ากลุ่มสาระฯ'));
    _setCell(sheet, 3, startRow + 1, TextCellValue('(.......................................)'));
    _setCell(sheet, 6, startRow, TextCellValue('ลงชื่อ ....................................... ผู้อำนวยการสถานศึกษา'));
    _setCell(sheet, 6, startRow + 1, TextCellValue('(.......................................)'));
  }

  void _setCell(
    Sheet sheet,
    int col,
    int row,
    CellValue value, [
    CellStyle? style,
  ]) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = value;
    if (style != null) {
      cell.cellStyle = style;
    }
  }

  void _applyWidths(Sheet sheet, List<double> widths) {
    for (var i = 0; i < widths.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }
  }

  String _shortMark(AttendanceStatus? status) {
    return switch (status) {
      AttendanceStatus.present => 'ม',
      AttendanceStatus.late => 'ส',
      AttendanceStatus.leave => 'ล',
      AttendanceStatus.absent => 'ข',
      null => '-',
    };
  }

  String _riskLabel(AttendanceRiskLevel? level) {
    return switch (level) {
      AttendanceRiskLevel.exceededMs => 'เกินเกณฑ์ มส',
      AttendanceRiskLevel.approachingMs => 'เสี่ยง มส',
      AttendanceRiskLevel.normal || null => 'ปกติ',
    };
  }
}
