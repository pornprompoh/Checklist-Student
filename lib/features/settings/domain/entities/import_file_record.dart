/// Domain entity representing a row in `public.import_files` joined with
/// `public.academic_years.year_be` for yearly storage cleanup.
///
/// Pure Dart entity.
class ImportFileRecord {
  const ImportFileRecord({
    required this.id,
    required this.teacherId,
    required this.academicYearId,
    required this.academicYearBe,
    this.homeroomId,
    required this.storagePath,
    required this.originalFilename,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.createdAt,
    this.deletedAt,
  });

  final String id;
  final String teacherId;
  final String academicYearId;
  final int academicYearBe;
  final String? homeroomId;
  final String storagePath;
  final String originalFilename;
  final String mimeType;
  final int fileSizeBytes;
  final DateTime createdAt;
  final DateTime? deletedAt;

  bool get isActive => deletedAt == null;
}
