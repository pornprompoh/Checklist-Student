import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/student_portal_class_detail.dart';
import 'student_portal_class_assignments_section.dart';
import 'student_portal_class_attendance_section.dart';
import 'student_portal_score_grade_strip.dart';

/// Responsive subject-class card for Student Portal structured in 3 scannable
/// zones: score/grade summary, attendance summary, and assignment checklist.
class StudentPortalClassCard extends StatelessWidget {
  const StudentPortalClassCard({super.key, required this.detail});

  final StudentPortalClassDetail detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          detail.subjectCode,
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                            fontFeatures: AppTheme.tabularFigures,
                          ),
                        ),
                      ),
                      Text(
                        'ห้อง ${detail.roomName} · เลขที่ ${detail.studentNumber}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    detail.subjectName,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (detail.enrollmentStatus == 'transferred_out')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: semantic.warningContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ย้ายออกแล้ว',
                    style: textTheme.labelSmall?.copyWith(
                      color: semantic.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          StudentPortalScoreGradeStrip(detail: detail),
          const Divider(height: 24),
          StudentPortalClassAttendanceSection(
            summary: detail.attendanceSummary,
            records: detail.attendanceRecords,
          ),
          const Divider(height: 24),
          StudentPortalClassAssignmentsSection(
            assignments: detail.assignments,
            showScoreToStudent: detail.showScoreToStudent,
          ),
        ],
      ),
    );
  }
}
