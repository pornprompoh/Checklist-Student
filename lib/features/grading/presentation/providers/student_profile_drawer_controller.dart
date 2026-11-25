import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../homeroom_roster/domain/entities/class_enrollment.dart';
import '../../../homeroom_roster/domain/entities/student_lifecycle_status.dart';
import '../../../homeroom_roster/presentation/providers/homeroom_roster_providers.dart';
import '../../domain/entities/student_pin_status.dart';
import 'grading_providers.dart';

/// Loads safe Portal PIN status metadata (without raw `pin_hash`) for
/// [studentIdentityId].
final studentPinStatusProvider = FutureProvider.autoDispose
    .family<StudentPinStatus, String>((ref, studentIdentityId) async {
      return ref
          .watch(gradingRepositoryProvider)
          .fetchStudentPinStatus(studentIdentityId);
    });

/// Controller for actions inside `StudentProfileDrawer` and
/// `SpecialGradeActionDialog`: special grade updates (with Optimistic Locking),
/// student PIN reset, and Soft Delete transfer status updates.
class StudentProfileDrawerController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<bool> updateSpecialGrade({
    required String subjectClassId,
    required String enrollmentId,
    required int expectedVersion,
    required String? specialGradeOverride,
    required bool markRResolved,
    required bool markMsResolved,
  }) async {
    return _run(() async {
      await ref
          .read(gradingRepositoryProvider)
          .updateSpecialGradeStatus(
            enrollmentId: enrollmentId,
            expectedVersion: expectedVersion,
            specialGradeOverride: specialGradeOverride,
            markRResolved: markRResolved,
            markMsResolved: markMsResolved,
          );
      ref.invalidate(classEnrollmentsProvider(subjectClassId));
    });
  }

  Future<bool> resetStudentPin(String studentIdentityId) async {
    return _run(() async {
      await ref
          .read(gradingRepositoryProvider)
          .resetStudentPin(studentIdentityId);
      ref.invalidate(studentPinStatusProvider(studentIdentityId));
    });
  }

  Future<bool> updateTransferStatus({
    required ClassEnrollment enrollment,
    required StudentLifecycleStatus nextStatus,
    required bool syncToHomeroomAndAllClasses,
  }) async {
    return _run(() async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await ref
          .read(homeroomRosterRepositoryProvider)
          .setClassEnrollmentStatus(
            existing: enrollment,
            status: nextStatus,
            transferredOutAt: nextStatus == StudentLifecycleStatus.transferredOut
                ? today
                : null,
            syncToHomeroomAndAllClasses: syncToHomeroomAndAllClasses,
          );
      ref
        ..invalidate(classEnrollmentsProvider(enrollment.subjectClassId))
        ..invalidate(homeroomStudentsProvider)
        ..invalidate(dashboardOverviewProvider);
    });
  }

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading<void>();
    try {
      await action();
      state = const AsyncData<void>(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      return false;
    }
  }
}

final studentProfileDrawerControllerProvider =
    NotifierProvider<StudentProfileDrawerController, AsyncValue<void>>(
      StudentProfileDrawerController.new,
    );
