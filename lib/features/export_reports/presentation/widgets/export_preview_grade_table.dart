import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../grading/domain/services/score_calculator_service.dart';
import '../../domain/entities/export_report_bundle.dart';

/// Preview section for `ExportSection.gradeSummary` (ปพ.5): category scores,
/// exact unrounded total score, evaluated/override grade, and grade distribution.
class ExportPreviewGradeTable extends StatelessWidget {
  const ExportPreviewGradeTable({super.key, required this.bundle});

  final ExportReportBundle bundle;

  static const _calculator = ScoreCalculatorService();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final categories = bundle.scoreCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'สรุปคะแนนและผลการเรียน (ปพ.5)',
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
              headingRowHeight: 40,
              dataRowMinHeight: 36,
              dataRowMaxHeight: 42,
              horizontalMargin: 10,
              columnSpacing: 14,
              border: TableBorder.all(
                color: colorScheme.outlineVariant,
                width: 0.7,
              ),
              columns: <DataColumn>[
                const DataColumn(label: Text('เลขที่')),
                const DataColumn(label: Text('รหัส')),
                const DataColumn(label: Text('ชื่อ-นามสกุล')),
                for (final cat in categories)
                  DataColumn(
                    numeric: true,
                    label: Text(
                      cat.targetMaxScore == null
                          ? cat.name
                          : '${cat.name} (${_calculator.formatExactScore(cat.targetMaxScore!)})',
                    ),
                  ),
                const DataColumn(numeric: true, label: Text('คะแนนรวม')),
                const DataColumn(label: Text('เกรด')),
              ],
              rows: [
                for (final student in bundle.students)
                  _buildStudentRow(context, student.id, semantic),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'สรุปแจกแจงระดับผลการเรียน (นักเรียนกำลังเรียน)',
          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final entry in bundle.gradeDistribution.entries)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: (entry.key == 'ร' || entry.key == 'มส') &&
                          entry.value > 0
                      ? semantic.dangerContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'เกรด ${entry.key}: ${entry.value} คน',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: (entry.key == 'ร' || entry.key == 'มส') &&
                            entry.value > 0
                        ? semantic.danger
                        : colorScheme.onSurface,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  DataRow _buildStudentRow(
    BuildContext context,
    String enrollmentId,
    AppSemanticColors semantic,
  ) {
    final student = bundle.students.firstWhere((s) => s.id == enrollmentId);
    final result = bundle.gradeResults[enrollmentId];
    final summaryByCatId = <String?, double>{
      if (result != null)
        for (final s in result.categorySummaries) s.categoryId: s.earnedScore,
    };

    final displayedGrade = result?.displayedGrade ?? '-';
    final showResolvedNote =
        bundle.options.includeTeacherResolvedBadges &&
        result != null &&
        result.specialGradeOverride == null &&
        (result.wasRResolved || result.wasMsResolved);
    final gradeText = showResolvedNote
        ? '$displayedGrade (เคยแก้)'
        : displayedGrade;

    return DataRow(
      cells: <DataCell>[
        DataCell(Text('${student.studentNumber}')),
        DataCell(Text(student.studentCode)),
        DataCell(
          Text(
            student.isTransferredOut
                ? '${student.fullName} (ย้ายออก)'
                : student.fullName,
          ),
        ),
        for (final cat in bundle.scoreCategories)
          DataCell(
            Text(
              _calculator.formatExactScore(summaryByCatId[cat.id] ?? 0.0),
            ),
          ),
        DataCell(
          Text(
            result == null
                ? '0'
                : _calculator.formatExactScore(result.totalScore),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        DataCell(
          Text(
            gradeText,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: result?.specialGradeOverride != null
                  ? semantic.danger
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
