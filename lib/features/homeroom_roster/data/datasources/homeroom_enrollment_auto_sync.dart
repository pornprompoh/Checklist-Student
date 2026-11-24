import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/entities/student_lifecycle_status.dart';
import '../models/homeroom_dto.dart';
import '../models/homeroom_student_dto.dart';

/// Result counts returned after auto-enrolling newly added homeroom students
/// into all `subject_classes` linked to that homeroom in the same term.
class AutoEnrollSyncSummary {
  const AutoEnrollSyncSummary({
    required this.linkedClassCount,
    required this.insertedEnrollmentsCount,
  });

  final int linkedClassCount;
  final int insertedEnrollmentsCount;
}

/// Focused datasource helper for:
/// 1) Auto-enrolling newly inserted `homeroom_students` into all linked
///    `subject_classes` without duplicating rows or touching `pin_hash`.
/// 2) Ensuring a `homerooms` row exists by `(term_id, name)` when syncing
///    previously unlinked `subject_classes`.
abstract final class HomeroomEnrollmentAutoSync {
  static const String _homeroomColumns =
      'id, teacher_id, term_id, name, created_at, updated_at';

  static Future<HomeroomDto> ensureHomeroom({
    required SupabaseClient client,
    required String teacherId,
    required String termId,
    required String name,
  }) async {
    final trimmed = name.trim();
    final existing = await client
        .from('homerooms')
        .select(_homeroomColumns)
        .eq('teacher_id', teacherId)
        .eq('term_id', termId)
        .eq('name', trimmed)
        .maybeSingle();
    if (existing != null) {
      return HomeroomDto.fromJson(existing);
    }

    try {
      final created = await client
          .from('homerooms')
          .insert(<String, dynamic>{
            'teacher_id': teacherId,
            'term_id': termId,
            'name': trimmed,
          })
          .select(_homeroomColumns)
          .single();
      return HomeroomDto.fromJson(created);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        final concurrent = await client
            .from('homerooms')
            .select(_homeroomColumns)
            .eq('teacher_id', teacherId)
            .eq('term_id', termId)
            .eq('name', trimmed)
            .single();
        return HomeroomDto.fromJson(concurrent);
      }
      rethrow;
    }
  }

  /// Enrolls newly added active [students] into every `subject_classes` row
  /// whose `homeroom_id == homeroomId`, skipping existing `student_code`s.
  static Future<AutoEnrollSyncSummary> enrollNewStudentsToLinkedClasses({
    required SupabaseClient client,
    required String teacherId,
    required String homeroomId,
    required List<HomeroomStudentDto> students,
    required DateTime enrolledAt,
  }) async {
    final activeStudents = students
        .where((s) => s.status == StudentLifecycleStatus.active)
        .toList(growable: false);
    if (activeStudents.isEmpty) {
      return const AutoEnrollSyncSummary(
        linkedClassCount: 0,
        insertedEnrollmentsCount: 0,
      );
    }

    final linkedClasses = await client
        .from('subject_classes')
        .select('id')
        .eq('teacher_id', teacherId)
        .eq('homeroom_id', homeroomId);
    if (linkedClasses.isEmpty) {
      return const AutoEnrollSyncSummary(
        linkedClassCount: 0,
        insertedEnrollmentsCount: 0,
      );
    }

    final enrolledIso = ThaiDateFormatter.toIsoDate(enrolledAt);
    var insertedTotal = 0;

    for (final cls in linkedClasses) {
      final classId = cls['id'] as String;
      final existingRows = await client
          .from('class_enrollments')
          .select('student_code')
          .eq('subject_class_id', classId);
      final existingCodes = existingRows
          .map((row) => row['student_code'] as String)
          .toSet();

      final payload = <Map<String, dynamic>>[];
      for (final student in activeStudents) {
        if (existingCodes.contains(student.studentCode)) continue;
        payload.add(<String, dynamic>{
          'teacher_id': teacherId,
          'subject_class_id': classId,
          'homeroom_student_id': student.id,
          'student_identity_id': student.studentIdentityId,
          'student_code': student.studentCode,
          'student_number': student.studentNumber,
          'prefix': student.prefix,
          'first_name': student.firstName,
          'last_name': student.lastName,
          'status': StudentLifecycleStatus.active.dbValue,
          'enrolled_at': enrolledIso,
          'version': 1,
        });
      }

      if (payload.isNotEmpty) {
        await client.from('class_enrollments').insert(payload);
        insertedTotal += payload.length;
      }
    }

    return AutoEnrollSyncSummary(
      linkedClassCount: linkedClasses.length,
      insertedEnrollmentsCount: insertedTotal,
    );
  }
}
