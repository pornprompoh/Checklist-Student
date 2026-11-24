import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../academic_structure/presentation/providers/academic_structure_providers.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/entities/class_enrollment.dart';
import '../../domain/entities/homeroom.dart';
import '../../domain/entities/homeroom_student.dart';
import '../../domain/entities/student_lifecycle_status.dart';
import '../../domain/services/roster_renumber_service.dart';
import 'homeroom_roster_providers.dart';

/// Controller orchestrating all homeroom master roster and class enrollment
/// mutations, cross-class sync, soft deletes, and renumbering.
class HomeroomRosterController extends AsyncNotifier<void> {
  @override
  void build() {}

  String _requireTeacherId() {
    final userId = ref.read(authStateProvider).userId;
    if (userId == null) {
      throw const AuthException('เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่อีกครั้ง');
    }
    return userId;
  }

  Future<T?> _run<T>(Future<T> Function() action) async {
    state = const AsyncLoading<void>();
    try {
      final result = await action();
      if (ref.mounted) {
        state = const AsyncData<void>(null);
      }
      return result;
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError<void>(
          ThaiErrorMapper.toAppException(error),
          stackTrace,
        );
      }
      return null;
    }
  }

  Future<Homeroom?> createHomeroom({
    required String termId,
    required String name,
  }) {
    return _run(() async {
      final teacherId = _requireTeacherId();
      final created = await ref
          .read(homeroomRosterRepositoryProvider)
          .createHomeroom(teacherId: teacherId, termId: termId, name: name);
      ref.invalidate(homeroomsByTermProvider(termId));
      ref.read(selectedHomeroomIdProvider.notifier).select(created.id);
      return created;
    });
  }

  Future<Homeroom?> renameHomeroom({
    required String termId,
    required String homeroomId,
    required String name,
  }) {
    return _run(() async {
      final updated = await ref
          .read(homeroomRosterRepositoryProvider)
          .renameHomeroom(homeroomId: homeroomId, name: name);
      ref.invalidate(homeroomsByTermProvider(termId));
      return updated;
    });
  }

  Future<bool> deleteHomeroom({
    required String termId,
    required String homeroomId,
  }) async {
    final ok = await _run(() async {
      await ref
          .read(homeroomRosterRepositoryProvider)
          .deleteHomeroom(homeroomId);
      if (ref.read(selectedHomeroomIdProvider) == homeroomId) {
        ref.read(selectedHomeroomIdProvider.notifier).select(null);
      }
      ref.invalidate(homeroomsByTermProvider(termId));
      ref.invalidate(subjectClassesByTermProvider(termId));
      return true;
    });
    return ok ?? false;
  }

  Future<HomeroomStudent?> addHomeroomStudent({
    required String homeroomId,
    required String studentCode,
    required int studentNumber,
    required String prefix,
    required String firstName,
    required String lastName,
  }) {
    return _run(() async {
      final teacherId = _requireTeacherId();
      final created = await ref
          .read(homeroomRosterRepositoryProvider)
          .addHomeroomStudent(
            teacherId: teacherId,
            homeroomId: homeroomId,
            studentCode: studentCode,
            studentNumber: studentNumber,
            prefix: prefix,
            firstName: firstName,
            lastName: lastName,
          );
      ref.invalidate(homeroomStudentsProvider(homeroomId));
      return created;
    });
  }

  Future<int?> updateHomeroomStudent({
    required String homeroomId,
    required String homeroomStudentId,
    required String studentCode,
    required int studentNumber,
    required String prefix,
    required String firstName,
    required String lastName,
    required bool syncLinkedClasses,
    List<String> linkedClassIds = const <String>[],
  }) {
    return _run(() async {
      final teacherId = _requireTeacherId();
      final synced = await ref
          .read(homeroomRosterRepositoryProvider)
          .updateHomeroomStudent(
            homeroomStudentId: homeroomStudentId,
            teacherId: teacherId,
            studentCode: studentCode,
            studentNumber: studentNumber,
            prefix: prefix,
            firstName: firstName,
            lastName: lastName,
            syncLinkedClasses: syncLinkedClasses,
          );
      ref.invalidate(homeroomStudentsProvider(homeroomId));
      for (final classId in linkedClassIds) {
        ref.invalidate(classEnrollmentsProvider(classId));
      }
      return synced;
    });
  }

  Future<int?> setHomeroomStudentStatus({
    required String homeroomId,
    required String homeroomStudentId,
    required StudentLifecycleStatus status,
    DateTime? transferredOutAt,
    required bool syncLinkedClasses,
    List<String> linkedClassIds = const <String>[],
  }) {
    return _run(() async {
      final synced = await ref
          .read(homeroomRosterRepositoryProvider)
          .setHomeroomStudentStatus(
            homeroomStudentId: homeroomStudentId,
            status: status,
            transferredOutAt: transferredOutAt,
            syncLinkedClasses: syncLinkedClasses,
          );
      ref.invalidate(homeroomStudentsProvider(homeroomId));
      for (final classId in linkedClassIds) {
        ref.invalidate(classEnrollmentsProvider(classId));
      }
      return synced;
    });
  }

  Future<int?> renumberHomeroomStudents({
    required String homeroomId,
    required List<RenumberAssignment> assignments,
    required bool syncLinkedClasses,
    List<String> linkedClassIds = const <String>[],
  }) {
    return _run(() async {
      final synced = await ref
          .read(homeroomRosterRepositoryProvider)
          .renumberHomeroomStudents(
            assignments: assignments,
            syncLinkedClasses: syncLinkedClasses,
          );
      ref.invalidate(homeroomStudentsProvider(homeroomId));
      for (final classId in linkedClassIds) {
        ref.invalidate(classEnrollmentsProvider(classId));
      }
      return synced;
    });
  }

  Future<int?> linkHomeroomToSubjectClasses({
    required String termId,
    required String homeroomId,
    required List<String> subjectClassIds,
    required DateTime enrolledAt,
  }) {
    return _run(() async {
      final teacherId = _requireTeacherId();
      final inserted = await ref
          .read(homeroomRosterRepositoryProvider)
          .linkHomeroomToSubjectClasses(
            teacherId: teacherId,
            homeroomId: homeroomId,
            subjectClassIds: subjectClassIds,
            enrolledAt: enrolledAt,
          );
      ref.invalidate(subjectClassesByTermProvider(termId));
      for (final classId in subjectClassIds) {
        ref.invalidate(classEnrollmentsProvider(classId));
      }
      return inserted;
    });
  }

  Future<ClassEnrollment?> addClassEnrollmentMidTerm({
    required String subjectClassId,
    String? addToHomeroomId,
    required String studentCode,
    required int studentNumber,
    required String prefix,
    required String firstName,
    required String lastName,
    required DateTime enrolledAt,
  }) {
    return _run(() async {
      final teacherId = _requireTeacherId();
      final created = await ref
          .read(homeroomRosterRepositoryProvider)
          .addClassEnrollmentMidTerm(
            teacherId: teacherId,
            subjectClassId: subjectClassId,
            addToHomeroomId: addToHomeroomId,
            studentCode: studentCode,
            studentNumber: studentNumber,
            prefix: prefix,
            firstName: firstName,
            lastName: lastName,
            enrolledAt: enrolledAt,
          );
      ref.invalidate(classEnrollmentsProvider(subjectClassId));
      if (addToHomeroomId != null) {
        ref.invalidate(homeroomStudentsProvider(addToHomeroomId));
      }
      return created;
    });
  }

  Future<int?> updateClassEnrollment({
    required ClassEnrollment existing,
    required String studentCode,
    required int studentNumber,
    required String prefix,
    required String firstName,
    required String lastName,
    required DateTime enrolledAt,
    required bool syncToHomeroomAndAllClasses,
    String? linkedHomeroomId,
    List<String> siblingClassIds = const <String>[],
  }) {
    return _run(() async {
      final synced = await ref
          .read(homeroomRosterRepositoryProvider)
          .updateClassEnrollment(
            existing: existing,
            studentCode: studentCode,
            studentNumber: studentNumber,
            prefix: prefix,
            firstName: firstName,
            lastName: lastName,
            enrolledAt: enrolledAt,
            syncToHomeroomAndAllClasses: syncToHomeroomAndAllClasses,
          );
      ref.invalidate(classEnrollmentsProvider(existing.subjectClassId));
      if (syncToHomeroomAndAllClasses) {
        if (linkedHomeroomId != null) {
          ref.invalidate(homeroomStudentsProvider(linkedHomeroomId));
        }
        for (final classId in siblingClassIds) {
          ref.invalidate(classEnrollmentsProvider(classId));
        }
      }
      return synced;
    });
  }

  Future<int?> setClassEnrollmentStatus({
    required ClassEnrollment existing,
    required StudentLifecycleStatus status,
    DateTime? transferredOutAt,
    required bool syncToHomeroomAndAllClasses,
    String? linkedHomeroomId,
    List<String> siblingClassIds = const <String>[],
  }) {
    return _run(() async {
      final synced = await ref
          .read(homeroomRosterRepositoryProvider)
          .setClassEnrollmentStatus(
            existing: existing,
            status: status,
            transferredOutAt: transferredOutAt,
            syncToHomeroomAndAllClasses: syncToHomeroomAndAllClasses,
          );
      ref.invalidate(classEnrollmentsProvider(existing.subjectClassId));
      if (syncToHomeroomAndAllClasses) {
        if (linkedHomeroomId != null) {
          ref.invalidate(homeroomStudentsProvider(linkedHomeroomId));
        }
        for (final classId in siblingClassIds) {
          ref.invalidate(classEnrollmentsProvider(classId));
        }
      }
      return synced;
    });
  }

  Future<bool> renumberClassEnrollments({
    required String subjectClassId,
    required List<ClassEnrollment> currentEnrollments,
    required List<RenumberAssignment> assignments,
  }) async {
    final ok = await _run(() async {
      await ref
          .read(homeroomRosterRepositoryProvider)
          .renumberClassEnrollments(
            currentEnrollments: currentEnrollments,
            assignments: assignments,
          );
      ref.invalidate(classEnrollmentsProvider(subjectClassId));
      return true;
    });
    return ok ?? false;
  }
}

final homeroomRosterControllerProvider =
    AsyncNotifierProvider<HomeroomRosterController, void>(
      HomeroomRosterController.new,
    );
