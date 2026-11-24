import 'ai_parsed_roster_row.dart';

/// Result of uploading a compressed source file to `import-sources` and
/// parsing it via `parse-roster-ai`. Pure Dart entity.
class UploadedImportFileResult {
  const UploadedImportFileResult({
    required this.importFileId,
    required this.storagePath,
    required this.originalFilename,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.students,
  });

  final String importFileId;
  final String storagePath;
  final String originalFilename;
  final String mimeType;
  final int fileSizeBytes;
  final List<AiParsedRosterRow> students;
}
