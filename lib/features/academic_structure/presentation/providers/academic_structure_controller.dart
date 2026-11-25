import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../homeroom_roster/presentation/providers/homeroom_roster_providers.dart';
import '../../domain/entities/academic_year.dart';
import '../../domain/entities/delete_impact_summary.dart';
import '../../domain/entities/subject.dart';
import '../../domain/entities/subject_class.dart';
import '../../domain/entities/term.dart';
import 'academic_structure_providers.dart';

/// Controller handling all 4-level CRUD mutations and structural RPCs for
/// `features/academic_structure/`.
class AcademicStructureController extends AsyncNotifier<void> {
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

  Future<AcademicYear?> createAcademicYear(int yearBe) {
    return _run(() async {
      final teacherId = _requireTeacherId();
      final created = await ref
          .read(academicStructureRepositoryProvider)
          .createAcademicYear(teacherId: teacherId, yearBe: yearBe);
      ref.invalidate(academicYearsProvider);
      return created;
    });
  }

  Future<bool> deleteAcademicYear(String academicYearId) async {
    final ok = await _run(() async {
      await ref
          .read(academicStructureRepositoryProvider)
          .deleteAcademicYear(academicYearId);
      ref.invalidate(academicYearsProvider);
      ref.invalidate(allTermsProvider);
      return true;
    });
    return ok ?? false;
  }

