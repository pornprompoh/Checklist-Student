import 'package:checklist_student/core/constants/attendance_status.dart';
import 'package:checklist_student/core/constants/submission_status.dart';
import 'package:checklist_student/core/theme/app_theme.dart';
import 'package:checklist_student/core/utils/in_app_browser_detector.dart';
import 'package:checklist_student/features/student_portal/domain/entities/resolved_teacher_portal.dart';
import 'package:checklist_student/features/student_portal/domain/entities/student_pin_access_status.dart';
import 'package:checklist_student/features/student_portal/domain/entities/student_pin_verification_result.dart';
import 'package:checklist_student/features/student_portal/domain/entities/student_portal_class_detail.dart';
import 'package:checklist_student/features/student_portal/domain/entities/student_portal_summary.dart';
import 'package:checklist_student/features/student_portal/domain/repositories/student_portal_repository.dart';
import 'package:checklist_student/features/student_portal/presentation/pages/student_portal_entry_page.dart';
import 'package:checklist_student/features/student_portal/presentation/providers/student_portal_providers.dart';
import 'package:checklist_student/features/student_portal/presentation/widgets/line_browser_redirect_banner.dart';
import 'package:checklist_student/features/student_portal/presentation/widgets/student_portal_class_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

StudentPortalClassDetail _buildClassDetail({
  required bool showScore,
  required bool showGrade,
}) {
  return StudentPortalClassDetail(
    subjectClassId: 'sc-1',
    subjectCode: 'ว31101',
    subjectName: 'วิทยาการคำนวณและการออกแบบเทคโนโลยี 1',
    roomName: 'ม.4/1',
    studentNumber: 1,
    enrollmentStatus: 'active',
    enrolledAt: DateTime(2026, 5, 16),
    showScoreToStudent: showScore,
    showGradeToStudent: showGrade,
    totalScore: showScore ? 79.99 : null,
    totalMaxScore: 100.0,
    displayedGrade: showGrade ? '3.5' : null,
    specialGradeOverride: null,
    attendanceSummary: const StudentPortalAttendanceSummary(
      totalEligibleSessions: 10,
      recordedSessions: 10,
      presentCount: 7,
      lateCount: 1,
      leaveCount: 1,
      absentCount: 1,
      convertedLateAbsentCount: 0,
      countedLeaveAbsentCount: 0,
      effectiveAbsentCount: 1,
      absentPercentage: 10.0,
      absentThresholdPct: 20.0,
    ),
    attendanceRecords: <StudentPortalAttendanceRecord>[
      StudentPortalAttendanceRecord(
        sessionDate: DateTime(2026, 11, 25),
        status: AttendanceStatus.present,
        note: 'เข้าเรียนตรงเวลา',
      ),
    ],
    categoryScores: <StudentPortalCategoryScore>[
      StudentPortalCategoryScore(
        categoryId: 'cat-1',
        categoryName: 'คะแนนเก็บระหว่างภาค',
        targetMaxScore: 100,
        maxScore: 100,
        earnedScore: showScore ? 79.99 : null,
      ),
    ],
    assignments: <StudentPortalAssignmentItem>[
      StudentPortalAssignmentItem(
        assignmentId: 'asg-1',
        categoryId: 'cat-1',
        categoryName: 'คะแนนเก็บระหว่างภาค',
        title: 'ใบงานที่ 1 การวิเคราะห์ขั้นตอนวิธี',
        maxScore: 50,
        isMandatory: true,
        dueDate: DateTime(2026, 7, 15),
        submissionStatus: SubmissionStatus.submitted,
        score: showScore ? 39.99 : null,
        note: 'ส่งครบเรียบร้อย',
      ),
    ],
  );
}

class _WidgetTestPortalRepo implements StudentPortalRepository {
  @override
  Future<ResolvedTeacherPortal> resolveTeacherCode(String teacherCode) async {
    return const ResolvedTeacherPortal(
      found: true,
      isRedirected: false,
      requestedCode: 't-7777',
      currentTeacherCode: 't-7777',
      teacherDisplayName: 'ครูสมหญิง ประเสริฐศรีวิทยา',
      schoolName: 'โรงเรียนมัธยมสาธิตตัวอย่างเฉลิมพระเกียรติ',
      department: 'กลุ่มสาระการเรียนรู้วิทยาศาสตร์และเทคโนโลยี',
    );
  }

  @override
  Future<StudentPinAccessStatus> checkStudentAccess({
    required String teacherCode,
    required String studentCode,
  }) async {
    return const StudentPinAccessStatus(
      teacherFound: true,
      studentFound: true,
      hasPin: true,
      isLocked: false,
      remainingAttempts: 5,
    );
  }

  @override
  Future<StudentPinVerificationResult> verifyOrSetPin({
    required String teacherCode,
    required String studentCode,
    required String pin,
    StudentPinAuthMode mode = StudentPinAuthMode.verify,
  }) async {
    return const StudentPinVerificationResult(
      success: true,
      remainingAttempts: 5,
    );
  }

