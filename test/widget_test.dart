import 'package:checklist_student/app.dart';
import 'package:checklist_student/core/network/connectivity_provider.dart';
import 'package:checklist_student/core/theme/theme_mode_provider.dart';
import 'package:checklist_student/features/auth/domain/entities/auth_state.dart';
import 'package:checklist_student/features/auth/domain/entities/teacher_feature_flags.dart';
import 'package:checklist_student/features/auth/domain/entities/teacher_profile.dart';
import 'package:checklist_student/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeAuthStateNotifier extends AuthStateNotifier {
  _FakeAuthStateNotifier(this._initialState);

  final AuthSessionState _initialState;

  @override
  AuthSessionState build() => _initialState;
}

AuthSessionState _buildAuthenticatedState() {
  final now = DateTime(2026, 11, 23);
  return AuthSessionState.authenticated(
    userId: 'teacher-1',
    profile: TeacherProfile(
      id: 'teacher-1',
      email: 'kru@school.ac.th',
      displayName: 'ครูสมชาย',
      schoolName: 'โรงเรียนตัวอย่าง',
      department: 'วิทยาศาสตร์',
      teacherCode: 't-8492',
      defaultAbsentThresholdPct: 20.0,
      defaultMissingWorkThreshold: 3,
      createdAt: now,
      updatedAt: now,
    ),
    featureFlags: TeacherFeatureFlags(
      teacherId: 'teacher-1',
      canUseAi: true,
      updatedAt: now,
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'redirects unauthenticated user to teacher login page and toggles theme',
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

      expect(find.text('Checklist-Student'), findsOneWidget);
      expect(find.text('เข้าสู่ระบบสำหรับครูผู้สอน'), findsOneWidget);
      expect(find.text('เข้าสู่ระบบด้วย Google'), findsOneWidget);

      expect(container.read(themeModeProvider), ThemeMode.system);
      await tester.tap(find.byIcon(Icons.dark_mode_outlined));
      await tester.pumpAndSettle();

      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    },
  );

  testWidgets(
    'renders desktop collapsible sidebar and navigates to settings page',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityStatusProvider.overrideWith(
              (ref) => Stream.value(true),
            ),
            authStateProvider.overrideWith(
              () => _FakeAuthStateNotifier(_buildAuthenticatedState()),
            ),
          ],
          child: const ChecklistStudentApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('หน้าหลักครูผู้สอน (Dashboard)'), findsOneWidget);
      expect(find.text('ชื่อผู้สอน: ครูสมชาย'), findsOneWidget);
      expect(find.text('สถานะซิงค์'), findsOneWidget);

      await tester.tap(find.text('ตั้งค่า'));
      await tester.pumpAndSettle();

      expect(find.text('โปรไฟล์และการตั้งค่าครู'), findsOneWidget);
      expect(find.text('รหัสครูและลิงก์ Student Portal'), findsOneWidget);
      expect(find.text('การแสดงผลและสิทธิ์การใช้งาน'), findsOneWidget);
    },
  );

  testWidgets(
    'renders mobile 390px bottom navigation bar cleanly without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityStatusProvider.overrideWith(
              (ref) => Stream.value(true),
            ),
            authStateProvider.overrideWith(
              () => _FakeAuthStateNotifier(_buildAuthenticatedState()),
            ),
          ],
          child: const ChecklistStudentApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('ตั้งค่า'), findsOneWidget);

      await tester.tap(find.text('ตั้งค่า'));
      await tester.pumpAndSettle();

      expect(find.text('โปรไฟล์และการตั้งค่าครู'), findsOneWidget);
    },
  );
}
