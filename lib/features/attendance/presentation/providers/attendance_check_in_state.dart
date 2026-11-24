import '../../../../core/constants/attendance_status.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_session.dart';

/// Immutable draft & loading state for one day's classroom attendance check-in.
class AttendanceCheckInState {
  const AttendanceCheckInState({
    required this.subjectClassId,
    required this.selectedDate,
    this.currentSession,
    this.existingRecordsByEnrollment = const <String, AttendanceRecord>{},
    this.draftStatuses = const <String, AttendanceStatus>{},
    this.draftNotes = const <String, String>{},
    this.sessionNote = '',
    this.isLoading = true,
    this.isSaving = false,
    this.isDirty = false,
    this.isConflictError = false,
    this.errorMessage,
  });

  final String subjectClassId;
  final DateTime selectedDate;
  final AttendanceSession? currentSession;
  final Map<String, AttendanceRecord> existingRecordsByEnrollment;
  final Map<String, AttendanceStatus> draftStatuses;
  final Map<String, String> draftNotes;
  final String sessionNote;
  final bool isLoading;
  final bool isSaving;
  final bool isDirty;
  final bool isConflictError;
  final String? errorMessage;

  bool get isLocked => currentSession?.isLocked ?? false;

  bool get hasSavedSession => currentSession != null;

  AttendanceCheckInState copyWith({
    DateTime? selectedDate,
    AttendanceSession? currentSession,
    bool clearSession = false,
    Map<String, AttendanceRecord>? existingRecordsByEnrollment,
    Map<String, AttendanceStatus>? draftStatuses,
    Map<String, String>? draftNotes,
    String? sessionNote,
    bool? isLoading,
    bool? isSaving,
    bool? isDirty,
    bool? isConflictError,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AttendanceCheckInState(
      subjectClassId: subjectClassId,
      selectedDate: selectedDate ?? this.selectedDate,
      currentSession: clearSession
          ? null
          : (currentSession ?? this.currentSession),
      existingRecordsByEnrollment:
          existingRecordsByEnrollment ?? this.existingRecordsByEnrollment,
      draftStatuses: draftStatuses ?? this.draftStatuses,
      draftNotes: draftNotes ?? this.draftNotes,
      sessionNote: sessionNote ?? this.sessionNote,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isDirty: isDirty ?? this.isDirty,
      isConflictError: isConflictError ?? this.isConflictError,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
