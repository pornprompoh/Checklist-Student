import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/core/constants/attendance_status.dart';
import 'package:checklist_student/core/constants/submission_status.dart';
import 'package:checklist_student/features/attendance/domain/entities/attendance_record.dart';
import 'package:checklist_student/features/attendance/domain/entities/attendance_rule_config.dart';
import 'package:checklist_student/features/attendance/domain/entities/attendance_session.dart';
import 'package:checklist_student/features/export_reports/domain/entities/export_document_header.dart';
import 'package:checklist_student/features/export_reports/domain/entities/export_options.dart';
import 'package:checklist_student/features/export_reports/domain/entities/export_report_bundle.dart';
import 'package:checklist_student/features/export_reports/domain/entities/export_section.dart';
import 'package:checklist_student/features/export_reports/domain/services/excel_report_generator_service.dart';
import 'package:checklist_student/features/export_reports/domain/services/export_report_builder_service.dart';
import 'package:checklist_student/features/grading/domain/entities/assignment.dart';
import 'package:checklist_student/features/grading/domain/entities/grading_scale_config.dart';
import 'package:checklist_student/features/grading/domain/entities/score_category.dart';
import 'package:checklist_student/features/grading/domain/entities/student_score.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/class_enrollment.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/student_lifecycle_status.dart';

