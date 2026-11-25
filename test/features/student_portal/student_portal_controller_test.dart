import 'package:checklist_student/features/student_portal/domain/entities/resolved_teacher_portal.dart';
import 'package:checklist_student/features/student_portal/domain/entities/student_pin_access_status.dart';
import 'package:checklist_student/features/student_portal/domain/entities/student_pin_verification_result.dart';
import 'package:checklist_student/features/student_portal/domain/entities/student_portal_summary.dart';
import 'package:checklist_student/features/student_portal/domain/repositories/student_portal_repository.dart';
import 'package:checklist_student/features/student_portal/presentation/providers/student_portal_controller.dart';
import 'package:checklist_student/features/student_portal/presentation/providers/student_portal_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStudentPortalRepository implements StudentPortalRepository {
  bool hasPin = false;
  int failedAttempts = 0;
  DateTime? lockedUntil;
  String savedPin = '';
  final List<String?> requestedTermIds = <String?>[];

  @override
  Future<ResolvedTeacherPortal> resolveTeacherCode(String teacherCode) async {
    final normalized = teacherCode.trim().toLowerCase();
    if (normalized == 't-old1') {
      return const ResolvedTeacherPortal(
        found: true,
        isRedirected: true,
        requestedCode: 't-old1',
        currentTeacherCode: 't-7777',
        teacherDisplayName: 'ครูสมหญิง ใจดี',
        schoolName: 'โรงเรียนทดสอบวิทยา',
        department: 'วิทยาศาสตร์',
      );
    }
    if (normalized == 't-7777') {
      return const ResolvedTeacherPortal(
        found: true,
        isRedirected: false,
        requestedCode: 't-7777',
        currentTeacherCode: 't-7777',
        teacherDisplayName: 'ครูสมหญิง ใจดี',
        schoolName: 'โรงเรียนทดสอบวิทยา',
        department: 'วิทยาศาสตร์',
      );
    }
    return ResolvedTeacherPortal(
      found: false,
      isRedirected: false,
      requestedCode: normalized,
    );
  }

  @override
  Future<StudentPinAccessStatus> checkStudentAccess({
    required String teacherCode,
    required String studentCode,
  }) async {
    if (studentCode != '67001') {
      return const StudentPinAccessStatus(
        teacherFound: true,
        studentFound: false,
        hasPin: false,
        isLocked: false,
        remainingAttempts: 5,
      );
    }
    return StudentPinAccessStatus(
      teacherFound: true,
      studentFound: true,
      hasPin: hasPin,
      isLocked: lockedUntil != null && lockedUntil!.isAfter(DateTime.now()),
      lockedUntil: lockedUntil,
      remainingAttempts: (5 - failedAttempts).clamp(0, 5),
    );
  }

  @override
  Future<StudentPinVerificationResult> verifyOrSetPin({
    required String teacherCode,
    required String studentCode,
    required String pin,
    StudentPinAuthMode mode = StudentPinAuthMode.verify,
  }) async {
    if (mode == StudentPinAuthMode.setup) {
      hasPin = true;
      savedPin = pin;
      failedAttempts = 0;
      lockedUntil = null;
      return const StudentPinVerificationResult(
        success: true,
        remainingAttempts: 5,
      );
    }

    if (lockedUntil != null && lockedUntil!.isAfter(DateTime.now())) {
      return StudentPinVerificationResult(
        success: false,
        errorCode: StudentPinErrorCode.pinLocked,
        message: 'ถูกล็อกชั่วคราว',
        remainingAttempts: 0,
        lockedUntil: lockedUntil,
      );
    }

    if (pin == savedPin) {
      failedAttempts = 0;
      lockedUntil = null;
      return const StudentPinVerificationResult(
        success: true,
        remainingAttempts: 5,
      );
    }

    failedAttempts++;
    if (failedAttempts >= 5) {
      lockedUntil = DateTime.now().add(const Duration(minutes: 15));
      return StudentPinVerificationResult(
        success: false,
        errorCode: StudentPinErrorCode.pinLocked,
        message: 'กรอกรหัส PIN ผิดครบ 5 ครั้ง ระบบล็อกชั่วคราว 15 นาที',
        remainingAttempts: 0,
        lockedUntil: lockedUntil,
      );
    }
    return StudentPinVerificationResult(
      success: false,
      errorCode: StudentPinErrorCode.invalidPin,
      message: 'รหัส PIN ไม่ถูกต้อง',
      remainingAttempts: 5 - failedAttempts,
    );
  }

  @override
  Future<StudentPortalSummary> fetchPortalSummary({
    required String teacherCode,
    required String studentCode,
    required String pin,
    String? termId,
  }) async {
    requestedTermIds.add(termId);
    if (pin != savedPin) {
      return const StudentPortalSummary(
        authorized: false,
        errorCode: StudentPinErrorCode.invalidPin,
        errorMessage: 'รหัส PIN ไม่ถูกต้อง',
      );
    }
    return StudentPortalSummary(
      authorized: true,
      teacher: const ResolvedTeacherPortal(
        found: true,
        isRedirected: false,
        requestedCode: 't-7777',
        currentTeacherCode: 't-7777',
        teacherDisplayName: 'ครูสมหญิง ใจดี',
      ),
      student: const StudentPortalStudentInfo(
        studentCode: '67001',
        prefix: 'ด.ช.',
        firstName: 'สมชาย',
        lastName: 'ตั้งใจเรียน',
      ),
      availableTerms: const <StudentPortalTermOption>[
        StudentPortalTermOption(
          termId: 'term-2',
          academicYearBe: 2569,
          termLabel: '2',
          isPinnedActive: true,
        ),
        StudentPortalTermOption(
          termId: 'term-1',
          academicYearBe: 2569,
          termLabel: '1',
          isPinnedActive: false,
        ),
      ],
      selectedTermId: termId ?? 'term-2',
    );
  }
}

