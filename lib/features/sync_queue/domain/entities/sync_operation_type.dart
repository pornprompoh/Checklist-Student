/// Mutation verb recorded in the local offline sync queue.
///
/// Pure Dart enum.
enum SyncOperationType {
  create('create', 'เพิ่มข้อมูล'),
  update('update', 'แก้ไขข้อมูล'),
  delete('delete', 'ลบข้อมูล');

  const SyncOperationType(this.dbValue, this.thaiLabel);

  final String dbValue;
  final String thaiLabel;

  static SyncOperationType fromDbValue(String value) {
    return SyncOperationType.values.firstWhere(
      (item) => item.dbValue == value,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'Unknown SyncOperationType value',
      ),
    );
  }
}
