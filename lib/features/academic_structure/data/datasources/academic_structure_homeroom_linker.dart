import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/thai_date_formatter.dart';

/// Helper datasource responsible for ensuring a term-level `public.homerooms`
/// record exists for a room name and copying its active students into a newly
/// created `public.subject_classes` row without touching `pin_hash`.
abstract final class AcademicStructureHomeroomLinker {
  /// Finds an existing homeroom `(teacher_id, term_id, name)` or inserts one.
  static Future<String> ensureHomeroomId({
    required SupabaseClient client,
    required String teacherId,
    required String termId,
    required String roomName,
  }) async {
    final trimmedName = roomName.trim();
    final existing = await client
        .from('homerooms')
        .select('id')
        .eq('teacher_id', teacherId)
        .eq('term_id', termId)
        .eq('name', trimmedName)
        .maybeSingle();
    if (existing != null) {
      return existing['id'] as String;
    }

    try {
      final created = await client
          .from('homerooms')
          .insert(<String, dynamic>{
            'teacher_id': teacherId,
            'term_id': termId,
            'name': trimmedName,
          })
          .select('id')
          .single();
      return created['id'] as String;
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        final concurrent = await client
            .from('homerooms')
            .select('id')
            .eq('teacher_id', teacherId)
            .eq('term_id', termId)
            .eq('name', trimmedName)
            .single();
        return concurrent['id'] as String;
      }
      rethrow;
    }
  }

  /// Copies all `active` students from `homeroom_students` into
  /// `class_enrollments` for [subjectClassId], skipping any `student_code`
  /// already enrolled.
  static Future<int> copyActiveHomeroomStudentsToClass({
    required SupabaseClient client,
    required String teacherId,
    required String homeroomId,
    required String subjectClassId,
    required DateTime enrolledAt,
  }) async {
    final activeStudents = await client
        .from('homeroom_students')
        .select(
          'id, student_identity_id, student_code, student_number, '
          'prefix, first_name, last_name',
        )
        .eq('teacher_id', teacherId)
        .eq('homeroom_id', homeroomId)
        .eq('status', 'active')
        .order('student_number', ascending: true);

    if (activeStudents.isEmpty) {
      return 0;
    }

    final existingRows = await client
        .from('class_enrollments')
        .select('student_code')
        .eq('subject_class_id', subjectClassId);
    final existingCodes = existingRows
        .map((row) => row['student_code'] as String)
        .toSet();

    final enrolledIso = ThaiDateFormatter.toIsoDate(enrolledAt);
    final payload = <Map<String, dynamic>>[];
    for (final student in activeStudents) {
      final code = student['student_code'] as String;
      if (existingCodes.contains(code)) continue;
      payload.add(<String, dynamic>{
        'teacher_id': teacherId,
        'subject_class_id': subjectClassId,
        'homeroom_student_id': student['id'] as String,
        'student_identity_id': student['student_identity_id'] as String,
        'student_code': code,
        'student_number': (student['student_number'] as num).toInt(),
        'prefix': student['prefix'] as String? ?? '',
        'first_name': student['first_name'] as String,
        'last_name': student['last_name'] as String,
        'status': 'active',
        'enrolled_at': enrolledIso,
        'version': 1,
      });
    }

    if (payload.isEmpty) {
      return 0;
    }

    await client.from('class_enrollments').insert(payload);
    return payload.length;
  }
}
