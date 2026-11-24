import 'package:flutter/material.dart';

import '../../../../core/constants/attendance_status.dart';
import '../../../../core/theme/app_color_scheme.dart';

/// Live per-session attendance counter bar (`มา / สาย / ลา / ขาด / ยังไม่เลือก`)
/// with quick actions: "มาทั้งหมด", "หมายเหตุคาบ", and "ปลดล็อกเพื่อแก้ไข".
class AttendanceStatusSummaryBar extends StatelessWidget {
  const AttendanceStatusSummaryBar({
    super.key,
    required this.presentCount,
    required this.lateCount,
    required this.leaveCount,
    required this.absentCount,
    required this.unmarkedCount,
    required this.sessionNote,
    required this.isLocked,
    required this.isBusy,
    required this.canMarkAllPresent,
    required this.onMarkAllPresent,
    required this.onEditSessionNote,
    required this.onUnlockSession,
  });

  final int presentCount;
  final int lateCount;
  final int leaveCount;
  final int absentCount;
  final int unmarkedCount;
  final String sessionNote;
  final bool isLocked;
  final bool isBusy;
  final bool canMarkAllPresent;
  final VoidCallback onMarkAllPresent;
  final VoidCallback onEditSessionNote;
  final VoidCallback onUnlockSession;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _CounterChip(
                  label: '${AttendanceStatus.present.thaiLabel} $presentCount',
                  bg: semantic.presentContainer,
                  fg: semantic.present,
                ),
                _CounterChip(
                  label: '${AttendanceStatus.late.thaiLabel} $lateCount',
                  bg: semantic.lateContainer,
                  fg: semantic.late,
                ),
                _CounterChip(
                  label: '${AttendanceStatus.leave.thaiLabel} $leaveCount',
                  bg: semantic.leaveContainer,
                  fg: semantic.leave,
                ),
                _CounterChip(
                  label: '${AttendanceStatus.absent.thaiLabel} $absentCount',
                  bg: semantic.absentContainer,
                  fg: semantic.absent,
                ),
                if (unmarkedCount > 0)
                  _CounterChip(
                    label: 'ยังไม่เลือก $unmarkedCount',
                    bg: colorScheme.surfaceContainerHighest,
                    fg: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (isLocked)
                  FilledButton.icon(
                    onPressed: isBusy ? null : onUnlockSession,
                    icon: const Icon(Icons.lock_open_rounded, size: 18),
                    label: const Text('ปลดล็อกเพื่อแก้ไข'),
                  )
                else
                  FilledButton.tonalIcon(
                    onPressed: (isBusy || !canMarkAllPresent)
                        ? null
                        : onMarkAllPresent,
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('มาทั้งหมด'),
                  ),
                OutlinedButton.icon(
                  onPressed: (isBusy || isLocked) ? null : onEditSessionNote,
                  icon: Icon(
                    sessionNote.isNotEmpty
                        ? Icons.sticky_note_2_rounded
                        : Icons.sticky_note_2_outlined,
                    size: 18,
                  ),
                  label: Text(
                    sessionNote.isNotEmpty ? 'แก้ไขหมายเหตุคาบ' : 'หมายเหตุคาบ',
                  ),
                ),
              ],
            ),
            if (sessionNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'หมายเหตุคาบ: $sessionNote',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CounterChip extends StatelessWidget {
  const _CounterChip({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
