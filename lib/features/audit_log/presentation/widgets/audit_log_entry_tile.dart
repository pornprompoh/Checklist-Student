import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/audit_log_target_type.dart';
import '../../domain/entities/score_audit_log_entry.dart';

/// Responsive card rendering one `public.score_audit_logs` entry with
/// `ค่าเดิม → ค่าใหม่`, Buddhist Era timestamp, and initial-entry lock badge.
class AuditLogEntryTile extends StatelessWidget {
  const AuditLogEntryTile({super.key, required this.entry});

  final ScoreAuditLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final isGradeStatus = entry.targetType == AuditLogTargetType.gradeStatus;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _TagChip(
                      label: entry.targetType.thaiLabel,
                      bg: isGradeStatus
                          ? semantic.warningContainer
                          : colorScheme.primaryContainer,
                      fg: isGradeStatus
                          ? semantic.warning
                          : colorScheme.onPrimaryContainer,
                    ),
                    if (entry.isInitialEntry)
                      _TagChip(
                        icon: Icons.lock_outline_rounded,
                        label: 'รายการแรก (ล็อกไว้)',
                        bg: semantic.successContainer,
                        fg: semantic.success,
                      ),
                  ],
                ),
                Text(
                  ThaiDateFormatter.formatDateTime(entry.changedAt),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'เลขที่ ${entry.studentNumber} ${entry.studentFullName} (${entry.studentCode})',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${entry.subjectCode} ${entry.subjectName} · ห้อง ${entry.roomName} '
              '· ${entry.displayTargetLabel} (ปี พ.ศ. ${entry.yearBe})',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    entry.displayOldValue,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  Text(
                    entry.displayNewValue,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isGradeStatus
                          ? semantic.danger
                          : colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });

  final IconData? icon;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
