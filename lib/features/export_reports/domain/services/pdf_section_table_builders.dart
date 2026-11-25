import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/constants/attendance_status.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../grading/domain/services/score_calculator_service.dart';
import '../entities/export_orientation.dart';
import '../entities/export_report_bundle.dart';
import 'pdf_document_chrome_builder.dart';

/// Builds multi-page PDF tables for `roster`, `attendance`, and `assignments`,
/// automatically chunking wide session/assignment columns so A4 tables never
/// overflow or compress past readability. Pure Dart.
class PdfSectionTableBuilders {
  const PdfSectionTableBuilders({
    this.chrome = const PdfDocumentChromeBuilder(),
  });

  final PdfDocumentChromeBuilder chrome;

  static const _calculator = ScoreCalculatorService();

  List<pw.Widget> buildRoster(ExportReportBundle bundle) {
    final widgets = <pw.Widget>[
      chrome.buildSectionHeading('ใบรายชื่อนักเรียน (${bundle.students.length} คน)'),
    ];
    if (bundle.students.isEmpty) {
      widgets.add(pw.Text('ยังไม่มีรายชื่อนักเรียน', style: chrome.bodyStyle()));
      return widgets;
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

    widgets.add(
      pw.TableHelper.fromTextArray(
        headers: const <String>[
          'เลขที่',
          'รหัสนักเรียน',
          'คำนำหน้า',
          'ชื่อ',
          'นามสกุล',
          'สถานะ',
          'เข้าเรียน (พ.ศ.)',
        ],
        data: rows,
        headerCount: 1,
        headerStyle: chrome.bodyStyle(fontSize: 8.5, bold: true),
        cellStyle: chrome.bodyStyle(fontSize: 8.5),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        cellAlignments: const <int, pw.Alignment>{
          0: pw.Alignment.center,
          1: pw.Alignment.center,
          2: pw.Alignment.centerLeft,
          3: pw.Alignment.centerLeft,
          4: pw.Alignment.centerLeft,
          5: pw.Alignment.center,
          6: pw.Alignment.center,
        },
      ),
    );
    return widgets;
  }

  List<pw.Widget> buildAttendance(ExportReportBundle bundle) {
    final sessions = bundle.attendanceSessions;
    final widgets = <pw.Widget>[
      chrome.buildSectionHeading('สถิติและตารางเวลาเรียน (${sessions.length} คาบ)'),
    ];
    if (bundle.students.isEmpty || sessions.isEmpty) {
      widgets.add(
        pw.Text('ยังไม่มีข้อมูลการเช็คชื่อในห้องเรียนนี้', style: chrome.bodyStyle()),
      );
      return widgets;
    }

    final isLandscape =
        bundle.orientationDecision.orientation == ExportPageOrientation.landscape;
    final chunkSize = isLandscape ? 14 : 8;
    final totalChunks = (sessions.length / chunkSize).ceil();

    for (var chunk = 0; chunk < totalChunks; chunk++) {
      final start = chunk * chunkSize;
      final end = (start + chunkSize > sessions.length)
          ? sessions.length
          : start + chunkSize;
      final slice = sessions.sublist(start, end);
      final isLastChunk = chunk == totalChunks - 1;

      if (totalChunks > 1) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6, bottom: 4),
            child: pw.Text(
              'ตารางเวลาเรียน (ชุดที่ ${chunk + 1}: คาบที่ ${start + 1}–$end)',
              style: chrome.bodyStyle(fontSize: 9, bold: true),
            ),
          ),
        );
      }

      final headers = <String>[
        'เลขที่',
        'ชื่อ-นามสกุล',
        for (final s in slice)
          ThaiDateFormatter.formatNumericDate(s.sessionDate).substring(0, 5),
        if (isLastChunk) ...const <String>['มา', 'สาย', 'ลา', 'ขาด', '% ขาด'],
      ];

      final rows = <List<String>>[];
      for (final student in bundle.students) {
        final summary = bundle.attendanceSummaries[student.id];
        rows.add(<String>[
          '${student.studentNumber}',
          student.fullName,
          for (final s in slice)
            _shortMark(bundle.attendanceMatrix[student.id]?[s.id]?.status),
          if (isLastChunk) ...<String>[
            '${summary?.presentCount ?? 0}',
            '${summary?.lateCount ?? 0}',
            '${summary?.leaveCount ?? 0}',
            '${summary?.absentCount ?? 0}',
            '${(summary?.absentPercentage ?? 0).toStringAsFixed(1)}%',
          ],
        ]);
      }

      widgets.add(
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: rows,
          headerCount: 1,
          headerStyle: chrome.bodyStyle(fontSize: 7.5, bold: true),
          cellStyle: chrome.bodyStyle(fontSize: 7.5),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3.5),
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          cellAlignments: <int, pw.Alignment>{
            0: pw.Alignment.center,
            1: pw.Alignment.centerLeft,
            for (var i = 2; i < headers.length; i++) i: pw.Alignment.center,
          },
        ),
      );
    }
    return widgets;
  }

  List<pw.Widget> buildAssignments(ExportReportBundle bundle) {
    final assignments = bundle.assignments;
    final widgets = <pw.Widget>[
      chrome.buildSectionHeading(
        'รายการงานและคะแนนรายชิ้น (${assignments.length} ชิ้น)',
      ),
    ];
    if (bundle.students.isEmpty || assignments.isEmpty) {
      widgets.add(
        pw.Text('ยังไม่มีรายการชิ้นงานในห้องเรียนนี้', style: chrome.bodyStyle()),
      );
      return widgets;
    }

    final isLandscape =
        bundle.orientationDecision.orientation == ExportPageOrientation.landscape;
    final chunkSize = isLandscape ? 8 : 5;
    final totalChunks = (assignments.length / chunkSize).ceil();

    for (var chunk = 0; chunk < totalChunks; chunk++) {
      final start = chunk * chunkSize;
      final end = (start + chunkSize > assignments.length)
          ? assignments.length
          : start + chunkSize;
      final slice = assignments.sublist(start, end);
      final isLastChunk = chunk == totalChunks - 1;

      if (totalChunks > 1) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6, bottom: 4),
            child: pw.Text(
              'รายการงาน (ชุดที่ ${chunk + 1}: ชิ้นที่ ${start + 1}–$end)',
              style: chrome.bodyStyle(fontSize: 9, bold: true),
            ),
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
                ? '-'
                : _calculator.formatExactScore(
                    bundle.scoreMatrix[student.id]![a.id]!.score!,
                  ),
          if (isLastChunk) _calculator.formatExactScore(total),
        ]);
      }

      widgets.add(
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: rows,
          headerCount: 1,
          headerStyle: chrome.bodyStyle(fontSize: 8, bold: true),
          cellStyle: chrome.bodyStyle(fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          cellAlignments: <int, pw.Alignment>{
            0: pw.Alignment.center,
            1: pw.Alignment.centerLeft,
            for (var i = 2; i < headers.length; i++) i: pw.Alignment.center,
          },
        ),
      );
    }
    return widgets;
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
}
