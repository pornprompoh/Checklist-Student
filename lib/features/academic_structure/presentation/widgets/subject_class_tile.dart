import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/subject_class.dart';

/// Single room row inside a [SubjectCard] showing room name, pin toggle,
/// teaching-day chips (`จ.`–`อา.`), and edit/delete icon buttons.
class SubjectClassTile extends StatelessWidget {
  const SubjectClassTile({
    super.key,
    required this.subjectClass,
    required this.isBusy,
    required this.onTogglePin,
    required this.onEdit,
    required this.onDelete,
  });

  final SubjectClass subjectClass;
  final bool isBusy;
  final VoidCallback onTogglePin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);
    final sortedDays = List<int>.of(subjectClass.teachingDays)..sort();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
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
                        size: 16,
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
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'แก้ไขห้องเรียน',
                onPressed: isBusy ? null : onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'ลบห้องเรียน',
                onPressed: isBusy ? null : onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: semantic.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
        ],
      ),
    );
  }
}
