import 'package:checklist_student/core/constants/attendance_status.dart';
import 'package:checklist_student/core/theme/app_theme.dart';
import 'package:checklist_student/core/widgets/unsaved_changes_provider.dart';
import 'package:checklist_student/features/attendance/domain/entities/attendance_record.dart';
import 'package:checklist_student/features/attendance/domain/entities/attendance_record_input.dart';
import 'package:checklist_student/features/attendance/domain/entities/attendance_rule_config.dart';
import 'package:checklist_student/features/attendance/domain/entities/attendance_session.dart';
import 'package:checklist_student/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:checklist_student/features/attendance/presentation/pages/attendance_check_in_page.dart';
import 'package:checklist_student/features/attendance/presentation/pages/attendance_rule_settings_page.dart';
import 'package:checklist_student/features/attendance/presentation/providers/attendance_check_in_controller.dart';
import 'package:checklist_student/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:checklist_student/features/attendance/presentation/widgets/attendance_student_row.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/class_enrollment.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/student_lifecycle_status.dart';
import 'package:checklist_student/features/homeroom_roster/presentation/providers/homeroom_roster_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeAttendanceRepository implements AttendanceRepository {
  _FakeAttendanceRepository({required this.ruleConfig});

  AttendanceRuleConfig ruleConfig;

  @override
  Future<List<AttendanceSession>> fetchSessions(String subjectClassId) async =>
      const <AttendanceSession>[];

  @override
  Future<AttendanceSession?> fetchSessionByDate({
    required String subjectClassId,
    required DateTime sessionDate,
  }) async => null;

  @override
  Future<List<AttendanceRecord>> fetchRecordsBySession(
    String sessionId,
  ) async => const <AttendanceRecord>[];

  @override
  Future<List<AttendanceRecord>> fetchRecordsByClass(
    String subjectClassId,
  ) async => const <AttendanceRecord>[];

  @override
  Future<AttendanceSession> createSession({
    required String teacherId,
    required String subjectClassId,
    required DateTime sessionDate,
    String note = '',
    bool isLocked = false,
  }) async {
    return AttendanceSession(
      id: 'sess-1',
      teacherId: teacherId,
      subjectClassId: subjectClassId,
      sessionDate: sessionDate,
      isLocked: isLocked,
      note: note,
      version: 1,
      createdAt: sessionDate,
      updatedAt: sessionDate,
    );
  }

  @override
  Future<AttendanceSession> updateSession({
    required String sessionId,
    required String note,
    required bool isLocked,
    required int expectedVersion,
  }) async {
    final now = DateTime.now();
    return AttendanceSession(
      id: sessionId,
      teacherId: 't-1',
      subjectClassId: 'sc-1',
      sessionDate: now,
      isLocked: isLocked,
      note: note,
      version: expectedVersion + 1,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<List<AttendanceRecord>> saveSessionRecords({
    required String teacherId,
    required String sessionId,
    required List<AttendanceRecordInput> inputs,
  }) async => const <AttendanceRecord>[];

  @override
  Future<AttendanceRuleConfig> fetchRuleConfig(String subjectClassId) async =>
      ruleConfig;

  @override
  Future<AttendanceRuleConfig> updateRuleConfig(
    AttendanceRuleConfig config,
  ) async {
    ruleConfig = config;
    return config;
  }
}

ClassEnrollment _makeEnrollment({
  required String id,
  required int number,
  required String code,
  required String firstName,
  required DateTime enrolledAt,
  StudentLifecycleStatus status = StudentLifecycleStatus.active,
  DateTime? transferredOutAt,
}) {
  return ClassEnrollment(
    id: id,
    teacherId: 't-1',
    subjectClassId: 'sc-1',
    homeroomStudentId: null,
    studentIdentityId: 'sid-$id',
    studentCode: code,
    studentNumber: number,
    prefix: 'ด.ช.',
    firstName: firstName,
    lastName: 'ทดสอบ',
    status: status,
    enrolledAt: enrolledAt,
    transferredOutAt: transferredOutAt,
    specialGradeOverride: null,
    wasRResolved: false,
    wasMsResolved: false,
    resolvedGradeAt: null,
    version: 1,
    createdAt: enrolledAt,
    updatedAt: enrolledAt,
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Attendance UI Widgets & Guardrails', () {
    testWidgets(
      'AttendanceStudentRow allows selecting 4 statuses when unlocked and blocks taps when locked (390px)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final today = DateTime(2026, 11, 24);
        final student = _makeEnrollment(
          id: 'enr-1',
          number: 1,
          code: '65001',
          firstName: 'สมชาย',
          enrolledAt: DateTime(2026, 5, 16),
        );

        AttendanceStatus? selected;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(12),
                child: AttendanceStudentRow(
                  enrollment: student,
                  selectedDate: today,
                  selectedStatus: selected,
                  note: '',
                  summary: null,
                  isLocked: false,
                  onStatusSelected: (status) => selected = status,
                  onEditNote: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('มา'));
        expect(selected, AttendanceStatus.present);

        await tester.tap(find.text('สาย'));
        expect(selected, AttendanceStatus.late);

        await tester.tap(find.text('ลา'));
        expect(selected, AttendanceStatus.leave);

        await tester.tap(find.text('ขาด'));
        expect(selected, AttendanceStatus.absent);

        // Rebuild in locked state: taps must be ignored.
        selected = AttendanceStatus.present;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(12),
                child: AttendanceStudentRow(
                  enrollment: student,
                  selectedDate: today,
                  selectedStatus: selected,
                  note: '',
                  summary: null,
                  isLocked: true,
                  onStatusSelected: (status) => selected = status,
                  onEditNote: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('ขาด'));
        expect(selected, AttendanceStatus.present);
      },
    );

    testWidgets(
      'Mark All Present only marks eligible students and skips mid-term students enrolled after selectedDate',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final pastEnrolled = today.subtract(const Duration(days: 10));
        final futureEnrolled = today.add(const Duration(days: 5));

        final enrollments = <ClassEnrollment>[
          _makeEnrollment(
            id: 'enr-eligible',
            number: 1,
            code: '65001',
            firstName: 'สมชาย',
            enrolledAt: pastEnrolled,
          ),
          _makeEnrollment(
            id: 'enr-future',
            number: 2,
            code: '65002',
            firstName: 'มาทีหลัง',
            enrolledAt: futureEnrolled,
          ),
        ];

        final fakeRepo = _FakeAttendanceRepository(
          ruleConfig: const AttendanceRuleConfig(
            subjectClassId: 'sc-1',
            absentThresholdPct: 20.0,
            countLeaveAsAbsent: false,
          ),
        );

        final container = ProviderContainer(
          overrides: [
            attendanceRepositoryProvider.overrideWithValue(fakeRepo),
            classEnrollmentsProvider('sc-1').overrideWith(
              (ref) async => enrollments,
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(
                body: AttendanceCheckInPage(initialClassId: 'sc-1'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('ไม่ต้องเช็คชื่อวันนี้'), findsOneWidget);

        await tester.tap(find.text('มาทั้งหมด'));
        await tester.pumpAndSettle();

        final state = container.read(
          attendanceCheckInControllerProvider('sc-1'),
        );
        expect(state.draftStatuses['enr-eligible'], AttendanceStatus.present);
        expect(state.draftStatuses.containsKey('enr-future'), isFalse);
        expect(state.isDirty, isTrue);
      },
    );

    testWidgets(
      'AttendanceRuleSettingsPage marks unsavedChangesStateProvider dirty and shows UnsavedChangesGuard dialog on exit',
      (tester) async {
        final fakeRepo = _FakeAttendanceRepository(
          ruleConfig: const AttendanceRuleConfig(
            subjectClassId: 'sc-1',
            absentThresholdPct: 20.0,
            lateToAbsentRatio: null,
            countLeaveAsAbsent: false,
          ),
        );

        final container = ProviderContainer(
          overrides: [
            attendanceRepositoryProvider.overrideWithValue(fakeRepo),
            classEnrollmentsProvider('sc-1').overrideWith(
              (ref) async => const <ClassEnrollment>[],
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(
                body: AttendanceRuleSettingsPage(subjectClassId: 'sc-1'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(container.read(unsavedChangesStateProvider), isFalse);

        // Toggle "นับการลา (ลาป่วย/ลากิจ) รวมเป็นการขาดเรียน"
        await tester.tap(
          find.text('นับการลา (ลาป่วย/ลากิจ) รวมเป็นการขาดเรียน'),
        );
        await tester.pumpAndSettle();

        expect(container.read(unsavedChangesStateProvider), isTrue);

        // Attempt to leave via "กลับหน้าเช็คชื่อ" -> UnsavedChangesGuard dialog must appear.
        await tester.tap(find.text('กลับหน้าเช็คชื่อ'));
        await tester.pumpAndSettle();

        expect(find.text('ยังไม่ได้บันทึกการเปลี่ยนแปลง'), findsOneWidget);

        await tester.tap(find.text('อยู่หน้านี้ต่อ'));
        await tester.pumpAndSettle();
        expect(find.text('ตั้งค่าเกณฑ์เวลาเรียน (มส) รายวิชา'), findsOneWidget);
      },
    );
  });
}
