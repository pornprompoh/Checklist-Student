import '../../domain/entities/resolved_teacher_portal.dart';
import '../../domain/entities/student_portal_summary.dart';

/// Discrete UI step of the unauthenticated Student Portal flow.
enum StudentPortalStep {
  resolvingTeacher,
  teacherNotFound,
  enterTeacherCode,
  enterStudentCode,
  setupPin,
  verifyPin,
  authenticated,
}

/// Immutable presentation state for `StudentPortalController`.
///
/// Intentionally NEVER holds the student's raw 6-digit PIN in public UI state
/// or serializable objects.
class StudentPortalState {
  const StudentPortalState({
    this.step = StudentPortalStep.resolvingTeacher,
    this.isBusy = false,
    this.requestedTeacherCode = '',
    this.resolvedTeacher,
    this.wasRedirectedFromOldCode = false,
    this.studentCode = '',
    this.remainingAttempts,
    this.lockedUntil,
    this.summary,
    this.errorMessage,
    this.infoMessage,
  });

  final StudentPortalStep step;
  final bool isBusy;
  final String requestedTeacherCode;
  final ResolvedTeacherPortal? resolvedTeacher;
  final bool wasRedirectedFromOldCode;
  final String studentCode;
  final int? remainingAttempts;
  final DateTime? lockedUntil;
  final StudentPortalSummary? summary;
  final String? errorMessage;
  final String? infoMessage;

  String get activeTeacherCode =>
      resolvedTeacher?.currentTeacherCode ?? requestedTeacherCode;

  bool isLockedAt(DateTime now) {
    final until = lockedUntil;
    return until != null && until.toUtc().isAfter(now.toUtc());
  }

  static const Object _unset = Object();

  StudentPortalState copyWith({
    StudentPortalStep? step,
    bool? isBusy,
    String? requestedTeacherCode,
    Object? resolvedTeacher = _unset,
    bool? wasRedirectedFromOldCode,
    String? studentCode,
    Object? remainingAttempts = _unset,
    Object? lockedUntil = _unset,
    Object? summary = _unset,
    Object? errorMessage = _unset,
    Object? infoMessage = _unset,
  }) {
    return StudentPortalState(
      step: step ?? this.step,
      isBusy: isBusy ?? this.isBusy,
      requestedTeacherCode: requestedTeacherCode ?? this.requestedTeacherCode,
      resolvedTeacher: identical(resolvedTeacher, _unset)
          ? this.resolvedTeacher
          : resolvedTeacher as ResolvedTeacherPortal?,
      wasRedirectedFromOldCode:
          wasRedirectedFromOldCode ?? this.wasRedirectedFromOldCode,
      studentCode: studentCode ?? this.studentCode,
      remainingAttempts: identical(remainingAttempts, _unset)
          ? this.remainingAttempts
          : remainingAttempts as int?,
      lockedUntil: identical(lockedUntil, _unset)
          ? this.lockedUntil
          : lockedUntil as DateTime?,
      summary: identical(summary, _unset)
          ? this.summary
          : summary as StudentPortalSummary?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      infoMessage: identical(infoMessage, _unset)
          ? this.infoMessage
          : infoMessage as String?,
    );
  }
}
