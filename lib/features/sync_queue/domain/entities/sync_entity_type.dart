/// Supported classroom entities that can be queued for offline synchronization.
///
/// Pure Dart enum.
enum SyncEntityType {
  attendanceSession('attendance_session', 'คาบเช็คชื่อ'),
  attendanceRecord('attendance_record', 'บันทึกเช็คชื่อ'),
  studentScore('student_score', 'คะแนนรายชิ้น'),
  specialGradeStatus('special_grade_status', 'สถานะเกรดพิเศษ ร/มส');

  const SyncEntityType(this.dbValue, this.thaiLabel);

  final String dbValue;
  final String thaiLabel;

  static SyncEntityType fromDbValue(String value) {
    return SyncEntityType.values.firstWhere(
      (item) => item.dbValue == value,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'Unknown SyncEntityType value',
      ),
    );
  }
}