  Future<Term?> createTerm({
    required String academicYearId,
    required String termLabel,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _run(() async {
      final teacherId = _requireTeacherId();
      final created = await ref
          .read(academicStructureRepositoryProvider)
          .createTerm(
            teacherId: teacherId,
            academicYearId: academicYearId,
            termLabel: termLabel,
            startDate: startDate,
            endDate: endDate,
          );
      ref.invalidate(allTermsProvider);
      ref.read(selectedTermIdProvider.notifier).select(created.id);
      return created;
    });
  }

  Future<Term?> updateTerm({
    required String termId,
    required String termLabel,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _run(() async {
      final updated = await ref
          .read(academicStructureRepositoryProvider)
          .updateTerm(
            termId: termId,
            termLabel: termLabel,
            startDate: startDate,
            endDate: endDate,
          );
      ref.invalidate(allTermsProvider);
      return updated;
    });
  }

  Future<bool> setPinnedActiveTerm(String? termId) async {
    final ok = await _run(() async {
      await ref
          .read(academicStructureRepositoryProvider)
          .setPinnedActiveTerm(termId);
      ref.invalidate(allTermsProvider);
      return true;
    });
    return ok ?? false;
  }

  Future<bool> deleteTerm(String termId) async {
    final ok = await _run(() async {
      await ref.read(academicStructureRepositoryProvider).deleteTerm(termId);
      if (ref.read(selectedTermIdProvider) == termId) {
        ref.read(selectedTermIdProvider.notifier).select(null);
      }
      ref.invalidate(allTermsProvider);
      ref.invalidate(subjectsByTermProvider(termId));
      ref.invalidate(subjectClassesByTermProvider(termId));
      return true;
    });
    return ok ?? false;
  }

  Future<Subject?> createSubject({
    required String termId,
    required String subjectCode,
    required String subjectName,
  }) {
    return _run(() async {
      final teacherId = _requireTeacherId();
      final created = await ref
          .read(academicStructureRepositoryProvider)
          .createSubject(
            teacherId: teacherId,
            termId: termId,
            subjectCode: subjectCode,
            subjectName: subjectName,
          );
      ref.invalidate(subjectsByTermProvider(termId));
      return created;
    });
  }

  Future<Subject?> updateSubject({
    required String termId,
    required String subjectId,
    required String subjectCode,
    required String subjectName,
  }) {
    return _run(() async {
      final updated = await ref
          .read(academicStructureRepositoryProvider)
          .updateSubject(
            subjectId: subjectId,
            subjectCode: subjectCode,
            subjectName: subjectName,
          );
      ref.invalidate(subjectsByTermProvider(termId));
      return updated;
    });
  }

  Future<bool> deleteSubject({
    required String termId,
    required String subjectId,
  }) async {
    final ok = await _run(() async {
      await ref
          .read(academicStructureRepositoryProvider)
          .deleteSubject(subjectId);
      ref.invalidate(subjectsByTermProvider(termId));
      ref.invalidate(subjectClassesByTermProvider(termId));
      return true;
    });
    return ok ?? false;
  }

  Future<SubjectClass?> createSubjectClass({
    required String termId,
    required String subjectId,
    required String roomName,
    required List<int> teachingDays,
    required bool isPinned,
    bool autoLinkHomeroom = true,
    DateTime? defaultEnrolledAt,
  }) {
    return _run(() async {
      final teacherId = _requireTeacherId();
      final profile = ref.read(authStateProvider).profile;
      final created = await ref
          .read(academicStructureRepositoryProvider)
          .createSubjectClass(
            teacherId: teacherId,
            subjectId: subjectId,
            termId: termId,
            roomName: roomName,
            autoLinkHomeroom: autoLinkHomeroom,
            defaultEnrolledAt: defaultEnrolledAt,
            teachingDays: teachingDays,
            isPinned: isPinned,
            absentThresholdPct: profile?.defaultAbsentThresholdPct,
            missingWorkThreshold: profile?.defaultMissingWorkThreshold,
          );
      ref.invalidate(subjectClassesByTermProvider(termId));
      if (autoLinkHomeroom) {
        ref.invalidate(homeroomsByTermProvider(termId));
        ref.invalidate(classEnrollmentsProvider(created.id));
      }
      return created;
    });
  }

  Future<SubjectClass?> updateSubjectClass({
    required String termId,
    required SubjectClass existing,
    required String roomName,
    required List<int> teachingDays,
    required bool isPinned,
  }) {
    return _run(() async {
      final updated = await ref
          .read(academicStructureRepositoryProvider)
          .updateSubjectClass(
            _copySubjectClass(
              existing,
              roomName: roomName,
              teachingDays: teachingDays,
              isPinned: isPinned,
            ),
          );
      ref.invalidate(subjectClassesByTermProvider(termId));
      return updated;
    });
  }

  Future<bool> togglePinSubjectClass({
    required String termId,
    required SubjectClass subjectClass,
  }) async {
    final updated = await updateSubjectClass(
      termId: termId,
      existing: subjectClass,
      roomName: subjectClass.roomName,
      teachingDays: subjectClass.teachingDays,
      isPinned: !subjectClass.isPinned,
    );
    return updated != null;
  }

  Future<bool> deleteSubjectClass({
    required String termId,
    required String subjectClassId,
  }) async {
    final ok = await _run(() async {
      await ref
          .read(academicStructureRepositoryProvider)
          .deleteSubjectClass(subjectClassId);
      ref.invalidate(subjectClassesByTermProvider(termId));
      return true;
    });
    return ok ?? false;
  }

  Future<DeleteImpactSummary> fetchDeleteImpactSummary({
    required StructuralEntityType entityType,
    required String entityId,
  }) {
    return ref
        .read(academicStructureRepositoryProvider)
        .getDeleteImpactSummary(entityType: entityType, entityId: entityId);
  }

  SubjectClass _copySubjectClass(
    SubjectClass source, {
    required String roomName,
    required List<int> teachingDays,
    required bool isPinned,
  }) {
    return SubjectClass(
      id: source.id,
      teacherId: source.teacherId,
      subjectId: source.subjectId,
      homeroomId: source.homeroomId,
      roomName: roomName,
      teachingDays: teachingDays,
      isPinned: isPinned,
      showScoreToStudent: source.showScoreToStudent,
      showGradeToStudent: source.showGradeToStudent,
      absentThresholdPct: source.absentThresholdPct,
      missingWorkThreshold: source.missingWorkThreshold,
      lateToAbsentRatio: source.lateToAbsentRatio,
      countLeaveAsAbsent: source.countLeaveAsAbsent,
      attendanceScoreWeight: source.attendanceScoreWeight,
      gradingScaleType: source.gradingScaleType,
      gradingRules: source.gradingRules,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt,
    );
  }
}

final academicStructureControllerProvider =
    AsyncNotifierProvider<AcademicStructureController, void>(
      AcademicStructureController.new,
    );
