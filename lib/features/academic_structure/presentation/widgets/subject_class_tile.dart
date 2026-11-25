import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/subject_class.dart';

/// Hairline-separated room row inside a [SubjectCard] showing room name,
/// weekday pills (`จ.`–`อา.`), quick workspace shortcuts, pin toggle, and menu.
class SubjectClassTile extends StatelessWidget {
  const SubjectClassTile({
    super.key,
    required this.subjectClass,
    required this.isBusy,
    required this.onTogglePin,
    required this.onEdit,
    required this.onDelete,
    this.onOpenAttendance,
    this.onOpenGrading,
    this.onOpenGradingPlan,
  });

  final SubjectClass subjectClass;
  final bool isBusy;
  final VoidCallback onTogglePin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onOpenAttendance;
  final VoidCallback? onOpenGrading;
  final VoidCallback? onOpenGradingPlan;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final sortedDays = List<int>.of(subjectClass.teachingDays)..sort();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        subjectClass.roomName,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (subjectClass.isPinned) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.push_pin_rounded,
                        size: 15,
                        color: colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: subjectClass.isPinned
                    ? 'เลิกปักหมุดบนหน้าหลัก'
                    : 'ปักหมุดบนหน้าหลัก',
                onPressed: isBusy ? null : onTogglePin,
                icon: Icon(
                  subjectClass.isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  size: 18,
                  color: subjectClass.isPinned
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'จัดการห้องเรียน',
                enabled: !isBusy,
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined, size: 18),
                      title: Text('แก้ไขห้องเรียน'),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: semantic.danger,
                      ),
                      title: Text(
                        'ลบห้องเรียน',
                        style: TextStyle(color: semantic.danger),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (sortedDays.isEmpty)
                Text(
                  'ยังไม่ระบุวันสอน',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final day in sortedDays)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ThaiDateFormatter.weekdayThaiName(day, short: true),
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              if (onOpenAttendance != null ||
                  onOpenGrading != null ||
                  onOpenGradingPlan != null)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (onOpenAttendance != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        onPressed: isBusy ? null : onOpenAttendance,
                        icon: const Icon(Icons.fact_check_outlined, size: 15),
                        label: const Text('เช็คชื่อ'),
                      ),
                    if (onOpenGrading != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        onPressed: isBusy ? null : onOpenGrading,
                        icon: const Icon(Icons.table_chart_outlined, size: 15),
                        label: const Text('ตารางคะแนน'),
                      ),
                    if (onOpenGradingPlan != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        onPressed: isBusy ? null : onOpenGradingPlan,
                        icon: const Icon(Icons.assignment_outlined, size: 15),
                        label: const Text('แผนเก็บงาน'),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
