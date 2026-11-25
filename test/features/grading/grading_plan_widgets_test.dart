import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/core/theme/app_theme.dart';
import 'package:checklist_student/features/grading/domain/entities/assignment.dart';
import 'package:checklist_student/features/grading/domain/entities/grading_scale_config.dart';
import 'package:checklist_student/features/grading/domain/entities/score_category.dart';
import 'package:checklist_student/features/grading/presentation/providers/plan_editor_controller.dart';
import 'package:checklist_student/features/grading/presentation/widgets/grading_plan_actions.dart';
import 'package:checklist_student/features/grading/presentation/widgets/grading_scale_editor_card.dart';
import 'package:checklist_student/features/grading/presentation/widgets/over_max_score_warning_dialog.dart';
import 'package:checklist_student/features/grading/presentation/widgets/score_category_section_card.dart';

void main() {
  final now = DateTime.utc(2026, 11, 25);

  Widget wrapThemed(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('Grading Plan Widgets & Safety Guardrails', () {
    testWidgets(
      'GradingScaleEditorCard switches 0-4 to A-F -> marks dirty, and catches duplicate minScore',
      (tester) async {
        var latestDirty = false;
        const initialConfig = GradingScaleConfig(
          subjectClassId: 'class-1',
          scaleType: GradingScaleType.scale0To4,
          rules: GradingScaleConfig.defaultZeroToFourRules,
          missingWorkThreshold: 3,
        );

        await tester.pumpWidget(
          wrapThemed(
            GradingScaleEditorCard(
              initialConfig: initialConfig,
              isSaving: false,
              onDirtyChanged: (dirty) => latestDirty = dirty,
              onSave: (_) async => true,
            ),
          ),
        );

        expect(latestDirty, isFalse);

        // Switch from 0-4 to A-F preset.
        await tester.tap(find.text('A-F'));
        await tester.pumpAndSettle();

        expect(latestDirty, isTrue);
        expect(find.widgetWithText(TextField, 'A'), findsOneWidget);
        expect(find.widgetWithText(TextField, 'B+'), findsOneWidget);

        // Enter duplicate minScore (80 into the second tier 'B+' which is 75).
        final minScoreFields = find.widgetWithText(
          TextField,
          'คะแนนขั้นต่ำ (>=)',
        );
        await tester.enterText(minScoreFields.at(1), '80');
        await tester.pumpAndSettle();

        expect(
          find.text('พบคะแนนขั้นต่ำซ้ำกันในเกณฑ์ตัดเกรด กรุณาตรวจสอบอีกครั้ง'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'OverMaxScoreWarningDialog shows affected count & students and returns false/true',
      (tester) async {
        bool? dialogResult;
        const affected = <OverMaxScoreDetail>[
          OverMaxScoreDetail(
            enrollmentId: 'enr-1',
            studentLabel: 'เลขที่ 1 เด็กชายสมชาย ใจดี',
            currentScore: 18.5,
          ),
          OverMaxScoreDetail(
            enrollmentId: 'enr-2',
            studentLabel: 'เลขที่ 2 เด็กหญิงสมหญิง รักเรียน',
            currentScore: 16.0,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      dialogResult = await OverMaxScoreWarningDialog.show(
                        context,
                        assignmentTitle: 'ใบงานที่ 1',
                        newMaxScore: 15,
                        affectedStudents: affected,
                      );
                    },
                    child: const Text('เปิดเตือน'),
                  ),
                ),
              ),
            ),
          ),
        );

        // Open and cancel -> false
        await tester.tap(find.text('เปิดเตือน'));
        await tester.pumpAndSettle();

        expect(find.textContaining('พบนักเรียน 2 คน'), findsOneWidget);
        expect(find.textContaining('เลขที่ 1 เด็กชายสมชาย ใจดี'), findsOneWidget);
        expect(find.text('ได้ 18.5 คะแนน'), findsOneWidget);

        await tester.tap(find.text('ยกเลิก'));
        await tester.pumpAndSettle();
        expect(dialogResult, isFalse);

        // Re-open and confirm -> true
        await tester.tap(find.text('เปิดเตือน'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ยืนยันลดคะแนนเต็ม'));
        await tester.pumpAndSettle();
        expect(dialogResult, isTrue);
      },
    );

    testWidgets(
      'Deleting a scored assignment requires TypedConfirmDialog matching assignment title',
      (tester) async {
        bool? confirmed;
        final assignment = Assignment(
          id: 'assign-1',
          teacherId: 'teacher-1',
          subjectClassId: 'class-1',
          title: 'สอบกลางภาค 1',
          maxScore: 20,
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      confirmed =
                          await GradingPlanActions.confirmAssignmentDeletion(
                            context,
                            assignment: assignment,
                            scoredCount: 14,
                          );
                    },
                    child: const Text('ลบชิ้นงาน'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('ลบชิ้นงาน'));
        await tester.pumpAndSettle();

        expect(find.textContaining('14 คน'), findsOneWidget);

        // Confirm button starts disabled until exact title is typed.
        final confirmButtonFinder = find.widgetWithText(
          FilledButton,
          'ลบชิ้นงานและคะแนนถาวร',
        );
        expect(
          tester.widget<FilledButton>(confirmButtonFinder).onPressed,
          isNull,
        );

        // Wrong text keeps it disabled.
        await tester.enterText(find.byType(TextField), 'สอบกลางภาค');
        await tester.pumpAndSettle();
        expect(
          tester.widget<FilledButton>(confirmButtonFinder).onPressed,
          isNull,
        );

        // Exact title enables button and confirms deletion.
        await tester.enterText(find.byType(TextField), 'สอบกลางภาค 1');
        await tester.pumpAndSettle();
        expect(
          tester.widget<FilledButton>(confirmButtonFinder).onPressed,
          isNotNull,
        );

        await tester.tap(confirmButtonFinder);
        await tester.pumpAndSettle();
        expect(confirmed, isTrue);
      },
    );

    testWidgets(
      'ScoreCategorySectionCard highlights over-max count and fits cleanly on 390px viewport',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final category = ScoreCategory(
          id: 'cat-1',
          teacherId: 'teacher-1',
          subjectClassId: 'class-1',
          name: 'คะแนนเก็บระหว่างภาค',
          targetMaxScore: 60,
          createdAt: now,
          updatedAt: now,
        );
        final assignments = <Assignment>[
          Assignment(
            id: 'a-1',
            teacherId: 'teacher-1',
            subjectClassId: 'class-1',
            categoryId: 'cat-1',
            title: 'โครงงานกลุ่มบทที่ 1',
            maxScore: 15.5,
            isMandatory: true,
            dueDate: DateTime(2026, 11, 25),
            createdAt: now,
            updatedAt: now,
          ),
          Assignment(
            id: 'a-2',
            teacherId: 'teacher-1',
            subjectClassId: 'class-1',
            categoryId: 'cat-1',
            title: 'แบบฝึกหัดท้ายบท',
            maxScore: 10,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        await tester.pumpWidget(
          wrapThemed(
            Padding(
              padding: const EdgeInsets.all(12),
              child: ScoreCategorySectionCard(
                category: category,
                assignments: assignments,
                overMaxCounts: const <String, int>{'a-1': 3},
                isBusy: false,
                onAddAssignment: () {},
                onEditCategory: () {},
                onDeleteCategory: () {},
                onEditAssignment: (_) {},
                onDeleteAssignment: (_) {},
              ),
            ),
          ),
        );

        expect(find.text('คะแนนเก็บระหว่างภาค'), findsOneWidget);
        expect(
          find.textContaining('รวม 25.5 / เป้าหมาย 60 คะแนน'),
          findsOneWidget,
        );
        expect(find.text('บังคับส่ง'), findsOneWidget);
        expect(find.text('คะแนนเกินเต็ม 3 คน'), findsOneWidget);
        expect(find.textContaining('25 พ.ย. 2569'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
