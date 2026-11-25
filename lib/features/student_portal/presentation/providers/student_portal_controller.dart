import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/thai_error_mapper.dart';
import '../../domain/entities/student_pin_verification_result.dart';
import 'student_portal_providers.dart';
import 'student_portal_state.dart';

export 'student_portal_state.dart';

/// State-machine controller driving `/student` and `/student/:teacherCode`.
///
/// Security invariant: [_activePin] lives strictly in volatile memory for term
/// switching / refresh during the current view and is wiped on [signOut],
/// [changeStudent], and `ref.onDispose`. NEVER persisted to storage or URL.
class StudentPortalController extends Notifier<StudentPortalState> {
  String? _activePin;

  @override
  StudentPortalState build() {
    ref.onDispose(() {
      _activePin = null;
    });
    return const StudentPortalState();
  }

  /// Resolves [teacherCode] from URL or switches to manual teacher-code entry.
  Future<void> initialize(String? teacherCode) async {
    _activePin = null;
    final trimmed = teacherCode?.trim() ?? '';
    if (trimmed.isEmpty) {
      state = const StudentPortalState(
        step: StudentPortalStep.enterTeacherCode,
      );
      return;
    }

    state = StudentPortalState(
      step: StudentPortalStep.resolvingTeacher,
      isBusy: true,
      requestedTeacherCode: trimmed,
    );

    try {
      final resolved = await ref
          .read(studentPortalRepositoryProvider)
          .resolveTeacherCode(trimmed);
      if (!resolved.found) {
        state = StudentPortalState(
          step: StudentPortalStep.teacherNotFound,
          requestedTeacherCode: trimmed,
          errorMessage:
              'ไม่พบรหัสครู "$trimmed" ในระบบ กรุณาตรวจสอบลิงก์หรือขอรหัสใหม่จากครูผู้สอน',
        );
        return;
      }

      state = StudentPortalState(
        step: StudentPortalStep.enterStudentCode,
        requestedTeacherCode: trimmed,
        resolvedTeacher: resolved,
        wasRedirectedFromOldCode: resolved.isRedirected,
        infoMessage: resolved.isRedirected
            ? 'ครูอัปเดตรหัสลิงก์ใหม่เป็น "${resolved.currentTeacherCode}" แล้ว ระบบพามายังหน้าใหม่ให้อัตโนมัติ'
            : null,
      );
    } catch (error) {
      state = StudentPortalState(
        step: StudentPortalStep.teacherNotFound,
        requestedTeacherCode: trimmed,
        errorMessage: ThaiErrorMapper.map(error),
      );
    }
  }

  /// Step 1: Validates [studentCode] and checks PIN setup / lockout status.
  Future<void> lookupStudentCode(String studentCode) async {
    final validator = ref.read(studentPinValidatorServiceProvider);
    final validationError = validator.validateStudentCode(studentCode);
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return;
    }

    final trimmedCode = studentCode.trim();
    state = state.copyWith(isBusy: true, errorMessage: null);

