/// Student enrollment lifecycle status matching PostgreSQL `CHECK` constraint
/// `status IN ('active', 'transferred_out')` on `homeroom_students` and
/// `class_enrollments`.
///
/// Pure Dart enum.
enum StudentLifecycleStatus {
  active('active', 'กำลังเรียน'),
  transferredOut('transferred_out', 'ย้ายออก');

  const StudentLifecycleStatus(this.dbValue, this.thaiLabel);

  final String dbValue;
  final String thaiLabel;

  static StudentLifecycleStatus fromDbValue(String value) {
    for (final status in StudentLifecycleStatus.values) {
      if (status.dbValue == value) {
        return status;
      }
    }
    throw ArgumentError.value(
      value,
      'value',
      'Unknown student lifecycle status',
    );
  }
}
