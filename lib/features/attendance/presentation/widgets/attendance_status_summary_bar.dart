import 'package:flutter/material.dart';

import '../../../../core/constants/attendance_status.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';

/// Compact flat inline attendance summary counters (`มา / สาย / ลา / ขาด`).
///
/// Sits on the right side of the slim date context strip directly opposite the
/// date stepper, with zero outer card chrome.
class AttendanceStatusSummaryBar extends StatelessWidget {
  const AttendanceStatusSummaryBar({
    super.key,
    required this.presentCount,
    required this.lateCount,
    required this.leaveCount,
    required this.absentCount,
    required this.unmarkedCount,
  });

  final int presentCount;
  final int lateCount;
  final int leaveCount;
  final int absentCount;
  final int unmarkedCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _CounterPill(
          label: '${AttendanceStatus.present.thaiLabel} $presentCount',
          bg: semantic.presentContainer,
          fg: semantic.present,
        ),
        _CounterPill(
          label: '${AttendanceStatus.late.thaiLabel} $lateCount',
          bg: semantic.lateContainer,
          fg: semantic.late,
        ),
        _CounterPill(
          label: '${AttendanceStatus.leave.thaiLabel} $leaveCount',
          bg: semantic.leaveContainer,
          fg: semantic.leave,
        ),
        _CounterPill(
          label: '${AttendanceStatus.absent.thaiLabel} $absentCount',
          bg: semantic.absentContainer,
          fg: semantic.absent,
        ),
        if (unmarkedCount > 0)
          _CounterPill(
            label: 'ยังไม่เลือก $unmarkedCount',
            bg: colorScheme.surfaceContainer,
            fg: colorScheme.onSurfaceVariant,
          ),
      ],
    );
  }
}

class _CounterPill extends StatelessWidget {
  const _CounterPill({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontFeatures: AppTheme.tabularFigures,
        ),
      ),
    );
  }
}
