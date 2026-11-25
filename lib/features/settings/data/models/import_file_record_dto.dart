import '../../domain/entities/import_file_record.dart';

/// Data transfer object mapping `public.import_files` (joined with
/// `public.academic_years.year_be`) to [ImportFileRecord].
class ImportFileRecordDto {
  const ImportFileRecordDto({
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

  factory ImportFileRecordDto.fromJson(Map<String, dynamic> json) {
    return ImportFileRecordDto(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      academicYearId: json['academic_year_id'] as String,
      academicYearBe: _extractYearBe(json['academic_years']),
      homeroomId: json['homeroom_id'] as String?,
      storagePath: json['storage_path'] as String,
      originalFilename: json['original_filename'] as String,
      mimeType: json['mime_type'] as String,
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

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

  ImportFileRecord toEntity() => ImportFileRecord(
    id: id,
    teacherId: teacherId,
    academicYearId: academicYearId,
    academicYearBe: academicYearBe,
    homeroomId: homeroomId,
    storagePath: storagePath,
    originalFilename: originalFilename,
    mimeType: mimeType,
    fileSizeBytes: fileSizeBytes,
    createdAt: createdAt,
    deletedAt: deletedAt,
  );

  static int _extractYearBe(Object? joined) {
    if (joined is Map<String, dynamic>) {
      return (joined['year_be'] as num?)?.toInt() ?? 0;
    }
    if (joined is List && joined.isNotEmpty && joined.first is Map) {
      final map = Map<String, dynamic>.from(joined.first as Map);
      return (map['year_be'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }
}
