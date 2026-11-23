/// Assignment submission status matching
/// `student_scores.submission_status` CHECK constraint in PostgreSQL.
enum SubmissionStatus {
  submitted('submitted', 'ส่งแล้ว'),
  late('late', 'ส่งช้า'),
  missing('missing', 'ยังไม่ส่ง');

  const SubmissionStatus(this.dbValue, this.thaiLabel);

  /// Exact string value stored in PostgreSQL `student_scores.submission_status`.
  final String dbValue;

  /// Thai display label shown in the UI and exported reports.
  final String thaiLabel;

  /// Parses [value] from database storage into a [SubmissionStatus].
  ///
  /// Throws an [ArgumentError] if [value] does not match any supported status.
  static SubmissionStatus fromDbValue(String value) {
    final matched = tryFromDbValue(value);
    if (matched == null) {
      throw ArgumentError.value(
        value,
        'value',
        'Unknown student_scores.submission_status value',
      );
    }
    return matched;
  }

  /// Parses [value] safely, returning `null` if unknown or `null`.
  static SubmissionStatus? tryFromDbValue(String? value) {
    if (value == null) {
      return null;
    }
    for (final status in SubmissionStatus.values) {
      if (status.dbValue == value) {
        return status;
      }
    }
    return null;
  }
}
