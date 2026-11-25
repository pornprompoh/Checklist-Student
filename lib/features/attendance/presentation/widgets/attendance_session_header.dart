import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/class_workspace_bar.dart';

/// Option model for switching between subject-classes within the active term.
class AttendanceClassOption {
  const AttendanceClassOption({required this.id, required this.label});

  final String id;
  final String label;
}

enum _AttendanceMenuAction { history, rules, sessionNote }

/// Minimal top header for the Attendance Check-In page:
/// [AppPageHeader] with secondary actions tucked into a `⋯` menu + borderless
/// pinned [ClassWorkspaceBar], followed by a flat class & date selector row.
class AttendanceSessionHeader extends StatelessWidget {
  const AttendanceSessionHeader({
    super.key,
    required this.classOptions,
    required this.selectedClassId,
    required this.selectedDate,
    required this.hasSavedSession,
    required this.isLocked,
    required this.isBusy,
    this.sessionNote = '',
    required this.onSelectClass,
    required this.onPreviousDay,
    required this.onPickDate,
    required this.onNextDay,
    required this.onOpenHistory,
    required this.onOpenRules,
    this.onEditSessionNote,
    this.inlineStatusTrailing,
  });

  final List<AttendanceClassOption> classOptions;
  final String selectedClassId;
  final DateTime selectedDate;
  final bool hasSavedSession;
  final bool isLocked;
  final bool isBusy;
  final String sessionNote;
  final ValueChanged<String> onSelectClass;
  final VoidCallback onPreviousDay;
  final VoidCallback onPickDate;
  final VoidCallback onNextDay;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenRules;
  final VoidCallback? onEditSessionNote;

  /// Optional inline status counters + single contextual CTA placed on the
  /// same flat control row on wide viewports.
  final Widget? inlineStatusTrailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
            PopupMenuButton<_AttendanceMenuAction>(
              tooltip: 'ตัวเลือกเพิ่มเติม',
              enabled: !isBusy,
              icon: Icon(
                Icons.more_horiz_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              onSelected: (action) {
                switch (action) {
                  case _AttendanceMenuAction.history:
                    onOpenHistory();
                  case _AttendanceMenuAction.rules:
                    onOpenRules();
                  case _AttendanceMenuAction.sessionNote:
                    onEditSessionNote?.call();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _AttendanceMenuAction.history,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.history_rounded, size: 18),
                    title: Text('ประวัติคาบ'),
                  ),
                ),
                const PopupMenuItem(
                  value: _AttendanceMenuAction.rules,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.tune_rounded, size: 18),
                    title: Text('ตั้งค่าเกณฑ์ มส'),
                  ),
                ),
                if (onEditSessionNote != null && !isLocked)
                  PopupMenuItem(
                    value: _AttendanceMenuAction.sessionNote,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        sessionNote.isNotEmpty
                            ? Icons.sticky_note_2_rounded
                            : Icons.sticky_note_2_outlined,
                        size: 18,
                      ),
                      title: Text(
                        sessionNote.isNotEmpty
                            ? 'แก้ไขหมายเหตุคาบ'
                            : 'หมายเหตุคาบ',
                      ),
                    ),
                  ),
              ],
            ),
          ],
          bottom: ClassWorkspaceBar(
            subjectClassId: selectedClassId,
            activeTab: ClassWorkspaceTab.attendance,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (classOptions.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: DropdownButtonFormField<String>(
                      key: ValueKey<String>(selectedClassId),
                      initialValue:
                          classOptions.any((opt) => opt.id == selectedClassId)
                          ? selectedClassId
                          : classOptions.first.id,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'ห้องเรียน',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
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
            ?inlineStatusTrailing,
          ],
        ),
        if (sessionNote.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'หมายเหตุคาบ: $sessionNote',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
      color: colorScheme.surface,
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
                  horizontal: 10,
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
                    const SizedBox(width: 6),
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