    try {
      final status = await ref
          .read(studentPortalRepositoryProvider)
          .checkStudentAccess(
            teacherCode: state.activeTeacherCode,
            studentCode: trimmedCode,
          );

      if (!status.teacherFound) {
        state = state.copyWith(
          step: StudentPortalStep.teacherNotFound,
          isBusy: false,
          errorMessage: 'ไม่พบรหัสครูผู้สอนในระบบ กรุณาตรวจสอบลิงก์อีกครั้ง',
        );
        return;
      }

      if (!status.studentFound) {
        state = state.copyWith(
          isBusy: false,
          errorMessage:
              'ไม่พบรหัสนักเรียน "$trimmedCode" ในระบบของครูท่านนี้ กรุณาตรวจสอบเลขประจำตัวหรือสอบถามครูผู้สอน',
        );
        return;
      }

      state = state.copyWith(
        step: status.hasPin
            ? StudentPortalStep.verifyPin
            : StudentPortalStep.setupPin,
        isBusy: false,
        studentCode: trimmedCode,
        remainingAttempts: status.remainingAttempts,
        lockedUntil: status.lockedUntil,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: ThaiErrorMapper.map(error),
      );
    }
  }

  /// Step 2a: Sets initial 6-digit PIN and loads the student's portal summary.
  Future<void> submitPinSetup({
    required String pin,
    required String confirmPin,
  }) async {
    final validationError = ref
        .read(studentPinValidatorServiceProvider)
        .validatePinSetup(pin: pin, confirmPin: confirmPin);
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return;
    }
    await _authenticateWithPin(pin: pin, mode: StudentPinAuthMode.setup);
  }

  /// Step 2b: Verifies existing 6-digit PIN and loads the student's summary.
  Future<void> submitPinVerify(String pin) async {
    final validationError = ref
        .read(studentPinValidatorServiceProvider)
        .validatePin(pin);
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return;
    }
    await _authenticateWithPin(pin: pin, mode: StudentPinAuthMode.verify);
  }

  Future<void> _authenticateWithPin({
    required String pin,
    required StudentPinAuthMode mode,
  }) async {
    state = state.copyWith(isBusy: true, errorMessage: null);
    final repo = ref.read(studentPortalRepositoryProvider);
    try {
      final result = await repo.verifyOrSetPin(
        teacherCode: state.activeTeacherCode,
        studentCode: state.studentCode,
        pin: pin,
        mode: mode,
      );

      if (!result.success) {
        final nextStep = result.errorCode == StudentPinErrorCode.pinAlreadySet
            ? StudentPortalStep.verifyPin
            : (result.errorCode == StudentPinErrorCode.pinNotSet
                  ? StudentPortalStep.setupPin
                  : state.step);
        state = state.copyWith(
          step: nextStep,
          isBusy: false,
          remainingAttempts: result.remainingAttempts ?? state.remainingAttempts,
          lockedUntil: result.lockedUntil,
          errorMessage: result.message ?? 'ไม่สามารถยืนยันรหัส PIN ได้',
        );
        return;
      }

      _activePin = pin;
      await _loadSummary(termId: null);
    } catch (error) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: ThaiErrorMapper.map(error),
      );
    }
  }

  /// Switches to another academic term using the in-memory [_activePin].
  Future<void> selectTerm(String termId) async {
    if (_activePin == null || state.isBusy) return;
    state = state.copyWith(isBusy: true, errorMessage: null);
    await _loadSummary(termId: termId);
  }

  /// Re-fetches latest attendance, assignments, scores, and grades from server.
  Future<void> refreshSummary() async {
    if (_activePin == null || state.isBusy) return;
    state = state.copyWith(isBusy: true, errorMessage: null);
    await _loadSummary(termId: state.summary?.selectedTermId);
  }

  Future<void> _loadSummary({required String? termId}) async {
    final pin = _activePin;
    if (pin == null) {
      signOut();
      return;
    }

    try {
      final summary = await ref
          .read(studentPortalRepositoryProvider)
          .fetchPortalSummary(
            teacherCode: state.activeTeacherCode,
            studentCode: state.studentCode,
            pin: pin,
            termId: termId,
          );

      if (!summary.authorized) {
        _activePin = null;
        state = state.copyWith(
          step: StudentPortalStep.enterStudentCode,
          isBusy: false,
          summary: null,
          lockedUntil: summary.lockedUntil,
          errorMessage:
              summary.errorMessage ??
              'สถานะรหัส PIN มีการเปลี่ยนแปลง (อาจถูกรีเซตโดยครูผู้สอน) กรุณากรอกรหัสนักเรียนใหม่อีกครั้ง',
        );
        return;
      }

      state = state.copyWith(
        step: StudentPortalStep.authenticated,
        isBusy: false,
        resolvedTeacher: summary.teacher ?? state.resolvedTeacher,
        summary: summary,
        remainingAttempts: 5,
        lockedUntil: null,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: ThaiErrorMapper.map(error),
      );
    }
  }

  /// Clears lockout banner client-side once countdown reaches 0 so user can retry.
  void clearExpiredLockout() {
    if (state.lockedUntil != null && !state.isLockedAt(DateTime.now())) {
      state = state.copyWith(lockedUntil: null, errorMessage: null);
    }
  }

  /// Returns to Step 1 (student code entry) and wipes in-memory PIN.
  void changeStudent() => signOut();

  /// Wipes in-memory PIN and student summary immediately.
  void signOut() {
    _activePin = null;
    state = state.copyWith(
      step: state.resolvedTeacher != null
          ? StudentPortalStep.enterStudentCode
          : StudentPortalStep.enterTeacherCode,
      isBusy: false,
      studentCode: '',
      remainingAttempts: null,
      lockedUntil: null,
      summary: null,
      errorMessage: null,
    );
  }
}
