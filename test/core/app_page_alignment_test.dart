import 'package:checklist_student/core/theme/app_theme.dart';
import 'package:checklist_student/core/widgets/app_page_container.dart';
import 'package:checklist_student/core/widgets/app_page_header.dart';
import 'package:checklist_student/features/academic_structure/presentation/pages/academic_structure_page.dart';
import 'package:checklist_student/features/attendance/presentation/pages/attendance_check_in_page.dart';
import 'package:checklist_student/features/attendance/presentation/pages/attendance_rule_settings_page.dart';
import 'package:checklist_student/features/audit_log/presentation/pages/audit_log_page.dart';
import 'package:checklist_student/features/dashboard/presentation/pages/teacher_dashboard_page.dart';
import 'package:checklist_student/features/export_reports/presentation/pages/export_reports_page.dart';
import 'package:checklist_student/features/grading/presentation/pages/grading_plan_page.dart';
import 'package:checklist_student/features/grading/presentation/pages/grading_table_page.dart';
import 'package:checklist_student/features/homeroom_roster/presentation/pages/homeroom_roster_page.dart';
import 'package:checklist_student/features/settings/presentation/pages/teacher_settings_page.dart';
import 'package:checklist_student/features/settings/presentation/widgets/teacher_code_section_card.dart';
import 'package:checklist_student/features/settings/presentation/widgets/teacher_profile_form_card.dart';
import 'package:checklist_student/features/sync_queue/presentation/pages/sync_queue_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'responsive_test_fixtures.dart';

