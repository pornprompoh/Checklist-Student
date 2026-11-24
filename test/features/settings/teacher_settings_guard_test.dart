import 'package:checklist_student/app.dart';
import 'package:checklist_student/core/network/connectivity_provider.dart';
import 'package:checklist_student/core/router/app_router.dart';
import 'package:checklist_student/features/academic_structure/domain/entities/academic_year.dart';
import 'package:checklist_student/features/academic_structure/domain/entities/term.dart';
import 'package:checklist_student/features/academic_structure/presentation/providers/academic_structure_providers.dart';
import 'package:checklist_student/features/auth/domain/entities/auth_state.dart';
import 'package:checklist_student/features/auth/domain/entities/teacher_feature_flags.dart';
import 'package:checklist_student/features/auth/domain/entities/teacher_profile.dart';
import 'package:checklist_student/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:checklist_student/features/settings/domain/entities/import_file_record.dart';
import 'package:checklist_student/features/settings/domain/entities/teacher_code_history_entry.dart';
import 'package:checklist_student/features/settings/domain/entities/teacher_profile_update.dart';
import 'package:checklist_student/features/settings/domain/repositories/settings_repository.dart';
import 'package:checklist_student/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _MutableFakeAuthStateNotifier extends AuthStateNotifier {
  _MutableFakeAuthStateNotifier(this._initialState);

  final AuthSessionState _initialState;

  @override
  AuthSessionState build() => _initialState;
}

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this._profile);

  TeacherProfile _profile;
  final List<TeacherCodeHistoryEntry> _history = <TeacherCodeHistoryEntry>[];
  TeacherProfileUpdate? lastProfileUpdate;
  String? lastUpdatedCode;

  @override
  Future<TeacherProfile> updateTeacherProfile({
    required String teacherId,
    required TeacherProfileUpdate update,
  }) async {
    lastProfileUpdate = update;
    _profile = _profile.copyWith(
      displayName: update.displayName,
      schoolName: update.schoolName,
      department: update.department,
      defaultAbsentThresholdPct: update.defaultAbsentThresholdPct,
      defaultMissingWorkThreshold: update.defaultMissingWorkThreshold,
      updatedAt: _profile.updatedAt.add(const Duration(minutes: 1)),
    );
    return _profile;
  }

  @override
  Future<TeacherProfile> updateTeacherCode({
    required String teacherId,
    required String newTeacherCode,
  }) async {
    final oldCode = _profile.teacherCode;
    lastUpdatedCode = newTeacherCode;
    _history.insert(
      0,
      TeacherCodeHistoryEntry(
        oldCode: oldCode,
        teacherId: teacherId,
        changedAt: DateTime(2026, 11, 24, 9, 0),
      ),
    );
    _profile = _profile.copyWith(
      teacherCode: newTeacherCode,
      updatedAt: _profile.updatedAt.add(const Duration(minutes: 2)),
    );
    return _profile;
  }

  @override
  Future<List<TeacherCodeHistoryEntry>> fetchTeacherCodeHistory(
    String teacherId,
  ) async {
    return List<TeacherCodeHistoryEntry>.unmodifiable(_history);
  }

  @override
  Future<List<ImportFileRecord>> fetchActiveImportFiles(
    String teacherId,
  ) async {
    return const <ImportFileRecord>[];
  }

  @override
  Future<String> createImportFileSignedUrl(String storagePath) async {
    return 'https://example.local/$storagePath';
  }

  @override
  Future<int> cleanupImportFilesByAcademicYear({
    required String teacherId,
    required String academicYearId,
  }) async {
    return 0;
  }
}

TeacherProfile _seedProfile() {
  final now = DateTime(2026, 11, 23, 10, 0);
  return TeacherProfile(
    id: 'teacher-1',
    email: 'kru@school.ac.th',
    displayName: 'ครูสมชาย',
    schoolName: 'โรงเรียนเดิม',
    department: 'วิทยาศาสตร์',
    teacherCode: 't-8492',
    defaultAbsentThresholdPct: 20.0,
    defaultMissingWorkThreshold: 3,
    createdAt: now,
    updatedAt: now,
  );
}

