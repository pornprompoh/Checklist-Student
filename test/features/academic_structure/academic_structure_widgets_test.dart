import 'package:checklist_student/core/theme/app_theme.dart';
import 'package:checklist_student/features/academic_structure/domain/entities/academic_year.dart';
import 'package:checklist_student/features/academic_structure/domain/entities/delete_impact_summary.dart';
import 'package:checklist_student/features/academic_structure/domain/entities/subject.dart';
import 'package:checklist_student/features/academic_structure/domain/entities/subject_class.dart';
import 'package:checklist_student/features/academic_structure/domain/entities/term.dart';
import 'package:checklist_student/features/academic_structure/domain/repositories/academic_structure_repository.dart';
import 'package:checklist_student/features/academic_structure/presentation/pages/academic_structure_page.dart';
import 'package:checklist_student/features/academic_structure/presentation/providers/academic_structure_providers.dart';
import 'package:checklist_student/features/academic_structure/presentation/widgets/structural_delete_helper.dart';
import 'package:checklist_student/features/academic_structure/presentation/widgets/subject_class_form_dialog.dart';
import 'package:checklist_student/features/academic_structure/presentation/widgets/term_form_dialog.dart';
import 'package:checklist_student/features/auth/domain/entities/auth_state.dart';
import 'package:checklist_student/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeAuthNotifier extends AuthStateNotifier {
  @override
  AuthSessionState build() =>
      const AuthSessionState.authenticated(userId: 'teacher-1');
}

class _FakeAcademicStructureRepository implements AcademicStructureRepository {
  _FakeAcademicStructureRepository({
    this.years = const <AcademicYear>[],
    this.terms = const <Term>[],
    this.subjects = const <Subject>[],
    this.classes = const <SubjectClass>[],
  });

  final List<AcademicYear> years;
  final List<Term> terms;
  final List<Subject> subjects;
  final List<SubjectClass> classes;

  @override
  Future<List<AcademicYear>> fetchAcademicYears() async => years;

  @override
  Future<List<Term>> fetchTerms({String? academicYearId}) async => terms;

  @override
  Future<List<Subject>> fetchSubjects(String termId) async => subjects;

  @override
  Future<List<SubjectClass>> fetchSubjectClassesByTerm(String termId) async =>
      classes;

