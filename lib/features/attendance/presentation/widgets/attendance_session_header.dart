import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/thai_date_formatter.dart';

/// Option model for switching between subject-classes within the active term.
class AttendanceClassOption {
  const AttendanceClassOption({required this.id, required this.label});

  final String id;
  final String label;
}

/// Top session control bar on the Attendance Check-In page:
/// class selector, Buddhist Era date switcher, history & rules shortcuts,
/// and current session lock/saved status pill.
class AttendanceSessionHeader extends StatelessWidget {
  const AttendanceSessionHeader({
    super.key,
    required this.classOptions,
    required this.selectedClassId,
    required this.selectedDate,
    required this.hasSavedSession,
    required this.isLocked,
    required this.isBusy,
    required this.onSelectClass,
    required this.onPreviousDay,
    required this.onPickDate,
    required this.onNextDay,
    required this.onOpenHistory,
    required this.onOpenRules,
  });

  final List<AttendanceClassOption> classOptions;
  final String selectedClassId;
  final DateTime selectedDate;
  final bool hasSavedSession;
  final bool isLocked;
  final bool isBusy;
  final ValueChanged<String> onSelectClass;
  final VoidCallback onPreviousDay;
  final VoidCallback onPickDate;
  final VoidCallback onNextDay;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenRules;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = AppSemanticColors.of(context);

    final (String statusLabel, Color statusBg, Color statusFg, IconData icon) =
        isLocked
        ? (
            'ล็อกกันแก้ไข',
            semantic.warningContainer,
            semantic.warning,
            Icons.lock_outline_rounded,
          )
        : hasSavedSession
        ? (
            'บันทึกแล้ว',
            semantic.successContainer,
            semantic.success,
            Icons.check_circle_outline_rounded,
          )
        : (
            'ยังไม่เช็ค',
            colorScheme.surfaceContainerHighest,
            colorScheme.onSurfaceVariant,
            Icons.radio_button_unchecked_rounded,
          );

    final dateLabel =
        '${ThaiDateFormatter.weekdayThaiName(selectedDate.weekday, short: true)} '
        '${ThaiDateFormatter.formatShortDate(selectedDate)}';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fact_check_outlined,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'เช็คชื่อรายวัน',
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 15, color: statusFg),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: textTheme.labelMedium?.copyWith(
                          color: statusFg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (classOptions.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                key: ValueKey<String>(selectedClassId),
                initialValue:
                    classOptions.any((opt) => opt.id == selectedClassId)
                    ? selectedClassId
                    : classOptions.first.id,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'รายวิชาและห้องเรียน',
                  isDense: true,
                ),
                items: [
                  for (final opt in classOptions)
                    DropdownMenuItem<String>(
                      value: opt.id,
                      child: Text(opt.label, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: isBusy
                    ? null
                    : (id) {
                        if (id != null && id != selectedClassId) {
                          onSelectClass(id);
                        }
                      },
              ),
              const SizedBox(height: 10),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.outlined(
                      tooltip: 'วันก่อนหน้า',
                      onPressed: isBusy ? null : onPreviousDay,
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: OutlinedButton.icon(
                        onPressed: isBusy ? null : onPickDate,
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                        ),
                        label: Text(
                          dateLabel,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.outlined(
                      tooltip: 'วันถัดไป',
                      onPressed: isBusy ? null : onNextDay,
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    OutlinedButton.icon(
                      onPressed: isBusy ? null : onOpenHistory,
                      icon: const Icon(Icons.history_rounded, size: 18),
                      label: const Text('ประวัติคาบ'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: isBusy ? null : onOpenRules,
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('ตั้งค่าเกณฑ์ มส'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
