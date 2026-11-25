import 'package:checklist_student/core/theme/app_theme.dart';
import 'package:checklist_student/core/widgets/app_empty_state.dart';
import 'package:checklist_student/core/widgets/app_page_header.dart';
import 'package:checklist_student/core/widgets/app_surface_card.dart';
import 'package:checklist_student/core/widgets/class_workspace_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Step 8.1.1 — Shared UI Primitives', () {
    const testViewports = <Size>[
      Size(320, 568),
      Size(390, 844),
      Size(1280, 800),
    ];

    testWidgets(
      'AppPageHeader renders title, subtitle and wrapping actions cleanly from 320px to 1280px',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        var primaryTapped = false;

        for (final size in testViewports) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: AppPageHeader(
                    title: 'หน้าหลักครูผู้สอน รายวิชาวิทยาการคำนวณ ม.4',
                    subtitle: 'วันพุธที่ 25 พ.ย. 2569 · ภาคเรียนที่ 1/2569',
                    leading: const Icon(Icons.school_rounded),
                    actions: [
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('รีเฟรชข้อมูล'),
                      ),
                      FilledButton.icon(
                        onPressed: () => primaryTapped = true,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('เพิ่มวิชาและห้องเรียน'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('เพิ่มวิชาและห้องเรียน'), findsOneWidget);
          expect(tester.takeException(), isNull, reason: 'Overflow at $size');
        }

        await tester.tap(find.text('เพิ่มวิชาและห้องเรียน'));
        await tester.pumpAndSettle();
        expect(primaryTapped, isTrue);
      },
    );

    testWidgets(
      'AppSurfaceCard & AppEmptyState render cleanly in Light and Dark modes without overflow',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        var actionTapped = 0;

        for (final theme in <ThemeData>[AppTheme.light, AppTheme.dark]) {
          for (final size in testViewports) {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1.0;

            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                home: Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSurfaceCard(
                          title: 'สรุปห้องเรียนประจำภาคเรียน',
                          subtitle: 'แสดงข้อมูลล่าสุดจากฐานข้อมูล',
                          trailing: const Chip(label: Text('2 ห้อง')),
                          child: const Text('เนื้อหาการ์ดมาตรฐาน'),
                        ),
                        const SizedBox(height: 16),
                        AppEmptyState(
                          icon: Icons.class_outlined,
                          title: 'ยังไม่มีห้องเรียนในเทอมนี้',
                          description:
                              'เพิ่มรายวิชาและห้องเรียนเพื่อเริ่มเช็คชื่อและตัดเกรดได้ทันที',
                          actionLabel: 'เพิ่มรายวิชา',
                          onAction: () => actionTapped++,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(find.text('ยังไม่มีห้องเรียนในเทอมนี้'), findsOneWidget);
            expect(find.text('เพิ่มรายวิชา'), findsOneWidget);
            expect(
              tester.takeException(),
              isNull,
              reason: 'Overflow at $size (${theme.brightness})',
            );
          }
        }

        await tester.tap(find.text('เพิ่มรายวิชา'));
        await tester.pumpAndSettle();
        expect(actionTapped, 1);
      },
    );

    testWidgets(
      'ClassWorkspaceBar switches across all 4 tabs and scrolls cleanly at 320px',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        ClassWorkspaceTab? selected;

        for (final size in testViewports) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: AppTheme.light,
                home: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClassWorkspaceBar(
                      subjectClassId: 'class-1',
                      activeTab: ClassWorkspaceTab.attendance,
                      onSelectTab: (tab) => selected = tab,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('เช็คชื่อ'), findsOneWidget);
          expect(find.text('ตารางคะแนน'), findsOneWidget);
          expect(find.text('แผนเก็บงาน'), findsOneWidget);
          expect(find.text('ส่งออกรายงาน'), findsOneWidget);
          expect(tester.takeException(), isNull, reason: 'Overflow at $size');
        }

        await tester.tap(find.text('ตารางคะแนน'));
        await tester.pumpAndSettle();
        expect(selected, ClassWorkspaceTab.grading);

        await tester.tap(find.text('ส่งออกรายงาน'));
        await tester.pumpAndSettle();
        expect(selected, ClassWorkspaceTab.export);
      },
    );
  });
}
