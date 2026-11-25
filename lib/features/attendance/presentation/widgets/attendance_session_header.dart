import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/class_workspace_bar.dart';

/// Option model for switching between subject-classes within the active term.
class AttendanceClassOption {
  const AttendanceClassOption({required this.id, required this.label});

  final String id;
  final String label;
}

/// Top workspace header on the Attendance Check-In page:
/// [AppPageHeader], [ClassWorkspaceBar], class switcher, compact pill date
/// switcher (`< | 25 พ.ย. 2569 | >`), and clean secondary actions.
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
            Icons.lock_rounded,
          )
        : hasSavedSession
        ? (
            'บันทึกแล้ว',
            semantic.successContainer,
            semantic.success,
            Icons.check_circle_rounded,
          )
        : (
            'ยังไม่เช็ค',
            colorScheme.surfaceContainer,
            colorScheme.onSurfaceVariant,
            Icons.schedule_rounded,
          );

    final dateLabel =
        '${ThaiDateFormatter.weekdayThaiName(selectedDate.weekday, short: true)} '
        '${ThaiDateFormatter.formatShortDate(selectedDate)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppPageHeader(
          title: 'เช็คชื่อรายวัน',
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 15, color: statusFg),
                  const SizedBox(width: 6),
                  Text(
                    statusLabel,
                    style: textTheme.labelMedium?.copyWith(
                      color: statusFg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: isBusy ? null : onOpenHistory,
              icon: const Icon(Icons.history_rounded, size: 18),
              label: const Text('ประวัติคาบ'),
            ),
            OutlinedButton.icon(
              onPressed: isBusy ? null : onOpenRules,
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('ตั้งค่าเกณฑ์ มส'),
            ),
          ],
          bottom: ClassWorkspaceBar(
            subjectClassId: selectedClassId,
            activeTab: ClassWorkspaceTab.attendance,
          ),
        ),
        const SizedBox(height: 12),
        AppSurfaceCard(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (classOptions.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: DropdownButtonFormField<String>(
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
                          child: Text(
                            opt.label,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                ),
              _DateStepperPill(
                dateLabel: dateLabel,
                isBusy: isBusy,
                onPreviousDay: onPreviousDay,
                onPickDate: onPickDate,
                onNextDay: onNextDay,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateStepperPill extends StatelessWidget {
  const _DateStepperPill({
    required this.dateLabel,
    required this.isBusy,
    required this.onPreviousDay,
    required this.onPickDate,
    required this.onNextDay,
  });

  final String dateLabel;
  final bool isBusy;
  final VoidCallback onPreviousDay;
  final VoidCallback onPickDate;
  final VoidCallback onNextDay;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'วันก่อนหน้า',
            visualDensity: VisualDensity.compact,
            onPressed: isBusy ? null : onPreviousDay,
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
          ),
          Container(width: 1, height: 22, color: colorScheme.outlineVariant),
          Flexible(
            child: InkWell(
              onTap: isBusy ? null : onPickDate,
              mouseCursor: isBusy
                  ? MouseCursor.defer
                  : SystemMouseCursors.click,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        dateLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, height: 22, color: colorScheme.outlineVariant),
          IconButton(
            tooltip: 'วันถัดไป',
            visualDensity: VisualDensity.compact,
            onPressed: isBusy ? null : onNextDay,
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
