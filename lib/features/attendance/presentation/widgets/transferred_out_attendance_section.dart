import 'package:flutter/material.dart';

import '../../../../core/constants/attendance_status.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../homeroom_roster/domain/entities/class_enrollment.dart';
import '../../domain/entities/attendance_record.dart';

/// Collapsed read-only section displaying `transferred_out` students who still
/// have a historical `attendance_record` on the selected past session date.
///
/// Kept separate from the main active list so renumbered student numbers never
/// clash visually and historical totals stay strictly scoped to active students.
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

    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: Icon(
          Icons.person_off_outlined,
          size: 20,
          color: semantic.warning,
        ),
        title: Text(
          'นักเรียนที่ย้ายออกแล้ว (${students.length} คน)',
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'แสดงประวัติการเช็คชื่อเดิมแบบอ่านอย่างเดียว (ไม่นับรวมในยอดสรุปปัจจุบัน)',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        children: [
          for (final student in students) ...[
            _TransferredHistoryRow(
              student: student,
              record: recordsByEnrollment[student.id],
              semantic: semantic,
            ),
            const SizedBox(height: 8),
          ],
        ],
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

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: semantic.warning.withValues(alpha: 0.35)),
      ),
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
                borderRadius: BorderRadius.circular(10),
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
