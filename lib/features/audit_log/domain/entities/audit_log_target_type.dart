/// Target category of a `public.score_audit_logs` row matching PostgreSQL
/// CHECK constraint `target_type IN ('score', 'grade_status')`.
enum AuditLogTargetType {
  score('score', 'คะแนน'),
  gradeStatus('grade_status', 'สถานะ ร/มส');

  const AuditLogTargetType(this.dbValue, this.thaiLabel);

  final String dbValue;
  final String thaiLabel;

  static AuditLogTargetType fromDbValue(String value) {
    for (final type in AuditLogTargetType.values) {
      if (type.dbValue == value) {
        return type;
      }
    }
    throw ArgumentError.value(
      value,
      'value',
      'Unknown score_audit_logs.target_type value',
    );
  }
}
