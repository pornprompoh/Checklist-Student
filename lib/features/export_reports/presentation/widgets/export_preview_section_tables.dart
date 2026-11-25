import 'package:flutter/material.dart';

import '../../../../core/constants/attendance_status.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../grading/domain/services/score_calculator_service.dart';
import '../../domain/entities/export_report_bundle.dart';
import '../../domain/entities/export_section.dart';
import 'export_preview_grade_table.dart';

/// Renders all toggled-on preview tables (`roster`, `attendance`, `assignments`,
/// `gradeSummary`) inside `ExportPreviewCanvas`.
class ExportPreviewSectionTables extends StatelessWidget {
  const ExportPreviewSectionTables({super.key, required this.bundle});

  final ExportReportBundle bundle;

  static const _calculator = ScoreCalculatorService();

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];
    if (bundle.options.hasSection(ExportSection.roster)) {
      sections.add(_buildRosterTable(context));
    }
    if (bundle.options.hasSection(ExportSection.attendance)) {
      sections.add(_buildAttendanceTable(context));
    }
    if (bundle.options.hasSection(ExportSection.assignments)) {
      sections.add(_buildAssignmentsTable(context));
    }
    if (bundle.options.hasSection(ExportSection.gradeSummary)) {
      sections.add(ExportPreviewGradeTable(bundle: bundle));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const Divider(height: 28),
          sections[i],
        ],
      ],
    );
  }

  Widget _buildRosterTable(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ใบรายชื่อนักเรียน (${bundle.students.length} คน)',
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (bundle.students.isEmpty)
          Text(
            'ยังไม่มีรายชื่อนักเรียนในห้องเรียนนี้',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 38,
              dataRowMinHeight: 34,
              dataRowMaxHeight: 40,
              horizontalMargin: 10,
              columnSpacing: 14,
              border: TableBorder.all(
                color: colorScheme.outlineVariant,
                width: 0.7,
              ),
              columns: const <DataColumn>[
                DataColumn(label: Text('เลขที่')),
                DataColumn(label: Text('รหัสนักเรียน')),
                DataColumn(label: Text('คำนำหน้า')),
                DataColumn(label: Text('ชื่อ-นามสกุล')),
                DataColumn(label: Text('สถานะ / เข้าเรียน')),
              ],
              rows: [
                for (final student in bundle.students)
                  DataRow(
                    cells: <DataCell>[
                      DataCell(Text('${student.studentNumber}')),
                      DataCell(Text(student.studentCode)),
                      DataCell(Text(student.prefix.isEmpty ? '-' : student.prefix)),
                      DataCell(Text('${student.firstName} ${student.lastName}'.trim())),
                      DataCell(
                        Text(
                          student.isTransferredOut
                              ? 'ย้ายออก'
                              : 'กำลังเรียน (${ThaiDateFormatter.formatShortDate(student.enrolledAt)})',
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAttendanceTable(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sessions = bundle.attendanceSessions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'สถิติและตารางเวลาเรียน (${sessions.length} คาบ)',
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (bundle.students.isEmpty || sessions.isEmpty)
          Text(
            'ยังไม่มีข้อมูลการเช็คชื่อในห้องเรียนนี้',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 34,
              dataRowMaxHeight: 40,
              horizontalMargin: 10,
              columnSpacing: 10,
              border: TableBorder.all(
                color: colorScheme.outlineVariant,
                width: 0.7,
              ),
              columns: <DataColumn>[
                const DataColumn(label: Text('เลขที่')),
                const DataColumn(label: Text('ชื่อ-นามสกุล')),
                for (final session in sessions)
                  DataColumn(
                    label: Text(
                      ThaiDateFormatter.formatNumericDate(session.sessionDate)
                          .substring(0, 5),
                    ),
                  ),
                const DataColumn(numeric: true, label: Text('มา/สาย/ลา/ขาด')),
                const DataColumn(numeric: true, label: Text('% ขาด')),
              ],
              rows: [
                for (final student in bundle.students)
                  DataRow(
                    cells: <DataCell>[
                      DataCell(Text('${student.studentNumber}')),
                      DataCell(Text(student.fullName)),
                      for (final session in sessions)
                        DataCell(
                          Text(
                            _shortAttendanceMark(
                              bundle
                                  .attendanceMatrix[student.id]?[session.id]
                                  ?.status,
                            ),
                          ),
                        ),
                      DataCell(
                        Text(_attendanceCountsLabel(student.id)),
                      ),
                      DataCell(
                        Text(
                          '${(bundle.attendanceSummaries[student.id]?.absentPercentage ?? 0).toStringAsFixed(1)}%',
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAssignmentsTable(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final assignments = bundle.assignments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'รายการงานและคะแนนรายชิ้น (${assignments.length} ชิ้น)',
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (bundle.students.isEmpty || assignments.isEmpty)
          Text(
            'ยังไม่มีรายการชิ้นงานในห้องเรียนนี้',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 42,
              dataRowMinHeight: 34,
              dataRowMaxHeight: 40,
              horizontalMargin: 10,
              columnSpacing: 12,
              border: TableBorder.all(
                color: colorScheme.outlineVariant,
                width: 0.7,
              ),
              columns: <DataColumn>[
                const DataColumn(label: Text('เลขที่')),
                const DataColumn(label: Text('ชื่อ-นามสกุล')),
                for (final assign in assignments)
                  DataColumn(
                    numeric: true,
                    label: Text(
                      '${assign.title} (${_calculator.formatExactScore(assign.maxScore)}'
                      '${assign.isMandatory ? '*' : ''})',
                    ),
                  ),
              ],
              rows: [
                for (final student in bundle.students)
                  DataRow(
                    cells: <DataCell>[
                      DataCell(Text('${student.studentNumber}')),
                      DataCell(Text(student.fullName)),
                      for (final assign in assignments)
                        _buildAssignmentScoreCell(
                          studentId: student.id,
                          assignmentId: assign.id,
                          maxScore: assign.maxScore,
                          semantic: semantic,
                        ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  DataCell _buildAssignmentScoreCell({
    required String studentId,
    required String assignmentId,
    required double maxScore,
    required AppSemanticColors semantic,
  }) {
    final score = bundle.scoreMatrix[studentId]?[assignmentId]?.score;
    final isOver =
        score != null && (score * 100).round() > (maxScore * 100).round();
    return DataCell(
      Text(
        score == null ? '-' : _calculator.formatExactScore(score),
        style: isOver
            ? TextStyle(color: semantic.danger, fontWeight: FontWeight.w700)
            : null,
      ),
    );
  }

  String _shortAttendanceMark(AttendanceStatus? status) {
    return switch (status) {
      AttendanceStatus.present => 'ม',
      AttendanceStatus.late => 'ส',
      AttendanceStatus.leave => 'ล',
      AttendanceStatus.absent => 'ข',
      null => '-',
    };
  }

  String _attendanceCountsLabel(String enrollmentId) {
    final s = bundle.attendanceSummaries[enrollmentId];
    if (s == null) return '0/0/0/0';
    return '${s.presentCount}/${s.lateCount}/${s.leaveCount}/${s.absentCount}';
  }
}
