import 'dart:convert';

import '../../../../core/utils/thai_date_formatter.dart';
import '../entities/score_audit_log_entry.dart';

/// Pure Dart serializer exporting [ScoreAuditLogEntry] lists to UTF-8 BOM CSV
/// (Excel-safe Thai text) and structured pretty-printed JSON.
class AuditLogExportService {
  const AuditLogExportService();

  static const String utf8Bom = '\uFEFF';

  static const List<String> csvHeaders = <String>[
    'วันที่-เวลา (พ.ศ.)',
    'ปีการศึกษา',
    'รหัสวิชา',
    'ชื่อวิชา',
    'ห้อง',
    'เลขที่',
    'รหัสนักเรียน',
    'ชื่อ-นามสกุล',
    'ประเภท',
    'ชิ้นงาน',
    'ค่าเดิม',
    'ค่าใหม่',
    'รายการแรก (ล็อก)',
  ];

  /// Builds an RFC-4180 compliant CSV string prefixed with UTF-8 BOM so Thai
  /// text opens cleanly in Microsoft Excel without garbled characters.
  String buildCsvContent(List<ScoreAuditLogEntry> entries) {
    final buffer = StringBuffer(utf8Bom);
    buffer.writeln(csvHeaders.map(_escapeCsvField).join(','));

    for (final entry in entries) {
      final row = <String>[
        ThaiDateFormatter.formatDateTime(entry.changedAt),
        '${entry.yearBe}',
        entry.subjectCode,
        entry.subjectName,
        entry.roomName,
        '${entry.studentNumber}',
        entry.studentCode,
        entry.studentFullName,
        entry.targetType.thaiLabel,
        entry.displayTargetLabel,
        entry.displayOldValue,
        entry.displayNewValue,
        entry.isInitialEntry ? 'ใช่' : 'ไม่ใช่',
      ];
      buffer.writeln(row.map(_escapeCsvField).join(','));
    }

    return buffer.toString();
  }

  /// Builds a pretty-printed JSON backup payload containing export metadata
  /// and all audit log [entries].
  String buildJsonContent(
    List<ScoreAuditLogEntry> entries, {
    required int? yearBe,
    required DateTime exportedAt,
  }) {
    final payload = <String, dynamic>{
      'exported_at_iso': exportedAt.toUtc().toIso8601String(),
      'year_be': yearBe,
      'total_records': entries.length,
      'records': entries
          .map(
            (entry) => <String, dynamic>{
              'id': entry.id,
              'changed_at_iso': entry.changedAt.toUtc().toIso8601String(),
              'changed_at_thai': ThaiDateFormatter.formatDateTime(
                entry.changedAt,
              ),
              'year_be': entry.yearBe,
              'subject_code': entry.subjectCode,
              'subject_name': entry.subjectName,
              'room_name': entry.roomName,
              'student_number': entry.studentNumber,
              'student_code': entry.studentCode,
              'student_full_name': entry.studentFullName,
              'target_type': entry.targetType.dbValue,
              'target_type_label': entry.targetType.thaiLabel,
              'assignment_title': entry.assignmentTitle,
              'old_value': entry.oldValue,
              'new_value': entry.newValue,
              'is_initial_entry': entry.isInitialEntry,
            },
          )
          .toList(growable: false),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Builds a clean download filename such as `audit_log_BE2569_20261125.csv`.
  String buildExportFileName({
    int? yearBe,
    required String extension,
    DateTime? now,
  }) {
    final date = now ?? DateTime.now();
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final cleanExt = extension.trim().replaceFirst(RegExp(r'^\.+'), '');
    final yearSegment = yearBe == null ? 'all' : 'BE$yearBe';
    return 'audit_log_${yearSegment}_$y$m$d.$cleanExt';
  }

  static String _escapeCsvField(String raw) {
    final needsQuotes =
        raw.contains(',') ||
        raw.contains('"') ||
        raw.contains('\n') ||
        raw.contains('\r');
    if (!needsQuotes) {
      return raw;
    }
    final escaped = raw.replaceAll('"', '""');
    return '"$escaped"';
  }
}
