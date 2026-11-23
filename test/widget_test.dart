import 'package:checklist_student/app.dart';
import 'package:checklist_student/core/network/connectivity_provider.dart';
import 'package:checklist_student/core/theme/theme_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders bootstrap screen with online status', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityStatusProvider.overrideWith((ref) => Stream.value(true)),
        ],
        child: const ChecklistStudentApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Checklist-Student'), findsOneWidget);
    expect(find.text('ออนไลน์ (เชื่อมต่อเครือข่ายแล้ว)'), findsOneWidget);
  });

  testWidgets('renders bootstrap screen with offline status', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityStatusProvider.overrideWith((ref) => Stream.value(false)),
        ],
        child: const ChecklistStudentApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Checklist-Student'), findsOneWidget);
    expect(find.text('ออฟไลน์ (ไม่พบการเชื่อมต่อเครือข่าย)'), findsOneWidget);
  });

  testWidgets('toggles light and dark theme mode from bootstrap screen', (
    tester,
  ) async {
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
    await tester.pump();

    expect(container.read(themeModeProvider), ThemeMode.system);

    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.light);
  });
}
