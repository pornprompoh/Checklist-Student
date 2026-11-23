/// Fixed 4-state classroom attendance status matching
/// `attendance_records.status` CHECK constraint in PostgreSQL.
enum AttendanceStatus {
  present('present', 'มา'),
  late('late', 'สาย'),
  leave('leave', 'ลา'),
  absent('absent', 'ขาด');

  const AttendanceStatus(this.dbValue, this.thaiLabel);

  /// Exact string value stored in PostgreSQL `attendance_records.status`.
  final String dbValue;

  /// Thai display label shown in the UI and exported reports.
  final String thaiLabel;

  /// Parses [value] from database storage into an [AttendanceStatus].
  ///
  /// Throws an [ArgumentError] if [value] does not match any supported status.
  static AttendanceStatus fromDbValue(String value) {
    final matched = tryFromDbValue(value);
    if (matched == null) {
      throw ArgumentError.value(
        value,
        'value',
        'Unknown attendance_records.status value',
      );
    }
    return matched;
  }

  /// Parses [value] safely, returning `null` if unknown or `null`.
  static AttendanceStatus? tryFromDbValue(String? value) {
    if (value == null) {
      return null;
    }
    for (final status in AttendanceStatus.values) {
      if (status.dbValue == value) {
        return status;
      }
    }
    return null;
  }
}
