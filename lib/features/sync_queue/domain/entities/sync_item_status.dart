/// Lifecycle state of an offline queued mutation item.
///
/// Pure Dart enum.
enum SyncItemStatus {
  pending('pending', 'รอซิงค์'),
  syncing('syncing', 'กำลังซิงค์'),
  conflict('conflict', 'ข้อมูลชนกัน'),
  failed('failed', 'ซิงค์ไม่สำเร็จ');

  const SyncItemStatus(this.dbValue, this.thaiLabel);

  final String dbValue;
  final String thaiLabel;

  static SyncItemStatus fromDbValue(String value) {
    return SyncItemStatus.values.firstWhere(
      (item) => item.dbValue == value,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'Unknown SyncItemStatus value',
      ),
    );
  }
}