void main() {
  group('StudentPortalController', () {
    test('resolves archived teacher_code with redirect notice', () async {
      final repo = _FakeStudentPortalRepository();
      final container = ProviderContainer(
        overrides: [studentPortalRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final ctrl = container.read(studentPortalControllerProvider.notifier);
      await ctrl.initialize('t-old1');

      final state = container.read(studentPortalControllerProvider);
      expect(state.step, StudentPortalStep.enterStudentCode);
      expect(state.wasRedirectedFromOldCode, isTrue);
      expect(state.resolvedTeacher?.currentTeacherCode, 't-7777');
      expect(state.infoMessage, contains('t-7777'));
    });

    test('new student sets 6-digit PIN, switches term, and clears state on signOut', () async {
      final repo = _FakeStudentPortalRepository()..hasPin = false;
      final container = ProviderContainer(
        overrides: [studentPortalRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final ctrl = container.read(studentPortalControllerProvider.notifier);
      await ctrl.initialize('t-7777');
      await ctrl.lookupStudentCode('67001');

      expect(
        container.read(studentPortalControllerProvider).step,
        StudentPortalStep.setupPin,
      );

      await ctrl.submitPinSetup(pin: '246810', confirmPin: '246810');
      final authed = container.read(studentPortalControllerProvider);
      expect(authed.step, StudentPortalStep.authenticated);
      expect(authed.summary?.selectedTermId, 'term-2');

      await ctrl.selectTerm('term-1');
      expect(
        container.read(studentPortalControllerProvider).summary?.selectedTermId,
        'term-1',
      );
      expect(repo.requestedTermIds, <String?>[null, 'term-1']);

      ctrl.signOut();
      final afterSignOut = container.read(studentPortalControllerProvider);
      expect(afterSignOut.step, StudentPortalStep.enterStudentCode);
      expect(afterSignOut.summary, isNull);
      expect(afterSignOut.studentCode, isEmpty);
    });

    test('existing student gets remainingAttempts countdown, locks at 5, then succeeds after unlock', () async {
      final repo = _FakeStudentPortalRepository()
        ..hasPin = true
        ..savedPin = '246810';
      final container = ProviderContainer(
        overrides: [studentPortalRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final ctrl = container.read(studentPortalControllerProvider.notifier);
      await ctrl.initialize('t-7777');
      await ctrl.lookupStudentCode('67001');
      expect(
        container.read(studentPortalControllerProvider).step,
        StudentPortalStep.verifyPin,
      );

      for (var i = 1; i <= 4; i++) {
        await ctrl.submitPinVerify('000000');
        final s = container.read(studentPortalControllerProvider);
        expect(s.remainingAttempts, 5 - i);
        expect(s.isLockedAt(DateTime.now()), isFalse);
      }

      // 5th wrong attempt triggers 15-minute lockout
      await ctrl.submitPinVerify('000000');
      final lockedState = container.read(studentPortalControllerProvider);
      expect(lockedState.remainingAttempts, 0);
      expect(lockedState.isLockedAt(DateTime.now()), isTrue);

      // Simulate lockout expiry then login with right PIN
      repo.lockedUntil = DateTime.now().subtract(const Duration(seconds: 5));
      ctrl.clearExpiredLockout();
      await ctrl.submitPinVerify('246810');
      expect(
        container.read(studentPortalControllerProvider).step,
        StudentPortalStep.authenticated,
      );
    });
  });
}
