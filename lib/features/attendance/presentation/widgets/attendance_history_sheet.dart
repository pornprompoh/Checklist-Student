import 'package:flutter/material.dart';

import '../../../../core/constants/attendance_status.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_session.dart';

/// Bottom sheet displaying all recorded [AttendanceSession] dates for the class
/// with lock indicators and 4-state status summaries for instant date jumping.
class AttendanceHistorySheet extends StatelessWidget {
  const AttendanceHistorySheet({
    super.key,
    required this.sessions,
    required this.allRecords,
    required this.selectedDate,
    required this.onSelectDate,
  });

  final List<AttendanceSession> sessions;
  final List<AttendanceRecord> allRecords;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  static Future<void> show(
    BuildContext context, {
    required List<AttendanceSession> sessions,
    required List<AttendanceRecord> allRecords,
    required DateTime selectedDate,
    required ValueChanged<DateTime> onSelectDate,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AttendanceHistorySheet(
        sessions: sessions,
        allRecords: allRecords,
        selectedDate: selectedDate,
        onSelectDate: onSelectDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);

    final recordsBySession = <String, List<AttendanceRecord>>{};
    for (final rec in allRecords) {
      recordsBySession
          .putIfAbsent(rec.sessionId, () => <AttendanceRecord>[])
          .add(rec);
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ประวัติคาบเช็คชื่อ (${sessions.length} คาบ)',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              if (sessions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'ยังไม่มีประวัติการเช็คชื่อในห้องเรียนนี้',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: sessions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final list =
                          recordsBySession[session.id] ??
                          const <AttendanceRecord>[];
                      final p = list
                          .where((r) => r.status == AttendanceStatus.present)
                          .length;
                      final l = list
                          .where((r) => r.status == AttendanceStatus.late)
                          .length;
                      final lv = list
                          .where((r) => r.status == AttendanceStatus.leave)
                          .length;
                      final a = list
                          .where((r) => r.status == AttendanceStatus.absent)
                          .length;
                      final isSelected =
                          ThaiDateFormatter.toIsoDate(session.sessionDate) ==
                          ThaiDateFormatter.toIsoDate(selectedDate);

                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                          ),
                        ),
                        tileColor: isSelected
                            ? colorScheme.primaryContainer.withValues(
                                alpha: 0.35,
                              )
                            : null,
                        leading: Icon(
                          session.isLocked
                              ? Icons.lock_outline_rounded
                              : Icons.event_note_outlined,
                          color: session.isLocked
                              ? semantic.warning
                              : colorScheme.primary,
                        ),
                        title: Text(
                          'วัน${ThaiDateFormatter.weekdayThaiName(session.sessionDate.weekday)}ที่ '
                          '${ThaiDateFormatter.formatShortDate(session.sessionDate)}',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          'มา $p · สาย $l · ลา $lv · ขาด $a'
                          '${session.note.isNotEmpty ? ' · ${session.note}' : ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          onSelectDate(session.sessionDate);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
