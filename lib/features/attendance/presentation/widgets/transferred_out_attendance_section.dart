import 'package:flutter/material.dart';

import '../../../../core/constants/attendance_status.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../homeroom_roster/domain/entities/class_enrollment.dart';
import '../../domain/entities/attendance_record.dart';

/// Collapsed read-only section displaying `transferred_out` students who still
/// have a historical `attendance_record` on the selected past session date.
class TransferredOutAttendanceSection extends StatelessWidget {
  const TransferredOutAttendanceSection({
    super.key,
    required this.students,
    required this.recordsByEnrollment,
  });

  final List<ClassEnrollment> students;
  final Map<String, AttendanceRecord> recordsByEnrollment;

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          initiallyExpanded: false,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(
            Icons.person_off_outlined,
            size: 20,
            color: semantic.warning,
          ),
          title: Text(
            'นักเรียนที่ย้ายออกแล้ว (${students.length} คน)',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: AppTheme.tabularFigures,
            ),
          ),
          subtitle: Text(
            'แสดงประวัติการเช็คชื่อเดิมแบบอ่านอย่างเดียว (ไม่นับรวมในยอดสรุปปัจจุบัน)',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < students.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colorScheme.outlineVariant,
                      ),
                    _TransferredHistoryRow(
                      student: students[i],
                      record: recordsByEnrollment[students[i].id],
                      semantic: semantic,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferredHistoryRow extends StatelessWidget {
  const _TransferredHistoryRow({
    required this.student,
    required this.record,
    required this.semantic,
  });

  final ClassEnrollment student;
  final AttendanceRecord? record;
  final AppSemanticColors semantic;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final status = record?.status;
    final note = record?.note.trim() ?? '';

    final (Color fg, Color bg)? statusColors = status == null
        ? null
        : switch (status) {
            AttendanceStatus.present => (
              semantic.present,
              semantic.presentContainer,
            ),
            AttendanceStatus.late => (semantic.late, semantic.lateContainer),
            AttendanceStatus.leave => (semantic.leave, semantic.leaveContainer),
            AttendanceStatus.absent => (
              semantic.absent,
              semantic.absentContainer,
            ),
          };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${student.fullName} (เลขที่เดิม ${student.studentNumber})',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'รหัส ${student.studentCode}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontFeatures: AppTheme.tabularFigures,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: semantic.warningContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        student.transferredOutAt != null
                            ? 'ย้ายออกเมื่อ ${ThaiDateFormatter.formatShortDate(student.transferredOutAt!)}'
                            : 'ย้ายออก',
                        style: textTheme.labelSmall?.copyWith(
                          color: semantic.warning,
                          fontWeight: FontWeight.w700,
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                    ),
                  ],
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'หมายเหตุเดิม: $note',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (status != null && statusColors != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColors.$2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.thaiLabel,
                style: textTheme.labelMedium?.copyWith(
                  color: statusColors.$1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
