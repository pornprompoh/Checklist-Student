import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/roster_import_result.dart';
import '../../domain/entities/roster_import_row_preview.dart';
import '../../domain/entities/student_lifecycle_status.dart';
import '../../domain/services/roster_renumber_service.dart';
import '../models/homeroom_dto.dart';
import '../models/homeroom_student_dto.dart';

/// Remote data source managing `public.homerooms`, `public.student_identities`,
/// `public.homeroom_students`, and RPC `public.sync_homeroom_student_update`.
class HomeroomRosterRemoteDataSource {
  const HomeroomRosterRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const String _homeroomColumns =
      'id, teacher_id, term_id, name, created_at, updated_at';
  static const String _homeroomStudentColumns =
      'id, teacher_id, homeroom_id, student_identity_id, student_code, '
      'student_number, prefix, first_name, last_name, status, '
      'transferred_out_at, created_at, updated_at';

  /// Ensures a row exists in `public.student_identities` for `(teacherId, studentCode)`
  /// WITHOUT ever overwriting `pin_hash`, `failed_attempts`, or `locked_until`.
  Future<String> ensureStudentIdentityId({
    required String teacherId,
    required String studentCode,
  }) async {
    final code = studentCode.trim();
    try {
      final existing = await _client
          .from('student_identities')
          .select('id')
          .eq('teacher_id', teacherId)
          .eq('student_code', code)
          .maybeSingle();
      if (existing != null) {
        return existing['id'] as String;
      }

      await _client
          .from('student_identities')
          .upsert(
            <String, dynamic>{'teacher_id': teacherId, 'student_code': code},
            onConflict: 'teacher_id,student_code',
            ignoreDuplicates: true,
          );

      final created = await _client
          .from('student_identities')
          .select('id')
          .eq('teacher_id', teacherId)
          .eq('student_code', code)
          .single();
      return created['id'] as String;
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  /// Calls `public.sync_homeroom_student_update` RPC and returns updated row count.
  Future<int> syncHomeroomStudentUpdate({
    required String homeroomStudentId,
    required bool applyToAllClasses,
  }) async {
    try {
      final result = await _client.rpc<dynamic>(
        'sync_homeroom_student_update',
        params: <String, dynamic>{
          'p_homeroom_student_id': homeroomStudentId,
          'p_apply_to_all_classes': applyToAllClasses,
        },
      );
      return (result as num?)?.toInt() ?? 0;
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<List<HomeroomDto>> fetchHomerooms(String termId) async {
    try {
      final rows = await _client
          .from('homerooms')
          .select(_homeroomColumns)
          .eq('term_id', termId)
          .order('name', ascending: true);
      return rows.map(HomeroomDto.fromJson).toList(growable: false);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<HomeroomDto> createHomeroom({
    required String teacherId,
    required String termId,
    required String name,
  }) async {
    try {
      final data = await _client
          .from('homerooms')
          .insert(<String, dynamic>{
            'teacher_id': teacherId,
            'term_id': termId,
            'name': name.trim(),
          })
          .select(_homeroomColumns)
          .single();
      return HomeroomDto.fromJson(data);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<HomeroomDto> renameHomeroom({
    required String homeroomId,
    required String name,
  }) async {
    try {
      final data = await _client
          .from('homerooms')
          .update(<String, dynamic>{
            'name': name.trim(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', homeroomId)
          .select(_homeroomColumns)
          .single();
      return HomeroomDto.fromJson(data);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<void> deleteHomeroom(String homeroomId) async {
    try {
      await _client.from('homerooms').delete().eq('id', homeroomId);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<List<HomeroomStudentDto>> fetchHomeroomStudents(
    String homeroomId,
  ) async {
    try {
      final rows = await _client
          .from('homeroom_students')
          .select(_homeroomStudentColumns)
          .eq('homeroom_id', homeroomId)
          .order('student_number', ascending: true)
          .order('student_code', ascending: true);
      return rows.map(HomeroomStudentDto.fromJson).toList(growable: false);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<HomeroomStudentDto> addHomeroomStudent({
    required String teacherId,
    required String homeroomId,
    required String studentCode,
    required int studentNumber,
    required String prefix,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final identityId = await ensureStudentIdentityId(
        teacherId: teacherId,
        studentCode: studentCode,
      );
      final data = await _client
          .from('homeroom_students')
          .insert(<String, dynamic>{
            'teacher_id': teacherId,
            'homeroom_id': homeroomId,
            'student_identity_id': identityId,
            'student_code': studentCode.trim(),
            'student_number': studentNumber,
            'prefix': prefix.trim(),
            'first_name': firstName.trim(),
            'last_name': lastName.trim(),
          })
          .select(_homeroomStudentColumns)
          .single();
      return HomeroomStudentDto.fromJson(data);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<int> updateHomeroomStudent({
    required String homeroomStudentId,
    required String teacherId,
    required String studentCode,
    required int studentNumber,
    required String prefix,
    required String firstName,
    required String lastName,
    required bool syncLinkedClasses,
  }) async {
    try {
      final identityId = await ensureStudentIdentityId(
        teacherId: teacherId,
        studentCode: studentCode,
      );
      await _client
          .from('homeroom_students')
          .update(<String, dynamic>{
            'student_identity_id': identityId,
            'student_code': studentCode.trim(),
            'student_number': studentNumber,
            'prefix': prefix.trim(),
            'first_name': firstName.trim(),
            'last_name': lastName.trim(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', homeroomStudentId);

      if (!syncLinkedClasses) {
        return 0;
      }
      return syncHomeroomStudentUpdate(
        homeroomStudentId: homeroomStudentId,
        applyToAllClasses: true,
      );
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<int> setHomeroomStudentStatus({
    required String homeroomStudentId,
    required StudentLifecycleStatus status,
    DateTime? transferredOutAt,
    required bool syncLinkedClasses,
  }) async {
    try {
      final outDate = status == StudentLifecycleStatus.transferredOut
          ? ThaiDateFormatter.toIsoDate(transferredOutAt ?? DateTime.now())
          : null;
      await _client
          .from('homeroom_students')
          .update(<String, dynamic>{
            'status': status.dbValue,
            'transferred_out_at': outDate,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', homeroomStudentId);

      if (!syncLinkedClasses) {
        return 0;
      }
      return syncHomeroomStudentUpdate(
        homeroomStudentId: homeroomStudentId,
        applyToAllClasses: true,
      );
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<int> renumberHomeroomStudents({
    required List<RenumberAssignment> assignments,
    required bool syncLinkedClasses,
  }) async {
    try {
      var syncedTotal = 0;
      final nowIso = DateTime.now().toUtc().toIso8601String();
      for (final item in assignments) {
        await _client
            .from('homeroom_students')
            .update(<String, dynamic>{
              'student_number': item.newNumber,
              'updated_at': nowIso,
            })
            .eq('id', item.recordId);

        if (syncLinkedClasses) {
          syncedTotal += await syncHomeroomStudentUpdate(
            homeroomStudentId: item.recordId,
            applyToAllClasses: true,
          );
        }
      }
      return syncedTotal;
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  /// Bulk-imports validated preview rows into `public.homeroom_students`.
  ///
  /// Ensures `student_identities` without touching existing `pin_hash` values,
  /// inserts new rows, updates rows marked [DuplicateResolutionAction.overwrite],
  /// and optionally calls `sync_homeroom_student_update` for overwritten rows.
  Future<RosterImportResult> importHomeroomStudents({
    required String teacherId,
    required String homeroomId,
    required List<RosterImportRowPreview> rows,
    required bool syncOverwrittenToLinkedClasses,
  }) async {
    try {
      final newRows = rows
          .where((r) => r.status == RosterImportRowStatus.readyNew)
          .toList(growable: false);
      final overwriteRows = rows
          .where(
            (r) =>
                r.status == RosterImportRowStatus.duplicateExisting &&
                r.duplicateAction == DuplicateResolutionAction.overwrite &&
                r.existingStudent != null,
          )
          .toList(growable: false);
      final skippedCount = rows.length - newRows.length - overwriteRows.length;

      // 1. Batch-ensure student_identities without overwriting pin_hash.
      final neededCodes = newRows
          .map((r) => r.studentCode.trim())
          .where((c) => c.isNotEmpty)
          .toSet();
      final identityIdByCode = <String, String>{};
      if (neededCodes.isNotEmpty) {
        final upsertRows = neededCodes
            .map(
              (code) => <String, dynamic>{
                'teacher_id': teacherId,
                'student_code': code,
              },
            )
            .toList(growable: false);
        await _client
            .from('student_identities')
            .upsert(
              upsertRows,
              onConflict: 'teacher_id,student_code',
              ignoreDuplicates: true,
            );

        final fetched = await _client
            .from('student_identities')
            .select('id, student_code')
            .eq('teacher_id', teacherId)
            .inFilter('student_code', neededCodes.toList(growable: false));
        for (final row in fetched) {
          identityIdByCode[row['student_code'] as String] = row['id'] as String;
        }
      }

      // 2. Batch-insert new students into homeroom_students.
      if (newRows.isNotEmpty) {
        final insertPayload = <Map<String, dynamic>>[];
        for (final row in newRows) {
          final code = row.studentCode.trim();
          final identityId =
              identityIdByCode[code] ??
              await ensureStudentIdentityId(
                teacherId: teacherId,
                studentCode: code,
              );
          insertPayload.add(<String, dynamic>{
            'teacher_id': teacherId,
            'homeroom_id': homeroomId,
            'student_identity_id': identityId,
            'student_code': code,
            'student_number': row.studentNumber,
            'prefix': row.prefix.trim(),
            'first_name': row.firstName.trim(),
            'last_name': row.lastName.trim(),
            'status': StudentLifecycleStatus.active.dbValue,
          });
        }
        await _client.from('homeroom_students').insert(insertPayload);
      }

      // 3. Update existing rows explicitly marked as overwrite.
      var syncedEnrollmentsCount = 0;
      final nowIso = DateTime.now().toUtc().toIso8601String();
      for (final row in overwriteRows) {
        final existingId = row.existingStudent!.id;
        await _client
            .from('homeroom_students')
            .update(<String, dynamic>{
              'student_number': row.studentNumber,
              'prefix': row.prefix.trim(),
              'first_name': row.firstName.trim(),
              'last_name': row.lastName.trim(),
              'updated_at': nowIso,
            })
            .eq('id', existingId);

        if (syncOverwrittenToLinkedClasses) {
          syncedEnrollmentsCount += await syncHomeroomStudentUpdate(
            homeroomStudentId: existingId,
            applyToAllClasses: true,
          );
        }
      }

      return RosterImportResult(
        insertedCount: newRows.length,
        updatedCount: overwriteRows.length,
        skippedCount: skippedCount,
        syncedEnrollmentsCount: syncedEnrollmentsCount,
      );
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }
}

final homeroomRosterRemoteDataSourceProvider =
    Provider<HomeroomRosterRemoteDataSource>((ref) {
      final client = ref.watch(supabaseClientProvider);
      return HomeroomRosterRemoteDataSource(client);
    });
