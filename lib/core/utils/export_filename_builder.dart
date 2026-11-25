/// Pure Dart filename builder generating OS-safe (Windows/macOS/Web) Thai
/// export filenames such as `ปพ5_ว31101_ม.4-1_เทอม1-2569_20261125.pdf`.
///
/// Zero Flutter or Supabase dependencies.
abstract final class ExportFilenameBuilder {
  static final RegExp _forbiddenChars = RegExp(r'[/\\:*?"<>|\s]+');
  static final RegExp _multiDash = RegExp(r'-{2,}');
  static final RegExp _trimDash = RegExp(r'^-+|-+$');

  /// Sanitizes a single filename segment so it is safe across Windows, macOS,
  /// Linux, and Web downloads while preserving Thai, Latin, digits, and dots.
  ///
  /// Example: `' ม.4/1 '` -> `'ม.4-1'`.
  static String sanitizeSegment(String raw, {String fallback = 'report'}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }
    final replaced = trimmed
        .replaceAll(_forbiddenChars, '-')
        .replaceAll(_multiDash, '-')
        .replaceAll(_trimDash, '');
    return replaced.isEmpty ? fallback : replaced;
  }

  /// Resolves a concise Thai report prefix from selected section keys
  /// (`roster`, `attendance`, `assignments`, `gradeSummary`).
  static String resolveReportPrefix(Iterable<String> sectionKeys) {
    final normalized = sectionKeys.toSet();
    if (normalized.isEmpty || normalized.contains('gradeSummary')) {
      return 'ปพ5';
    }
    if (normalized.length == 1) {
      return switch (normalized.first) {
        'roster' => 'ใบรายชื่อ',
        'attendance' => 'เวลาเรียน',
        'assignments' => 'รายการงาน',
        _ => 'รายงาน',
      };
    }
    return 'รายงานรวม';
  }

  /// Builds a standardized OS-safe export filename:
  /// `<prefix>_<subjectCode>_<roomName>_เทอม<termLabel>-<yearBe>_<YYYYMMDD>.<ext>`
  static String build({
    required String reportPrefix,
    required String subjectCode,
    required String roomName,
    required String termLabel,
    required int yearBe,
    required String extension,
    DateTime? exportedAt,
  }) {
    final date = exportedAt ?? DateTime.now();
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');

    final prefix = sanitizeSegment(reportPrefix, fallback: 'รายงาน');
    final code = sanitizeSegment(subjectCode, fallback: 'วิชา');
    final room = sanitizeSegment(roomName, fallback: 'ห้อง');
    final term = sanitizeSegment(termLabel, fallback: '1');
    final cleanExt = extension
        .trim()
        .replaceFirst(RegExp(r'^\.+'), '')
        .toLowerCase();
    final ext = cleanExt.isEmpty ? 'pdf' : cleanExt;

    return '${prefix}_${code}_${room}_เทอม$term-${yearBe}_$y$m$d.$ext';
  }
}