void main() {
  const builder = ExportReportBuilderService();
  const generator = ExcelReportGeneratorService();
  final now = DateTime.utc(2026, 11, 25);

  ExportReportBundle createSampleBundle({
    required Set<ExportSection> selectedSections,
  }) {
    final raw = ExportRawClassData(
      subjectClassId: 'class-1',
      enrollments: <ClassEnrollment>[
        ClassEnrollment(
          id: 'e1',
          teacherId: 'teacher-1',
          subjectClassId: 'class-1',
          homeroomStudentId: null,
          studentIdentityId: 'ident-1',
          studentCode: '67001',
          studentNumber: 1,
          prefix: 'ด.ช.',
          firstName: 'สมชาย',
          lastName: 'ใจดี',
          status: StudentLifecycleStatus.active,
          enrolledAt: DateTime(2026, 5, 16),
          transferredOutAt: null,
          specialGradeOverride: null,
          wasRResolved: false,
          wasMsResolved: false,
          resolvedGradeAt: null,
          version: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      attendanceSessions: <AttendanceSession>[
        AttendanceSession(
          id: 'sess-1',
          teacherId: 'teacher-1',
          subjectClassId: 'class-1',
          sessionDate: DateTime(2026, 5, 18),
          isLocked: true,
          note: '',
          version: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      attendanceRecords: <AttendanceRecord>[
        AttendanceRecord(
          id: 'rec-1',
          teacherId: 'teacher-1',
          sessionId: 'sess-1',
          enrollmentId: 'e1',
          status: AttendanceStatus.present,
          note: '',
          version: 1,
          updatedAt: now,
        ),
      ],
      attendanceRuleConfig: const AttendanceRuleConfig(
        subjectClassId: 'class-1',
        absentThresholdPct: 20,
        lateToAbsentRatio: null,
        countLeaveAsAbsent: false,
      ),
      scoreCategories: <ScoreCategory>[
        ScoreCategory(
          id: 'cat-1',
          teacherId: 'teacher-1',
          subjectClassId: 'class-1',
          name: 'คะแนนเก็บ',
          targetMaxScore: 50,
          sortOrder: 0,
          createdAt: now,
          updatedAt: now,
        ),
        ScoreCategory(
          id: 'cat-2',
          teacherId: 'teacher-1',
          subjectClassId: 'class-1',
          name: 'สอบปลายภาค',
          targetMaxScore: 50,
          sortOrder: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      assignments: <Assignment>[
        Assignment(
          id: 'a1',
          teacherId: 'teacher-1',
          subjectClassId: 'class-1',
          categoryId: 'cat-1',
          title: 'ใบงานที่ 1',
          maxScore: 50,
          sortOrder: 0,
          createdAt: now,
          updatedAt: now,
        ),
        Assignment(
          id: 'a2',
          teacherId: 'teacher-1',
          subjectClassId: 'class-1',
          categoryId: 'cat-2',
          title: 'สอบปลายภาค',
          maxScore: 50,
          sortOrder: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      studentScores: <StudentScore>[
        StudentScore(
          id: 's1',
          teacherId: 'teacher-1',
          assignmentId: 'a1',
          enrollmentId: 'e1',
          submissionStatus: SubmissionStatus.submitted,
          score: 40.50,
          updatedAt: now,
        ),
        StudentScore(
          id: 's2',
          teacherId: 'teacher-1',
          assignmentId: 'a2',
          enrollmentId: 'e1',
          submissionStatus: SubmissionStatus.submitted,
          score: 39.49,
          updatedAt: now,
        ),
      ],
      gradingScaleConfig: const GradingScaleConfig(
        subjectClassId: 'class-1',
        scaleType: GradingScaleType.scale0To4,
        rules: GradingScaleConfig.defaultZeroToFourRules,
        missingWorkThreshold: 3,
      ),
    );

    final header = ExportDocumentHeader(
      reportTitle: 'แบบบันทึกผลการเรียน ปพ.5',
      schoolName: 'โรงเรียนสาธิตทดสอบ',
      department: 'กลุ่มสาระวิทยาศาสตร์',
      teacherName: 'ครูสมศรี ทดสอบ',
      academicYearBe: 2569,
      termLabel: '1',
      subjectCode: 'ว31101',
      subjectName: 'วิทยาศาสตร์',
      roomName: 'ม.4/1',
      exportedAt: DateTime(2026, 11, 25),
    );

    return builder.buildBundle(
      raw: raw,
      header: header,
      options: ExportOptions(selectedSections: selectedSections),
    );
  }

  group('ExcelReportGeneratorService', () {
    test(
      'generates all 4 sheets without default Sheet1 and preserves exact 79.99 DoubleCellValue -> grade 3.5',
      () {
        final bundle = createSampleBundle(
          selectedSections: ExportSection.values.toSet(),
        );
        final bytes = generator.generate(bundle);
        expect(bytes, isNotEmpty);

        final decoded = Excel.decodeBytes(bytes);
        expect(decoded.tables.containsKey('Sheet1'), isFalse);
        expect(decoded.tables.keys.toList(), <String>[
          'ใบรายชื่อ',
          'เวลาเรียน',
          'รายการงาน',
          'สรุปคะแนน-เกรด ปพ.5',
        ]);

        final summarySheet = decoded.tables['สรุปคะแนน-เกรด ปพ.5']!;
        // Row 0 contains school name in Thai
        expect(
          summarySheet.rows[0][0]?.value.toString(),
          contains('โรงเรียนสาธิตทดสอบ'),
        );
        // Student row is row 6 (0..3 header, 4 blank, 5 table header, 6 first student)
        // Columns: 0=no, 1=code, 2=name, 3=cat1(40.5), 4=cat2(39.49), 5=total(79.99), 6=grade('3.5')
        final totalCell = summarySheet.rows[6][5]?.value;
        expect(totalCell, isA<DoubleCellValue>());
        expect((totalCell! as DoubleCellValue).value, 79.99);
        expect(summarySheet.rows[6][6]?.value.toString(), '3.5');
      },
    );

    test('includes only selected sheets when subset of sections is chosen', () {
      final bundle = createSampleBundle(
        selectedSections: const <ExportSection>{
          ExportSection.roster,
          ExportSection.gradeSummary,
        },
      );
      final bytes = generator.generate(bundle);
      final decoded = Excel.decodeBytes(bytes);

      expect(decoded.tables.containsKey('Sheet1'), isFalse);
      expect(decoded.tables.keys.toList(), <String>[
        'ใบรายชื่อ',
        'สรุปคะแนน-เกรด ปพ.5',
      ]);
    });
  });
}
