import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../../core/utils/image_pdf_compressor.dart';
import '../../domain/entities/uploaded_import_file.dart';
import '../models/ai_parsed_roster_row_dto.dart';

/// Remote data source uploading compressed roster images/PDFs to the private
/// `import-sources` bucket, recording metadata in `public.import_files`, and
/// invoking the `parse-roster-ai` Supabase Edge Function.
class AiRosterRemoteDataSource {
  const AiRosterRemoteDataSource(this._client);

  final SupabaseClient _client;
  static const Uuid _uuid = Uuid();

  Future<UploadedImportFileResult> uploadAndParseRosterWithAi({
    required String teacherId,
    required String academicYearId,
    required String homeroomId,
    required String originalFilename,
    required Uint8List compressedBytes,
    required String mimeType,
    required String fileExtension,
  }) async {
    if (compressedBytes.isEmpty ||
        compressedBytes.length > ImagePdfCompressor.maxFileSizeBytes) {
      throw const ValidationException(
        'ขนาดไฟล์เกิน 500 KB ไม่สามารถอัปโหลดได้',
        code: 'FILE_TOO_LARGE',
      );
    }

    final fileUuid = _uuid.v4();
    final storagePath = '$teacherId/$academicYearId/$fileUuid.$fileExtension';
    var uploadedToStorage = false;
    String? insertedFileId;

    try {
      await _client.storage.from('import-sources').uploadBinary(
        storagePath,
        compressedBytes,
        fileOptions: FileOptions(contentType: mimeType),
      );
      uploadedToStorage = true;

      final fileRow = await _client
          .from('import_files')
          .insert(<String, dynamic>{
            'teacher_id': teacherId,
            'academic_year_id': academicYearId,
            'homeroom_id': homeroomId,
            'storage_path': storagePath,
            'original_filename': originalFilename,
            'mime_type': mimeType,
            'file_size_bytes': compressedBytes.length,
          })
          .select('id')
          .single();
      insertedFileId = fileRow['id'] as String;

      final response = await _client.functions.invoke(
        'parse-roster-ai',
        body: <String, dynamic>{
          'storage_path': storagePath,
          'mime_type': mimeType,
        },
      );

      final data = response.data;
      final rawStudents = (data is Map && data['students'] is List)
          ? (data['students'] as List)
          : const <dynamic>[];

      final students = rawStudents
          .whereType<Map>()
          .map(
            (item) => AiParsedRosterRowDto.fromJson(
              Map<String, dynamic>.from(item),
            ).toEntity(),
          )
          .toList(growable: false);

      return UploadedImportFileResult(
        importFileId: insertedFileId,
        storagePath: storagePath,
        originalFilename: originalFilename,
        mimeType: mimeType,
        fileSizeBytes: compressedBytes.length,
        students: students,
      );
    } on FunctionException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[AiRosterRemoteDataSource] parse-roster-ai failed '
          '(status=${error.status}, reason=${error.reasonPhrase}, '
          'details=${error.details})',
        );
      }
      await _cleanupOrphanedUpload(
        uploadedToStorage: uploadedToStorage,
        storagePath: storagePath,
        importFileId: insertedFileId,
      );
      throw ThaiErrorMapper.toAppException(error);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[AiRosterRemoteDataSource] Unexpected error: $error');
      }
      await _cleanupOrphanedUpload(
        uploadedToStorage: uploadedToStorage,
        storagePath: storagePath,
        importFileId: insertedFileId,
      );
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  /// Removes uploaded source file & DB metadata when Edge Function invocation
  /// fails so retries stay clean and Free-Tier storage is not wasted.
  Future<void> _cleanupOrphanedUpload({
    required bool uploadedToStorage,
    required String storagePath,
    required String? importFileId,
  }) async {
    if (uploadedToStorage) {
      try {
        await _client.storage.from('import-sources').remove(<String>[
          storagePath,
        ]);
      } catch (_) {}
    }
    if (importFileId != null) {
      try {
        await _client.from('import_files').delete().eq('id', importFileId);
      } catch (_) {}
    }
  }
}

final aiRosterRemoteDataSourceProvider = Provider<AiRosterRemoteDataSource>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return AiRosterRemoteDataSource(client);
});
