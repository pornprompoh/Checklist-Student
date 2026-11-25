import '../../../../core/constants/attendance_status.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../entities/export_orientation.dart';
import '../entities/export_report_bundle.dart';
import 'docx_xml_primitives.dart';

/// Builds auto-chunked Word OOXML attendance tables (`10` sessions Portrait /
/// `16` sessions Landscape) with summary statistics for `สถิติเวลาเรียน`.
/// Pure Dart.
class DocxAttendanceTableBuilder {
  const DocxAttendanceTableBuilder({this.xml = const DocxXmlPrimitives()});

  final DocxXmlPrimitives xml;

  String build(ExportReportBundle bundle, int contentWidth) {
    final sessions = bundle.attendanceSessions;
    final buffer = StringBuffer()
      ..write(
        xml.buildSectionHeading('สถิติและตารางเวลาเรียน (${sessions.length} คาบ)'),
      );
    if (bundle.students.isEmpty || sessions.isEmpty) {
      buffer.write(
        xml.buildParagraph(
          text: 'ยังไม่มีข้อมูลการเช็คชื่อในห้องเรียนนี้',
          spaceAfter: 80,
        ),
      );
      return buffer.toString();
    }

    final isLandscape =
        bundle.orientationDecision.orientation == ExportPageOrientation.landscape;
    final chunkSize = isLandscape ? 16 : 10;
    final totalChunks = (sessions.length / chunkSize).ceil();
    final lastSliceCount = sessions.length - ((totalChunks - 1) * chunkSize);
    final appendSummaryToLastChunk =
        totalChunks == 1 || lastSliceCount <= (isLandscape ? 10 : 5);

    for (var chunk = 0; chunk < totalChunks; chunk++) {
      final start = chunk * chunkSize;
      final end = (start + chunkSize > sessions.length)
          ? sessions.length
          : start + chunkSize;
      final slice = sessions.sublist(start, end);
      final includeSummaryHere =
          appendSummaryToLastChunk && chunk == totalChunks - 1;

      if (totalChunks > 1) {
        buffer.write(
          xml.buildParagraph(
            text:
                'ตารางเวลาเรียน (ชุดที่ ${chunk + 1}: คาบที่ ${start + 1}–$end)',
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
        for (final s in slice)
          ThaiDateFormatter.formatNumericDate(s.sessionDate).substring(0, 5),
        if (includeSummaryHere)
          ...const <String>['มา', 'สาย', 'ลา', 'ขาด', '% ขาด', 'สถานะ'],
      ];

      final rows = <List<String>>[];
      for (final student in bundle.students) {
        final summary = bundle.attendanceSummaries[student.id];
        rows.add(<String>[
          '${student.studentNumber}',
          student.fullName,
          for (final s in slice)
            _shortMark(bundle.attendanceMatrix[student.id]?[s.id]?.status),
          if (includeSummaryHere) ...<String>[
            '${summary?.presentCount ?? 0}',
            '${summary?.lateCount ?? 0}',
            '${summary?.leaveCount ?? 0}',
            '${summary?.absentCount ?? 0}',
            '${(summary?.absentPercentage ?? 0).toStringAsFixed(1)}%',
            summary?.exceedsMsThreshold == true ? 'มส' : 'ปกติ',
          ],
        ]);
      }

      final weights = <int>[
        7,
        28,
        for (var i = 0; i < slice.length; i++) 6,
        if (includeSummaryHere) ...const <int>[6, 6, 6, 6, 8, 8],
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
          fontSizePt: headers.length > 14 ? 11.5 : 12.5,
        ),
      );
    }

    if (!appendSummaryToLastChunk) {
      buffer
        ..write(
          xml.buildParagraph(
            text: 'สรุปสถิติเวลาเรียนรวม',
            fontSizePt: 13.5,
            bold: true,
            spaceBefore: 100,
            spaceAfter: 40,
            keepNext: true,
          ),
        )
        ..write(_buildSummaryTable(bundle, contentWidth));
    }
    return buffer.toString();
  }

  String _buildSummaryTable(ExportReportBundle bundle, int contentWidth) {
    final rows = bundle.students
        .map((student) {
          final summary = bundle.attendanceSummaries[student.id];
          return <String>[
            '${student.studentNumber}',
            student.fullName,
            '${summary?.presentCount ?? 0}',
            '${summary?.lateCount ?? 0}',
            '${summary?.leaveCount ?? 0}',
            '${summary?.absentCount ?? 0}',
            '${(summary?.absentPercentage ?? 0).toStringAsFixed(1)}%',
            summary?.exceedsMsThreshold == true ? 'มส' : 'ปกติ',
          ];
        })
        .toList(growable: false);

    return xml.buildTable(
      headers: const <String>[
        'เลขที่',
        'ชื่อ-นามสกุล',
        'มา',
        'สาย',
        'ลา',
        'ขาด',
        '% ขาด',
        'สถานะ',
      ],
      rows: rows,
      columnWidthsTwips: xml.allocateColumnWidths(
        const <int>[8, 34, 9, 9, 9, 9, 11, 11],
        contentWidth,
      ),
      columnAlignments: const <String>[
        'center',
        'left',
        'center',
        'center',
        'center',
        'center',
        'center',
        'center',
      ],
      fontSizePt: 12.5,
    );
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