void main() {
  late ResponsiveTestFixtures fixtures;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    fixtures = ResponsiveTestFixtures();
  });

  group('Step 8.1.8 — Unified Page Container & Spatial Alignment', () {
    testWidgets(
      'AppPageContainer.scrollable and .viewport align AppPageHeader identically on Desktop, Tablet, and Mobile',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final cases = <(String, Size, Offset)>[
          ('Desktop', const Size(1280, 800), const Offset(28.0, 24.0)),
          ('Tablet', const Size(768, 800), const Offset(20.0, 20.0)),
          ('Mobile', const Size(390, 844), const Offset(16.0, 16.0)),
        ];

        for (final (label, size, expectedOffset) in cases) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(
                body: AppPageContainer.scrollable(
                  header: const AppPageHeader(
                    title: 'หัวข้อทดสอบ',
                    subtitle: 'คำอธิบายทดสอบ',
                  ),
                  child: const SizedBox(height: 200),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final scrollablePos = tester.getTopLeft(find.byType(AppPageHeader));
          expect(
            scrollablePos,
            expectedOffset,
            reason: 'scrollable header offset mismatch on $label',
          );

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(
                body: AppPageContainer.viewport(
                  header: const AppPageHeader(
                    title: 'หัวข้อทดสอบ',
                    subtitle: 'คำอธิบายทดสอบ',
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final viewportPos = tester.getTopLeft(find.byType(AppPageHeader));
          expect(
            viewportPos,
            expectedOffset,
            reason: 'viewport header offset mismatch on $label',
          );
          expect(
            viewportPos,
            scrollablePos,
            reason: 'scrollable vs viewport header offset diverged on $label',
          );

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(
                body: AppPageContainer.viewport(
                  fullBleedWidth: true,
                  header: const AppPageHeader(title: 'หัวข้อทดสอบเต็มความกว้าง'),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final fullBleedPos = tester.getTopLeft(find.byType(AppPageHeader));
          expect(
            fullBleedPos,
            expectedOffset,
            reason: 'fullBleed viewport header offset mismatch on $label',
          );
        }
      },
    );

    testWidgets(
      'All teacher pages start AppPageHeader at identical (28, 24) top-left coordinates on 1280x800 Desktop',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;

        final pages = <String, Widget Function()>{
          'TeacherDashboardPage': () => const TeacherDashboardPage(),
          'AcademicStructurePage': () => const AcademicStructurePage(),
          'HomeroomRosterPage': () => const HomeroomRosterPage(),
          'ExportReportsPage': () =>
              const ExportReportsPage(initialClassId: 'class-1'),
          'AuditLogPage': () => const AuditLogPage(),
          'SyncQueuePage': () => const SyncQueuePage(),
          'TeacherSettingsPage': () => const TeacherSettingsPage(),
          'AttendanceCheckInPage': () =>
              const AttendanceCheckInPage(initialClassId: 'class-1'),
          'AttendanceRuleSettingsPage': () =>
              const AttendanceRuleSettingsPage(subjectClassId: 'class-1'),
          'GradingPlanPage': () =>
              const GradingPlanPage(initialClassId: 'class-1'),
          'GradingTablePage': () =>
              const GradingTablePage(initialClassId: 'class-1'),
        };

        Offset? baseline;

        for (final entry in pages.entries) {
          await tester.pumpWidget(
            ProviderScope(
              key: ValueKey<String>('align_${entry.key}'),
              overrides: fixtures.buildOverrides(),
              child: MaterialApp(
                theme: AppTheme.light,
                home: Scaffold(body: entry.value()),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason: 'Unexpected layout error in ${entry.key}',
          );

          final headerFinder = find.byType(AppPageHeader);
          expect(
            headerFinder,
            findsOneWidget,
            reason: '${entry.key} must render a single AppPageHeader',
          );

          final topLeft = tester.getTopLeft(headerFinder);
          expect(
            topLeft.dx,
            closeTo(28.0, 1.0),
            reason: '${entry.key} header dx must equal 28.0 on Desktop',
          );
          expect(
            topLeft.dy,
            closeTo(24.0, 1.0),
            reason: '${entry.key} header dy must equal 24.0 on Desktop',
          );

          baseline ??= topLeft;
          expect(
            (topLeft.dx - baseline.dx).abs(),
            lessThanOrEqualTo(1.0),
            reason: '${entry.key} header dx drifted from baseline',
          );
          expect(
            (topLeft.dy - baseline.dy).abs(),
            lessThanOrEqualTo(1.0),
            reason: '${entry.key} header dy drifted from baseline',
          );

          if (entry.key == 'TeacherSettingsPage') {
            final profileCardPos = tester.getTopLeft(
              find.byType(TeacherProfileFormCard),
            );
            final codeCardPos = tester.getTopLeft(
              find.byType(TeacherCodeSectionCard),
            );
            expect(
              codeCardPos.dx,
              greaterThan(profileCardPos.dx + 400),
              reason:
                  'TeacherSettingsPage should arrange cards in 2 columns on Desktop 1280px',
            );
            expect(
              (codeCardPos.dy - profileCardPos.dy).abs(),
              lessThanOrEqualTo(1.0),
              reason:
                  'Top cards in left and right columns of TeacherSettingsPage must align horizontally',
            );
          }
        }
      },
    );

    testWidgets(
      'Step 8.1.13 — AppPageHeader keeps actions on a single row and flush with container right edge on 1280px Desktop',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;

        // Case 1: Single overflow button (⋯) must sit flush right — never float around 65%.
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: AppPageContainer.scrollable(
                header: AppPageHeader(
                  title: 'เช็คชื่อรายวัน',
                  actions: [
                    IconButton(
                      key: const ValueKey<String>('single_more_btn'),
                      onPressed: () {},
                      icon: const Icon(Icons.more_horiz_rounded),
                    ),
                  ],
                ),
                child: const SizedBox(
                  key: ValueKey<String>('body_box_single'),
                  height: 120,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final singleHeaderRect = tester.getRect(find.byType(AppPageHeader));
        final singleBodyRect = tester.getRect(
          find.byKey(const ValueKey<String>('body_box_single')),
        );
        final singleBtnRect = tester.getRect(
          find.byKey(const ValueKey<String>('single_more_btn')),
        );

        expect(
          singleHeaderRect.right,
          closeTo(singleBodyRect.right, 0.5),
          reason: 'Header right edge must match body right edge exactly',
        );
        expect(
          singleBtnRect.right,
          closeTo(singleHeaderRect.right, 1.0),
          reason: 'Single ⋯ button must sit flush with right edge of container',
        );

        // Case 2: 3 Dashboard-style actions + inline titleMeta must stay on 1 row and flush right.
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: AppPageContainer.scrollable(
                header: AppPageHeader(
                  title: 'สวัสดี, Pornprom',
                  titleMeta: const Text('·  พ. 25 พ.ย. 2569'),
                  actions: [
                    OutlinedButton(
                      key: const ValueKey<String>('action_term'),
                      onPressed: () {},
                      child: const Text('เทอม 1/2569'),
                    ),
                    FilledButton.icon(
                      key: const ValueKey<String>('action_add'),
                      onPressed: () {},
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('เพิ่มวิชา/ห้อง'),
                    ),
                    IconButton(
                      key: const ValueKey<String>('action_refresh'),
                      onPressed: () {},
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                child: const SizedBox(
                  key: ValueKey<String>('body_box_multi'),
                  height: 120,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final multiHeaderRect = tester.getRect(find.byType(AppPageHeader));
        final multiBodyRect = tester.getRect(
          find.byKey(const ValueKey<String>('body_box_multi')),
        );
        final termRect = tester.getRect(
          find.byKey(const ValueKey<String>('action_term')),
        );
        final addRect = tester.getRect(
          find.byKey(const ValueKey<String>('action_add')),
        );
        final refreshRect = tester.getRect(
          find.byKey(const ValueKey<String>('action_refresh')),
        );

        expect(
          (addRect.center.dy - termRect.center.dy).abs(),
          lessThanOrEqualTo(2.0),
          reason: 'Action buttons must remain on a single horizontal row',
        );
        expect(
          (refreshRect.center.dy - termRect.center.dy).abs(),
          lessThanOrEqualTo(2.0),
          reason: 'Refresh icon must align vertically on the same single row',
        );
        expect(
          multiHeaderRect.right,
          closeTo(multiBodyRect.right, 0.5),
          reason: 'Header and body right edges must match identically',
        );
        expect(
          refreshRect.right,
          closeTo(multiHeaderRect.right, 1.0),
          reason: 'Rightmost action must be flush against container right edge',
        );

        // Case 3: Verify exact right-edge match on ultra-wide 1600px in both modes.
        tester.view.physicalSize = const Size(1600, 900);
        for (final fullBleed in const <bool>[false, true]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(
                body: AppPageContainer.viewport(
                  fullBleedWidth: fullBleed,
                  header: AppPageHeader(
                    title: 'ทดสอบขอบขวา',
                    actions: [
                      FilledButton(
                        key: const ValueKey<String>('wide_cta'),
                        onPressed: () {},
                        child: const Text('ดำเนินการ'),
                      ),
                    ],
                  ),
                  child: const SizedBox.expand(
                    key: ValueKey<String>('wide_body'),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final hRect = tester.getRect(find.byType(AppPageHeader));
          final bRect = tester.getRect(
            find.byKey(const ValueKey<String>('wide_body')),
          );
          final ctaRect = tester.getRect(
            find.byKey(const ValueKey<String>('wide_cta')),
          );
          expect(hRect.right, closeTo(bRect.right, 0.5));
          expect(ctaRect.right, closeTo(hRect.right, 1.0));
        }
      },
    );
  });
}