AuthSessionState _authenticatedState(TeacherProfile profile) {
  return AuthSessionState.authenticated(
    userId: profile.id,
    profile: profile,
    featureFlags: TeacherFeatureFlags(
      teacherId: profile.id,
      canUseAi: false,
      updatedAt: profile.updatedAt,
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'UC-002: saves profile changes to repository and syncs auth state cleanly',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final profile = _seedProfile();
      final fakeRepo = _FakeSettingsRepository(profile);
      final container = ProviderContainer(
        overrides: [
          connectivityStatusProvider.overrideWith((ref) => Stream.value(true)),
          authStateProvider.overrideWith(
            () => _MutableFakeAuthStateNotifier(_authenticatedState(profile)),
          ),
          settingsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ChecklistStudentApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ตั้งค่า'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'ชื่อโรงเรียน / สถานศึกษา'),
        'โรงเรียนใหม่วิทยา',
      );
      await tester.pump();

      await tester.tap(find.text('บันทึกข้อมูล'));
      await tester.pumpAndSettle();

      expect(fakeRepo.lastProfileUpdate?.schoolName, 'โรงเรียนใหม่วิทยา');
      expect(
        container.read(authStateProvider).profile?.schoolName,
        'โรงเรียนใหม่วิทยา',
      );
      expect(find.text('บันทึกข้อมูลโปรไฟล์เรียบร้อยแล้ว'), findsOneWidget);
    },
  );

  testWidgets(
    'UC-003: UnsavedChangesGuard warns when switching sidebar menu with unsaved edits',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final profile = _seedProfile();
      final fakeRepo = _FakeSettingsRepository(profile);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityStatusProvider.overrideWith(
              (ref) => Stream.value(true),
            ),
            authStateProvider.overrideWith(
              () => _MutableFakeAuthStateNotifier(_authenticatedState(profile)),
            ),
            settingsRepositoryProvider.overrideWithValue(fakeRepo),
            academicYearsProvider.overrideWith(
              (ref) async => const <AcademicYear>[],
            ),
            allTermsProvider.overrideWith((ref) async => const <Term>[]),
          ],
          child: const ChecklistStudentApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ตั้งค่า'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'กลุ่มสาระการเรียนรู้ / แผนกวิชา'),
        'คณิตศาสตร์',
      );
      await tester.pumpAndSettle();

      // Attempt to switch back to Dashboard via Sidebar
      await tester.tap(find.text('หน้าหลัก'));
      await tester.pumpAndSettle();

      expect(find.text('ยังไม่ได้บันทึกการเปลี่ยนแปลง'), findsOneWidget);

      // Stay on Settings page
      await tester.tap(find.text('อยู่หน้านี้ต่อ'));
      await tester.pumpAndSettle();
      expect(find.text('โปรไฟล์และการตั้งค่าครู'), findsOneWidget);

      // Try switching again and confirm discard
      await tester.tap(find.text('หน้าหลัก'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ออกโดยไม่บันทึก'));
      await tester.pumpAndSettle();

      expect(find.text('สวัสดี, ครูสมชาย'), findsOneWidget);
    },
  );

  testWidgets(
    'UC-005: typing a valid new teacher_code enables submit, opens confirm dialog, saves, and shows Buddhist Era history',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final profile = _seedProfile();
      final fakeRepo = _FakeSettingsRepository(profile);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityStatusProvider.overrideWith(
              (ref) => Stream.value(true),
            ),
            authStateProvider.overrideWith(
              () => _MutableFakeAuthStateNotifier(_authenticatedState(profile)),
            ),
            settingsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const ChecklistStudentApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ตั้งค่า'));
      await tester.pumpAndSettle();

      final codeField = find.widgetWithText(
        TextField,
        'รหัสครูสั้น (Teacher Code)',
      );
      await tester.ensureVisible(codeField);
      await tester.enterText(codeField, 'kru-somchai');
      await tester.pumpAndSettle();

      final changeButton = find.text('เปลี่ยนรหัสครู');
      await tester.ensureVisible(changeButton);
      await tester.tap(changeButton);
      await tester.pumpAndSettle();

      expect(find.text('ยืนยันการเปลี่ยนรหัสครู'), findsOneWidget);

      await tester.tap(find.text('ยืนยันเปลี่ยนรหัส'));
      await tester.pumpAndSettle();

      expect(fakeRepo.lastUpdatedCode, 'kru-somchai');
      expect(find.text('t-8492'), findsOneWidget);
      expect(find.text('เปลี่ยนเมื่อ 24 พ.ย. 2569'), findsOneWidget);
    },
  );

  testWidgets(
    'UC-004: unauthenticated visit to /student/t-8492?openExternalBrowser=1 stays on Student Portal',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          connectivityStatusProvider.overrideWith((ref) => Stream.value(true)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ChecklistStudentApp(),
        ),
      );
      await tester.pumpAndSettle();

      container
          .read(appRouterProvider)
          .go('/student/t-8492?openExternalBrowser=1');
      await tester.pumpAndSettle();

      expect(find.text('พอร์ทัลตรวจสอบคะแนนนักเรียน'), findsOneWidget);
      expect(find.text('รหัสครูผู้สอน: t-8492'), findsOneWidget);
      expect(find.text('openExternalBrowser: 1'), findsOneWidget);
      expect(find.text('เข้าสู่ระบบสำหรับครูผู้สอน'), findsNothing);
    },
  );
}
