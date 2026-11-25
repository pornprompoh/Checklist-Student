import 'package:checklist_student/core/theme/app_theme.dart';
import 'package:checklist_student/features/auth/presentation/pages/teacher_login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'UC-032: TeacherLoginPage renders minimal teacher-only Google Sign-In without student links or showcase copy',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final theme in <ThemeData>[AppTheme.light, AppTheme.dark]) {
        for (final size in const <Size>[Size(320, 568), Size(1280, 800)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: theme,
                home: const TeacherLoginPage(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Checklist-Student'), findsOneWidget);
          expect(find.text('เข้าสู่ระบบสำหรับครูผู้สอน'), findsOneWidget);
          expect(find.text('เข้าสู่ระบบด้วย Google'), findsOneWidget);
          expect(find.textContaining('Student Portal'), findsNothing);
          expect(find.textContaining('พอร์ทัลนักเรียน'), findsNothing);
          expect(
            tester.takeException(),
            isNull,
            reason: 'Overflow at $size (${theme.brightness})',
          );
        }
      }
    },
  );
}
