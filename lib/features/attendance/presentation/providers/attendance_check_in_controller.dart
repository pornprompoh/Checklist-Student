import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/attendance_status.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/thai_error_mapper.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_record_input.dart';
import 'attendance_check_in_state.dart';
import 'attendance_providers.dart';

/// Controller orchestrating daily attendance check-in drafts, session locking,
/// Optimistic Locking conflict handling, and Dashboard cache invalidation.
class AttendanceCheckInController extends Notifier<AttendanceCheckInState> {
  AttendanceCheckInController(this.subjectClassId);

  final String subjectClassId;

  @override
  AttendanceCheckInState build() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    unawaited(Future<void>.microtask(() => loadDate(today)));
    return AttendanceCheckInState(
      subjectClassId: subjectClassId,
      selectedDate: today,
      isLoading: true,
    );
  }

  Future<void> loadDate(DateTime rawDate) async {
    final date = DateTime(rawDate.year, rawDate.month, rawDate.day);
    state = state.copyWith(
      selectedDate: date,
      isLoading: true,
      isDirty: false,
      isConflictError: false,
      clearError: true,
    );

    try {
      final repo = ref.read(attendanceRepositoryProvider);
      final session = await repo.fetchSessionByDate(
        subjectClassId: subjectClassId,
        sessionDate: date,
      );

      if (!ref.mounted) return;
      if (session == null) {
        state = state.copyWith(
          selectedDate: date,
          clearSession: true,
          existingRecordsByEnrollment: const <String, AttendanceRecord>{},
          draftStatuses: const <String, AttendanceStatus>{},
          draftNotes: const <String, String>{},
          sessionNote: '',
          isLoading: false,
          isDirty: false,
          isConflictError: false,
          clearError: true,
        );
        return;
      }

      final records = await repo.fetchRecordsBySession(session.id);
      if (!ref.mounted) return;

      final existingByEnrollment = <String, AttendanceRecord>{
        for (final r in records) r.enrollmentId: r,
      };
      final draftStatuses = <String, AttendanceStatus>{
        for (final r in records) r.enrollmentId: r.status,
      };
      final draftNotes = <String, String>{
        for (final r in records)
          if (r.note.trim().isNotEmpty) r.enrollmentId: r.note,
      };

      state = state.copyWith(
        selectedDate: date,
        currentSession: session,
        existingRecordsByEnrollment: Map.unmodifiable(existingByEnrollment),
        draftStatuses: Map.unmodifiable(draftStatuses),
        draftNotes: Map.unmodifiable(draftNotes),
        sessionNote: session.note,
        isLoading: false,
        isDirty: false,
        isConflictError: false,
        clearError: true,
      );
    } catch (error) {
      if (!ref.mounted) return;
      final appErr = ThaiErrorMapper.toAppException(error);
      state = state.copyWith(
        isLoading: false,
        isConflictError: appErr is ConflictException,
        errorMessage: appErr.message,
      );
    }
  }

  Future<void> reloadCurrentDate() => loadDate(state.selectedDate);

  void setStudentStatus(String enrollmentId, AttendanceStatus status) {
    if (state.isLocked || state.isSaving) return;
    final next = Map<String, AttendanceStatus>.of(state.draftStatuses);
    next[enrollmentId] = status;
    state = state.copyWith(
      draftStatuses: Map.unmodifiable(next),
      isDirty: true,
      clearError: true,
    );
  }

  void setStudentNote(String enrollmentId, String note) {
    if (state.isLocked || state.isSaving) return;
    final trimmed = note.trim();
    final next = Map<String, String>.of(state.draftNotes);
    if (trimmed.isEmpty) {
      next.remove(enrollmentId);
    } else {
      next[enrollmentId] = trimmed;
    }
    state = state.copyWith(
      draftNotes: Map.unmodifiable(next),
      isDirty: true,
      clearError: true,
    );
  }

  void setSessionNote(String note) {
    if (state.isLocked || state.isSaving) return;
    state = state.copyWith(sessionNote: note.trim(), isDirty: true);
  }

  void markAllPresent(List<String> eligibleEnrollmentIds) {
    if (state.isLocked || state.isSaving || eligibleEnrollmentIds.isEmpty) {
      return;
    }
    final next = Map<String, AttendanceStatus>.of(state.draftStatuses);
    for (final id in eligibleEnrollmentIds) {
      next[id] = AttendanceStatus.present;
    }
    state = state.copyWith(
      draftStatuses: Map.unmodifiable(next),
      isDirty: true,
      clearError: true,
    );
  }

  Future<bool> unlockSession() async {
    final session = state.currentSession;
    if (session == null || !session.isLocked || state.isSaving) {
      return false;
    }
    state = state.copyWith(
      isSaving: true,
      isConflictError: false,
      clearError: true,
    );
    try {
      final updated = await ref
          .read(attendanceRepositoryProvider)
          .updateSession(
            sessionId: session.id,
            note: session.note,
            isLocked: false,
            expectedVersion: session.version,
          );
      if (!ref.mounted) return false;
      state = state.copyWith(currentSession: updated, isSaving: false);
      ref.invalidate(attendanceSessionsProvider(subjectClassId));
      ref.invalidate(dashboardOverviewProvider);
      return true;
    } catch (error) {
      if (!ref.mounted) return false;
      final appErr = ThaiErrorMapper.toAppException(error);
      state = state.copyWith(
        isSaving: false,
        isConflictError: appErr is ConflictException,
        errorMessage: appErr.message,
      );
      return false;
    }
  }

  Future<bool> saveAttendance({
    required bool lockAfterSave,
    Set<String>? eligibleEnrollmentIds,
  }) async {
    if (state.isSaving || state.isLocked) return false;

    final teacherId = ref.read(authStateProvider).userId;
    if (teacherId == null) {
      state = state.copyWith(
        errorMessage: 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่อีกครั้ง',
      );
      return false;
    }

    final filteredDraftEntries = state.draftStatuses.entries.where((entry) {
      if (eligibleEnrollmentIds == null) return true;
      return eligibleEnrollmentIds.contains(entry.key);
    }).toList(growable: false);

    if (filteredDraftEntries.isEmpty) {
      state = state.copyWith(
        errorMessage: 'กรุณาเลือกสถานะการเข้าเรียนอย่างน้อย 1 คนก่อนบันทึก',
      );
      return false;
    }

    state = state.copyWith(
      isSaving: true,
      isConflictError: false,
      clearError: true,
    );

    try {
      final repo = ref.read(attendanceRepositoryProvider);
      var session = state.currentSession;

      session ??= await repo.createSession(
        teacherId: teacherId,
        subjectClassId: subjectClassId,
        sessionDate: state.selectedDate,
        note: state.sessionNote,
        isLocked: false,
      );

      final inputs = <AttendanceRecordInput>[];
      for (final entry in filteredDraftEntries) {
        final existing = state.existingRecordsByEnrollment[entry.key];
        inputs.add(
          AttendanceRecordInput(
            existingRecordId: existing?.id,
            enrollmentId: entry.key,
            status: entry.value,
            note: state.draftNotes[entry.key] ?? '',
            expectedVersion: existing?.version,
          ),
        );
      }

      final savedRecords = await repo.saveSessionRecords(
        teacherId: teacherId,
        sessionId: session.id,
        inputs: inputs,
      );

      final needsSessionUpdate =
          session.note != state.sessionNote ||
          session.isLocked != lockAfterSave;
      if (needsSessionUpdate) {
        session = await repo.updateSession(
          sessionId: session.id,
          note: state.sessionNote,
          isLocked: lockAfterSave,
          expectedVersion: session.version,
        );
      }

      if (!ref.mounted) return false;
      final mergedByEnrollment = Map<String, AttendanceRecord>.of(
        state.existingRecordsByEnrollment,
      );
      for (final r in savedRecords) {
        mergedByEnrollment[r.enrollmentId] = r;
      }
      state = state.copyWith(
        currentSession: session,
        existingRecordsByEnrollment: Map.unmodifiable(mergedByEnrollment),
        isSaving: false,
        isDirty: false,
        isConflictError: false,
        clearError: true,
      );

      ref.invalidate(attendanceSessionsProvider(subjectClassId));
      ref.invalidate(attendanceClassRecordsProvider(subjectClassId));
      ref.invalidate(dashboardOverviewProvider);
      return true;
    } catch (error) {
      if (!ref.mounted) return false;
      final appErr = ThaiErrorMapper.toAppException(error);
      state = state.copyWith(
        isSaving: false,
        isConflictError: appErr is ConflictException,
        errorMessage: appErr.message,
      );
      return false;
    }
  }
}

final attendanceCheckInControllerProvider = NotifierProvider.autoDispose
    .family<AttendanceCheckInController, AttendanceCheckInState, String>(
      AttendanceCheckInController.new,
    );