  @override
  Future<StudentPortalSummary> fetchPortalSummary({
    required String teacherCode,
    required String studentCode,
    required String pin,
    String? termId,
  }) async {
    return StudentPortalSummary(
      authorized: true,
      teacher: const ResolvedTeacherPortal(
        found: true,
        isRedirected: false,
        requestedCode: 't-7777',
        currentTeacherCode: 't-7777',
        teacherDisplayName: 'ครูสมหญิง ประเสริฐศรีวิทยา',
        schoolName: 'โรงเรียนมัธยมสาธิตตัวอย่างเฉลิมพระเกียรติ',
      ),
      student: const StudentPortalStudentInfo(
        studentCode: '67001',
        prefix: 'ด.ช.',
        firstName: 'สมชาย',
        lastName: 'ตั้งใจเรียน',
      ),
      availableTerms: const <StudentPortalTermOption>[
        StudentPortalTermOption(
          termId: 'term-1',
          academicYearBe: 2569,
          termLabel: '1',
          isPinnedActive: true,
        ),
      ],
      selectedTermId: 'term-1',
      classes: <StudentPortalClassDetail>[
        _buildClassDetail(showScore: true, showGrade: true),
        _buildClassDetail(showScore: false, showGrade: false),
      ],
    );
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('LineBrowserRedirectBanner', () {
    testWidgets('shows LINE external browser button with ?openExternalBrowser=1', (
      tester,
    ) async {
      final info = parseInAppBrowserInfo(
        userAgent: 'Mozilla/5.0 Line/14.0.0',
        currentUrl: 'https://example.com/student/t-7777',
      );
      String? openedUrl;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: LineBrowserRedirectBanner(
              browserInfoOverride: info,
              onOpenExternal: (url) => openedUrl = url,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('LINE'), findsOneWidget);
      expect(find.text('เปิดในเบราว์เซอร์หลัก'), findsOneWidget);

      await tester.tap(find.text('เปิดในเบราว์เซอร์หลัก'));
      await tester.pumpAndSettle();
      expect(openedUrl, 'https://example.com/student/t-7777?openExternalBrowser=1');
    });
  });

  group('StudentPortalClassCard', () {
    testWidgets('renders exact unrounded 79.99 score and 3.5 grade when visible', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: StudentPortalClassCard(
                detail: _buildClassDetail(showScore: true, showGrade: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('79.99 / 100'), findsOneWidget);
      expect(find.text('3.5'), findsOneWidget);
      expect(find.text('39.99 / 50'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows polite hidden messages when score and grade are masked while keeping attendance & submission status', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: StudentPortalClassCard(
                detail: _buildClassDetail(showScore: false, showGrade: false),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ครูยังไม่เปิดเผยคะแนนของวิชานี้'), findsOneWidget);
      expect(find.text('ครูยังไม่เปิดเผยเกรดของวิชานี้'), findsOneWidget);
      expect(find.text('มา 7'), findsOneWidget);
      expect(find.text('ส่งแล้ว'), findsOneWidget);
      expect(find.text('79.99'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('StudentPortalEntryPage Responsive Overflow Stress Check (4 Viewports)', () {
    const viewports = <Size>[
      Size(320, 568),
      Size(390, 844),
      Size(640, 460),
      Size(1280, 800),
    ];

    testWidgets('renders Lookup -> PIN -> Summary cleanly without RenderFlex overflow across 4 viewports', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final lineInfo = parseInAppBrowserInfo(
        userAgent: 'Mozilla/5.0 Line/14.0.0',
        currentUrl: 'https://example.com/student/t-7777',
      );

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          ProviderScope(
            key: ValueKey<String>('portal_${size.width}x${size.height}'),
            overrides: [
              studentPortalRepositoryProvider.overrideWithValue(
                _WidgetTestPortalRepo(),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: StudentPortalEntryPage(
                initialTeacherCode: 't-7777',
                browserInfoOverride: lineInfo,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Lookup overflow at $size');

        // Step 1 -> Step 2 (PIN screen)
        await tester.ensureVisible(find.byType(TextField).first);
        await tester.enterText(find.byType(TextField).first, '67001');
        await tester.ensureVisible(find.text('ถัดไป'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ถัดไป'));
        await tester.pumpAndSettle();
        expect(find.text('ยืนยันรหัส PIN 6 หลัก'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'PIN overflow at $size');

        // Step 2 -> Authenticated Summary screen
        await tester.ensureVisible(find.byType(TextField).first);
        await tester.enterText(find.byType(TextField).first, '246810');
        await tester.ensureVisible(find.text('ยืนยันรหัส PIN'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ยืนยันรหัส PIN'));
        await tester.pumpAndSettle();
        expect(find.text('ด.ช.สมชาย ตั้งใจเรียน'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Summary overflow at $size');
      }
    });
  });
}
