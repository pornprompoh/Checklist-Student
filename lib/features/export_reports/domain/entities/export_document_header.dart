/// Per-export editable document header metadata initialized from
/// `TeacherProfile` and subject-class details.
///
/// Edits apply ONLY to this export session and NEVER overwrite `public.teachers`.
class ExportDocumentHeader {
  const ExportDocumentHeader({
    required this.reportTitle,
    required this.schoolName,
    required this.department,
    required this.teacherName,
    required this.academicYearBe,
    required this.termLabel,
    required this.subjectCode,
    required this.subjectName,
    required this.roomName,
    required this.exportedAt,
  });

  final String reportTitle;
  final String schoolName;
  final String department;
  final String teacherName;
  final int academicYearBe;
  final String termLabel;
  final String subjectCode;
  final String subjectName;
  final String roomName;
  final DateTime exportedAt;

  ExportDocumentHeader copyWith({
    String? reportTitle,
    String? schoolName,
    String? department,
    String? teacherName,
    int? academicYearBe,
    String? termLabel,
    String? subjectCode,
    String? subjectName,
    String? roomName,
    DateTime? exportedAt,
  }) {
    return ExportDocumentHeader(
      reportTitle: reportTitle ?? this.reportTitle,
      schoolName: schoolName ?? this.schoolName,
      department: department ?? this.department,
      teacherName: teacherName ?? this.teacherName,
      academicYearBe: academicYearBe ?? this.academicYearBe,
      termLabel: termLabel ?? this.termLabel,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      roomName: roomName ?? this.roomName,
      exportedAt: exportedAt ?? this.exportedAt,
    );
  }
}