  @override
  Future<DeleteImpactSummary> getDeleteImpactSummary({
    required StructuralEntityType entityType,
    required String entityId,
  }) async {
    return DeleteImpactSummary(
      entityType: entityType,
      entityId: entityId,
      termsCount: 1,
      homeroomsCount: 2,
      subjectsCount: 3,
      subjectClassesCount: 4,
      studentsCount: 42,
      attendanceSessionsCount: 12,
      assignmentsCount: 8,
      scoredAssignmentsCount: 5,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'SubjectClassFormDialog selects multiple teaching days [1, 3, 5] and pin toggle',
    (tester) async {
      SubjectClassFormResult? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await SubjectClassFormDialog.show(
                    context,
                    subjectLabel: 'ว31101 วิทยาการคำนวณ 1',
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'ชื่อห้องเรียน'),
        'ม.4/1',
      );
      await tester.tap(find.text('จ.'));
      await tester.tap(find.text('พ.'));
      await tester.tap(find.text('ศ.'));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.roomName, 'ม.4/1');
      expect(result!.teachingDays, <int>[1, 3, 5]);
      expect(result!.isPinned, isTrue);
    },
  );

  testWidgets('TermFormDialog validates that endDate is not before startDate', (
    tester,
  ) async {
    final ts = DateTime(2026, 1, 1);
    final year = AcademicYear(
      id: 'y-1',
      teacherId: 'teacher-1',
      yearBe: 2569,
      createdAt: ts,
      updatedAt: ts,
    );
    final invalidExistingTerm = Term(
      id: 't-1',
      teacherId: 'teacher-1',
      academicYearId: 'y-1',
      termLabel: '1',
      startDate: DateTime(2026, 10, 10),
      endDate: DateTime(2026, 5, 16),
      isPinnedActive: false,
      createdAt: ts,
      updatedAt: ts,
    );

    TermFormResult? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await TermFormDialog.show(
                  context,
                  academicYears: <AcademicYear>[year],
                  existingTerm: invalidExistingTerm,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();

    expect(find.text('วันสิ้นสุดเทอมต้องไม่ก่อนวันเริ่มต้นเทอม'), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets(
    'TermFormDialog creates a term with null dates by default when optional toggle is off',
    (tester) async {
      final ts = DateTime(2026, 1, 1);
      final year = AcademicYear(
        id: 'y-1',
        teacherId: 'teacher-1',
        yearBe: 2569,
        createdAt: ts,
        updatedAt: ts,
      );

      TermFormResult? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await TermFormDialog.show(
                    context,
                    academicYears: <AcademicYear>[year],
                  );
                },
                child: const Text('open-new-term'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open-new-term'));
      await tester.pumpAndSettle();

      // Optional date toggle defaults to OFF; date fields are hidden.
      expect(find.text('ระบุวันเปิด–ปิดเทอม (ไม่บังคับ)'), findsOneWidget);
      expect(find.text('วันเริ่มต้นเทอม'), findsNothing);

      await tester.tap(find.text('เทอม 2'));
      await tester.pump();
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.termLabel, '2');
      expect(result!.startDate, isNull);
      expect(result!.endDate, isNull);
    },
  );

  testWidgets(
    'TermFormDialog clears dates to null when editing a dated term and toggling switch off',
    (tester) async {
      final ts = DateTime(2026, 1, 1);
      final year = AcademicYear(
        id: 'y-1',
        teacherId: 'teacher-1',
        yearBe: 2569,
        createdAt: ts,
        updatedAt: ts,
      );
      final existingDatedTerm = Term(
        id: 't-1',
        teacherId: 'teacher-1',
        academicYearId: 'y-1',
        termLabel: '1',
        startDate: DateTime(2026, 5, 16),
        endDate: DateTime(2026, 10, 10),
        isPinnedActive: false,
        createdAt: ts,
        updatedAt: ts,
      );

      TermFormResult? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await TermFormDialog.show(
                    context,
                    academicYears: <AcademicYear>[year],
                    existingTerm: existingDatedTerm,
                  );
                },
                child: const Text('open-edit-term'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open-edit-term'));
      await tester.pumpAndSettle();

      // Existing dated term starts with date pickers visible.
      expect(find.text('วันเริ่มต้นเทอม'), findsOneWidget);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.text('วันเริ่มต้นเทอม'), findsNothing);

      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.startDate, isNull);
      expect(result!.endDate, isNull);
    },
  );

  testWidgets(
    'confirmAndDeleteStructure shows impact summary and unlocks delete only on exact typed text',
    (tester) async {
      var deleteInvoked = false;
      final fakeRepo = _FakeAcademicStructureRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(_FakeAuthNotifier.new),
            academicStructureRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Consumer(
              builder: (context, ref, child) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => confirmAndDeleteStructure(
                    context: context,
                    ref: ref,
                    entityType: StructuralEntityType.subject,
                    entityId: 'sub-1',
                    title: 'ยืนยันการลบรายวิชา ว31101',
                    description: 'ข้อมูลทั้งหมดของวิชานี้จะถูกลบ',
                    expectedText: 'ว31101',
                    onConfirmedDelete: () async {
                      deleteInvoked = true;
                      return true;
                    },
                  ),
                  child: const Text('delete-subject'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('delete-subject'));
      await tester.pumpAndSettle();

      expect(find.text('ยืนยันการลบรายวิชา ว31101'), findsOneWidget);
      expect(find.text('42 รายการ'), findsOneWidget);
      expect(find.text('5 รายการ'), findsOneWidget);

      final confirmButtonFinder = find.widgetWithText(
        FilledButton,
        'ยืนยันการลบ',
      );
      expect(tester.widget<FilledButton>(confirmButtonFinder).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'ว31102');
      await tester.pump();
      expect(tester.widget<FilledButton>(confirmButtonFinder).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'ว31101');
      await tester.pump();
      expect(
        tester.widget<FilledButton>(confirmButtonFinder).onPressed,
        isNotNull,
      );

      await tester.tap(confirmButtonFinder);
      await tester.pumpAndSettle();

      expect(deleteInvoked, isTrue);
    },
  );

  testWidgets(
    'AcademicStructurePage renders cleanly on 390px mobile viewport without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final ts = DateTime(2026, 5, 1);
      final fakeRepo = _FakeAcademicStructureRepository(
        years: <AcademicYear>[
          AcademicYear(
            id: 'y-1',
            teacherId: 'teacher-1',
            yearBe: 2569,
            createdAt: ts,
            updatedAt: ts,
          ),
        ],
        terms: <Term>[
          Term(
            id: 't-1',
            teacherId: 'teacher-1',
            academicYearId: 'y-1',
            termLabel: '1',
            startDate: DateTime(2026, 5, 16),
            endDate: DateTime(2026, 10, 10),
            isPinnedActive: true,
            createdAt: ts,
            updatedAt: ts,
          ),
        ],
        subjects: <Subject>[
          Subject(
            id: 's-1',
            teacherId: 'teacher-1',
            termId: 't-1',
            subjectCode: 'ว31101',
            subjectName: 'วิทยาการคำนวณ 1',
            createdAt: ts,
            updatedAt: ts,
          ),
        ],
        classes: <SubjectClass>[
          SubjectClass(
            id: 'sc-1',
            teacherId: 'teacher-1',
            subjectId: 's-1',
            homeroomId: null,
            roomName: 'ม.4/1',
            teachingDays: const <int>[1, 3, 5],
            isPinned: true,
            showScoreToStudent: true,
            showGradeToStudent: true,
            absentThresholdPct: 20,
            missingWorkThreshold: 3,
            lateToAbsentRatio: null,
            countLeaveAsAbsent: false,
            attendanceScoreWeight: null,
            gradingScaleType: '0-4',
            gradingRules: const <GradingRuleTier>[],
            createdAt: ts,
            updatedAt: ts,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(_FakeAuthNotifier.new),
            academicStructureRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: AcademicStructurePage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('เทอมปัจจุบัน (ปักหมุด)'), findsOneWidget);
      expect(find.text('ว31101'), findsOneWidget);
      expect(find.text('ม.4/1'), findsOneWidget);
      expect(find.text('จัดการห้องเรียน'), findsOneWidget);

      // Drill down from Subject Block into SubjectDetailView.
      await tester.ensureVisible(find.text('จัดการห้องเรียน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('จัดการห้องเรียน'));
      await tester.pumpAndSettle();

      expect(find.text('กลับไปรายวิชาทั้งหมด'), findsOneWidget);
      expect(find.text('ม.4/1'), findsOneWidget);
      expect(find.text('จ.'), findsOneWidget);
      expect(find.text('แผนเก็บงาน'), findsOneWidget);

      // Return to Subject Blocks Grid.
      await tester.ensureVisible(find.text('กลับไปรายวิชาทั้งหมด'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('กลับไปรายวิชาทั้งหมด'));
      await tester.pumpAndSettle();

      expect(find.text('จัดการห้องเรียน'), findsOneWidget);
    },
  );
}
