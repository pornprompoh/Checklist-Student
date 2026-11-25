import '../../../../core/constants/attendance_status.dart';
import '../../../../core/constants/submission_status.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../grading/domain/services/score_calculator_service.dart';
import '../entities/sync_entity_type.dart';
import '../entities/sync_queue_item.dart';

/// Human-readable Thai field comparison row between a teacher's local offline
/// payload and the authoritative server snapshot for conflict resolution.
///
/// Pure Dart value object.
class SyncConflictFieldDiff {
  const SyncConflictFieldDiff({
    required this.label,
    required this.localValue,
    required this.serverValue,
    required this.isDifferent,
  });

  final String label;
  final String localValue;
  final String serverValue;
  final bool isDifferent;
}

/// Pure Dart formatter translating raw `payload` vs `serverSnapshot` maps into
/// clear Thai field diffs across all 4 [SyncEntityType] values without rounding
/// exact decimal scores.
class SyncConflictFieldFormatter {
  const SyncConflictFieldFormatter();

  static const _scoreCalculator = ScoreCalculatorService();

  List<SyncConflictFieldDiff> formatDiffs(SyncQueueItem item) {
    final local = item.payload;
    final server = item.serverSnapshot ?? const <String, dynamic>{};
    final diffs = <SyncConflictFieldDiff>[];

    switch (item.entityType) {
      case SyncEntityType.attendanceSession:
        _addRow(
          diffs,
          label: 'วันที่คาบเรียน',
          localValue: _formatIsoDate(local['session_date']),
          serverValue: _formatIsoDate(server['session_date']),
        );
        _addRow(
          diffs,
          label: 'สถานะการล็อกคาบ',
          localValue: _formatLockState(local['is_locked']),
          serverValue: _formatLockState(server['is_locked']),
        );
        _addRow(
          diffs,
          label: 'หมายเหตุคาบ',
          localValue: _formatNote(local['note']),
          serverValue: _formatNote(server['note']),
        );
      case SyncEntityType.attendanceRecord:
        _addRow(
          diffs,
          label: 'สถานะเข้าเรียน',
          localValue: _formatAttendanceStatus(local['status']),
          serverValue: _formatAttendanceStatus(server['status']),
        );
        _addRow(
          diffs,
          label: 'หมายเหตุรายบุคคล',
          localValue: _formatNote(local['note']),
          serverValue: _formatNote(server['note']),
        );
      case SyncEntityType.studentScore:
        _addRow(
          diffs,
          label: 'สถานะการส่งงาน',
          localValue: _formatSubmissionStatus(local['submission_status']),
          serverValue: _formatSubmissionStatus(server['submission_status']),
        );
        _addRow(
          diffs,
          label: 'คะแนน',
          localValue: _formatExactScoreValue(local['score']),
          serverValue: _formatExactScoreValue(server['score']),
        );
        _addRow(
          diffs,
          label: 'หมายเหตุ',
          localValue: _formatNote(local['note']),
          serverValue: _formatNote(server['note']),
        );
      case SyncEntityType.specialGradeStatus:
        _addRow(
          diffs,
          label: 'สถานะเกรดพิเศษ',
          localValue: _formatSpecialGrade(local['special_grade_override']),
          serverValue: _formatSpecialGrade(server['special_grade_override']),
        );
        _addRow(
          diffs,
          label: 'บันทึกแก้ ร แล้ว',
          localValue: _formatBool(
            local['mark_r_resolved'] ?? local['was_r_resolved'],
          ),
          serverValue: _formatBool(server['was_r_resolved']),
        );
        _addRow(
          diffs,
          label: 'บันทึกแก้ มส แล้ว',
          localValue: _formatBool(
            local['mark_ms_resolved'] ?? local['was_ms_resolved'],
          ),
          serverValue: _formatBool(server['was_ms_resolved']),
        );
    }

    final localVersion = item.expectedVersion == null
        ? 'สร้างใหม่'
        : 'v${item.expectedVersion}';
    final serverVerNum = (server['version'] as num?)?.toInt();
    final serverVersion = serverVerNum == null ? '-' : 'v$serverVerNum';
    _addRow(
      diffs,
      label: 'เวอร์ชันข้อมูล',
      localValue: localVersion,
      serverValue: serverVersion,
    );

    final serverUpdatedAt = _parseDateTime(server['updated_at']);
    if (serverUpdatedAt != null) {
      diffs.add(
        SyncConflictFieldDiff(
          label: 'เวลาอัปเดตล่าสุดบนเซิร์ฟเวอร์',
          localValue: ThaiDateFormatter.formatDateTime(item.updatedAt),
          serverValue: ThaiDateFormatter.formatDateTime(serverUpdatedAt),
          isDifferent: false,
        ),
      );
    }

    return List<SyncConflictFieldDiff>.unmodifiable(diffs);
  }

  void _addRow(
    List<SyncConflictFieldDiff> target, {
    required String label,
    required String localValue,
    required String serverValue,
  }) {
    target.add(
      SyncConflictFieldDiff(
        label: label,
        localValue: localValue,
        serverValue: serverValue,
        isDifferent: localValue != serverValue,
      ),
    );
  }

  String _formatIsoDate(Object? raw) {
    final parsed = ThaiDateFormatter.parseIsoDate(raw?.toString());
    return parsed == null ? '-' : ThaiDateFormatter.formatShortDate(parsed);
  }

  String _formatLockState(Object? raw) {
    if (raw is! bool) return '-';
    return raw ? 'ล็อกกันแก้ไข' : 'เปิดแก้ไข';
  }

  String _formatAttendanceStatus(Object? raw) {
    final status = AttendanceStatus.tryFromDbValue(raw?.toString());
    return status?.thaiLabel ?? '-';
  }

  String _formatSubmissionStatus(Object? raw) {
    final status = SubmissionStatus.tryFromDbValue(raw?.toString());
    return status?.thaiLabel ?? '-';
  }

  String _formatExactScoreValue(Object? raw) {
    if (raw == null) return 'ยังไม่กรอก';
    if (raw is num) {
      return _scoreCalculator.formatExactScore(raw.toDouble());
    }
    final parsed = double.tryParse(raw.toString());
    if (parsed == null) return 'ยังไม่กรอก';
    return _scoreCalculator.formatExactScore(parsed);
  }

  String _formatSpecialGrade(Object? raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return 'ปกติ';
    return value;
  }

  String _formatBool(Object? raw) {
    if (raw is! bool) return '-';
    return raw ? 'ใช่' : 'ไม่ใช่';
  }

  String _formatNote(Object? raw) {
    final trimmed = raw?.toString().trim() ?? '';
    return trimmed.isEmpty ? '-' : trimmed;
  }

  DateTime? _parseDateTime(Object? raw) {
    if (raw is String && raw.trim().isNotEmpty) {
      return DateTime.tryParse(raw.trim());
    }
    return null;
  }
}
