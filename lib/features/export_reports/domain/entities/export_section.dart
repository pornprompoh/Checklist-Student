/// Report sections that teachers can freely toggle on/off before exporting.
///
/// Pure Dart enum.
enum ExportSection {
  roster(
    key: 'roster',
    thaiTitle: 'ใบรายชื่อนักเรียน',
    shortDescription: 'เลขที่ รหัสนักเรียน ชื่อ-นามสกุล และวันที่เข้าเรียน (พ.ศ.)',
  ),
  attendance(
    key: 'attendance',
    thaiTitle: 'สถิติและตารางเวลาเรียน',
    shortDescription: 'ตารางเช็คชื่อรายคาบ (ม/ส/ล/ข) ยอดรวม และร้อยละขาดเรียน',
  ),
  assignments(
    key: 'assignments',
    thaiTitle: 'รายการงานและคะแนนรายชิ้น',
    shortDescription: 'คะแนนแต่ละชิ้นงานตามจริงพร้อมคะแนนเต็มและป้ายบังคับส่ง',
  ),
  gradeSummary(
    key: 'gradeSummary',
    thaiTitle: 'สรุปคะแนนและเกรด (ปพ.5)',
    shortDescription: 'คะแนนรวมแยกหมวด คะแนนสุทธิไม่ปัดเศษ เกรด และตารางแจกแจงเกรด',
  );

  const ExportSection({
    required this.key,
    required this.thaiTitle,
    required this.shortDescription,
  });

  final String key;
  final String thaiTitle;
  final String shortDescription;
}
