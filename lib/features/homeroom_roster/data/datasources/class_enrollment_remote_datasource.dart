import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/class_enrollment.dart';
import '../../domain/entities/student_lifecycle_status.dart';
import '../../domain/services/roster_renumber_service.dart';
import '../../domain/services/unlinked_room_sync_service.dart';
import '../models/class_enrollment_dto.dart';
import '../models/homeroom_dto.dart';
import 'homeroom_enrollment_auto_sync.dart';
import 'homeroom_roster_remote_datasource.dart';

/// Remote data source managing `public.class_enrollments` and homeroom-to-class
/// linking while strictly preserving Optimistic Locking (`version + 1`).
class ClassEnrollmentRemoteDataSource {
  const ClassEnrollmentRemoteDataSource(this._client, this._homeroomRemote);

  final SupabaseClient _client;
  final HomeroomRosterRemoteDataSource _homeroomRemote;

  static const String _enrollmentColumns =
      'id, teacher_id, subject_class_id, homeroom_student_id, '
      'student_identity_id, student_code, student_number, prefix, '
      'first_name, last_name, status, enrolled_at, transferred_out_at, '
      'special_grade_override, was_r_resolved, was_ms_resolved, '
      'resolved_grade_at, version, created_at, updated_at';

  /// Ensures `public.homerooms` exists for each [UnlinkedRoomGroup], links all
  /// matching `subject_classes.homeroom_id` rows, and copies active students.
  Future<HomeroomDto?> syncUnlinkedRoomGroups({
    required String teacherId,
    required String termId,
    required List<UnlinkedRoomGroup> groups,
    required DateTime enrolledAt,
  }) async {
    try {
      HomeroomDto? firstSynced;
      for (final group in groups) {
        final homeroomDto = await HomeroomEnrollmentAutoSync.ensureHomeroom(
          client: _client,
          teacherId: teacherId,
          termId: termId,
          name: group.roomName,
        );
        firstSynced ??= homeroomDto;

        await linkHomeroomToSubjectClasses(
          teacherId: teacherId,
          homeroomId: homeroomDto.id,
          subjectClassIds: group.subjectClassIds,
          enrolledAt: enrolledAt,
        );
      }
      return firstSynced;
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<int> linkHomeroomToSubjectClasses({
    required String teacherId,
    required String homeroomId,
    required List<String> subjectClassIds,
    required DateTime enrolledAt,
  }) async {
    try {
      final homeroomStudents = await _homeroomRemote.fetchHomeroomStudents(
        homeroomId,
      );
      final enrolledIso = ThaiDateFormatter.toIsoDate(enrolledAt);
      final nowIso = DateTime.now().toUtc().toIso8601String();
      var insertedTotal = 0;

      for (final classId in subjectClassIds) {
        await _client
            .from('subject_classes')
            .update(<String, dynamic>{
              'homeroom_id': homeroomId,
              'updated_at': nowIso,
            })
            .eq('id', classId);

        final existingRows = await _client
            .from('class_enrollments')
            .select('student_code')
            .eq('subject_class_id', classId);
        final existingCodes = existingRows
            .map((row) => row['student_code'] as String)
            .toSet();

        final payload = <Map<String, dynamic>>[];
        for (final hs in homeroomStudents) {
          if (existingCodes.contains(hs.studentCode)) continue;
          payload.add(<String, dynamic>{
            'teacher_id': teacherId,
            'subject_class_id': classId,
            'homeroom_student_id': hs.id,
            'student_identity_id': hs.studentIdentityId,
            'student_code': hs.studentCode,
            'student_number': hs.studentNumber,
            'prefix': hs.prefix,
            'first_name': hs.firstName,
            'last_name': hs.lastName,
            'status': hs.status.dbValue,
            'enrolled_at': enrolledIso,
            'transferred_out_at': hs.transferredOutAt == null
                ? null
                : ThaiDateFormatter.toIsoDate(hs.transferredOutAt!),
            'version': 1,
          });
        }

        if (payload.isNotEmpty) {
          await _client.from('class_enrollments').insert(payload);
          insertedTotal += payload.length;
        }
      }
      return insertedTotal;
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<List<ClassEnrollmentDto>> fetchClassEnrollments(
    String subjectClassId,
  ) async {
    try {
      final rows = await _client
          .from('class_enrollments')
          .select(_enrollmentColumns)
          .eq('subject_class_id', subjectClassId)
          .order('student_number', ascending: true)
          .order('student_code', ascending: true);
      return rows.map(ClassEnrollmentDto.fromJson).toList(growable: false);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<ClassEnrollmentDto> addClassEnrollmentMidTerm({
    required String teacherId,
    required String subjectClassId,
    String? addToHomeroomId,
    required String studentCode,
    required int studentNumber,
    required String prefix,
    required String firstName,
    required String lastName,
    required DateTime enrolledAt,
  }) async {
    try {
      final identityId = await _homeroomRemote.ensureStudentIdentityId(
        teacherId: teacherId,
        studentCode: studentCode,
      );
      String? homeroomStudentId;
      if (addToHomeroomId != null) {
        final hs = await _homeroomRemote.addHomeroomStudent(
          teacherId: teacherId,
          homeroomId: addToHomeroomId,
          studentCode: studentCode,
          studentNumber: studentNumber,
          prefix: prefix,
          firstName: firstName,
          lastName: lastName,
        );
        homeroomStudentId = hs.id;
      }

      final data = await _client
          .from('class_enrollments')
          .insert(<String, dynamic>{
            'teacher_id': teacherId,
            'subject_class_id': subjectClassId,
            'homeroom_student_id': homeroomStudentId,
            'student_identity_id': identityId,
            'student_code': studentCode.trim(),
            'student_number': studentNumber,
            'prefix': prefix.trim(),
            'first_name': firstName.trim(),
            'last_name': lastName.trim(),
            'enrolled_at': ThaiDateFormatter.toIsoDate(enrolledAt),
            'version': 1,
          })
          .select(_enrollmentColumns)
          .single();
      return ClassEnrollmentDto.fromJson(data);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<int> updateClassEnrollment({
    required ClassEnrollment existing,
    required String studentCode,
    required int studentNumber,
    required String prefix,
    required String firstName,
    required String lastName,
    required DateTime enrolledAt,
    required bool syncToHomeroomAndAllClasses,
  }) async {
    try {
      final enrolledIso = ThaiDateFormatter.toIsoDate(enrolledAt);
      if (syncToHomeroomAndAllClasses && existing.homeroomStudentId != null) {
        final synced = await _homeroomRemote.updateHomeroomStudent(
          homeroomStudentId: existing.homeroomStudentId!,
          teacherId: existing.teacherId,
          studentCode: studentCode,
          studentNumber: studentNumber,
          prefix: prefix,
          firstName: firstName,
          lastName: lastName,
          syncLinkedClasses: true,
        );
        if (ThaiDateFormatter.toIsoDate(existing.enrolledAt) != enrolledIso) {
          await _client
              .from('class_enrollments')
              .update(<String, dynamic>{
                'enrolled_at': enrolledIso,
                'version': existing.version + 2,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('id', existing.id);
        }
        return synced;
      }

      final identityId = await _homeroomRemote.ensureStudentIdentityId(
        teacherId: existing.teacherId,
        studentCode: studentCode,
      );
      await _client
          .from('class_enrollments')
          .update(<String, dynamic>{
            'student_identity_id': identityId,
            'student_code': studentCode.trim(),
            'student_number': studentNumber,
            'prefix': prefix.trim(),
            'first_name': firstName.trim(),
            'last_name': lastName.trim(),
            'enrolled_at': enrolledIso,
            'version': existing.version + 1,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', existing.id);
      return 1;
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<int> setClassEnrollmentStatus({
    required ClassEnrollment existing,
    required StudentLifecycleStatus status,
    DateTime? transferredOutAt,
    required bool syncToHomeroomAndAllClasses,
  }) async {
    try {
      if (syncToHomeroomAndAllClasses && existing.homeroomStudentId != null) {
        return _homeroomRemote.setHomeroomStudentStatus(
          homeroomStudentId: existing.homeroomStudentId!,
          status: status,
          transferredOutAt: transferredOutAt,
          syncLinkedClasses: true,
        );
      }

      final outDate = status == StudentLifecycleStatus.transferredOut
          ? ThaiDateFormatter.toIsoDate(transferredOutAt ?? DateTime.now())
          : null;
      await _client
          .from('class_enrollments')
          .update(<String, dynamic>{
            'status': status.dbValue,
            'transferred_out_at': outDate,
            'version': existing.version + 1,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', existing.id);
      return 1;
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  /// Permanently removes a `class_enrollments` row (cascading attendance,
  /// scores, and audit logs), optionally removing the linked homeroom master
  /// student and all sibling enrollments in the same term. Never touches
  /// `public.student_identities`.
  Future<void> permanentlyDeleteClassEnrollment({
    required String enrollmentId,
    String? homeroomStudentId,
    required bool alsoDeleteFromHomeroom,
  }) async {
    try {
      if (alsoDeleteFromHomeroom && homeroomStudentId != null) {
        await _homeroomRemote.permanentlyDeleteHomeroomStudent(
          homeroomStudentId: homeroomStudentId,
          deleteFromLinkedClasses: true,
        );
      }
      await _client.from('class_enrollments').delete().eq('id', enrollmentId);
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }

  Future<void> renumberClassEnrollments({
    required List<ClassEnrollment> currentEnrollments,
    required List<RenumberAssignment> assignments,
  }) async {
    try {
      final byId = <String, ClassEnrollment>{
        for (final e in currentEnrollments) e.id: e,
      };
      final nowIso = DateTime.now().toUtc().toIso8601String();
      for (final item in assignments) {
        final existing = byId[item.recordId];
        if (existing == null) continue;
        await _client
            .from('class_enrollments')
            .update(<String, dynamic>{
              'student_number': item.newNumber,
              'version': existing.version + 1,
              'updated_at': nowIso,
            })
            .eq('id', item.recordId);
      }
    } catch (error) {
      throw ThaiErrorMapper.toAppException(error);
    }
  }
}

final classEnrollmentRemoteDataSourceProvider =
    Provider<ClassEnrollmentRemoteDataSource>((ref) {
      final client = ref.watch(supabaseClientProvider);
      final homeroomRemote = ref.watch(homeroomRosterRemoteDataSourceProvider);
      return ClassEnrollmentRemoteDataSource(client, homeroomRemote);
    });
