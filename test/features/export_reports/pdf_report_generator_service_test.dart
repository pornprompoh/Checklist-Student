import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/core/constants/attendance_status.dart';
import 'package:checklist_student/core/constants/submission_status.dart';
import 'package:checklist_student/features/attendance/domain/entities/attendance_record.dart';
import 'package:checklist_student/features/attendance/domain/entities/attendance_rule_config.dart';
import 'package:checklist_student/features/attendance/domain/entities/attendance_session.dart';
import 'package:checklist_student/features/export_reports/domain/entities/export_document_header.dart';
import 'package:checklist_student/features/export_reports/domain/entities/export_options.dart';
import 'package:checklist_student/features/export_reports/domain/entities/export_orientation.dart';
import 'package:checklist_student/features/export_reports/domain/entities/export_report_bundle.dart';
import 'package:checklist_student/features/export_reports/domain/entities/export_section.dart';
import 'package:checklist_student/features/export_reports/domain/services/export_report_builder_service.dart';
import 'package:checklist_student/features/export_reports/domain/services/pdf_report_generator_service.dart';
import 'package:checklist_student/features/grading/domain/entities/assignment.dart';
import 'package:checklist_student/features/grading/domain/entities/grading_scale_config.dart';
import 'package:checklist_student/features/grading/domain/entities/score_category.dart';
import 'package:checklist_student/features/grading/domain/entities/student_score.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/class_enrollment.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/student_lifecycle_status.dart';

void main() {
  const builder = ExportReportBuilderService();
  const pdfGenerator = PdfReportGeneratorService();
  final now = DateTime.utc(2026, 11, 25);

  late Uint8List regularFont;
  late Uint8List boldFont;

  setUpAll(() {
    regularFont = File('assets/fonts/Sarabun-Regular.ttf').readAsBytesSync();
    boldFont = File('assets/fonts/Sarabun-Bold.ttf').readAsBytesSync();
  });

  ExportReportBundle buildBundle({
    required int studentCount,
    required int sessionCount,
    required int assignmentCount,
    required ExportOrientationMode orientationMode,
  }) {
    final students = List<ClassEnrollment>.generate(
      studentCount,
      (i) => ClassEnrollment(
        id: 'e-$i',
        teacherId: 'teacher-1',
        subjectClassId: 'class-1',
        homeroomStudentId: null,
        studentIdentityId: 'ident-$i',
        studentCode: '67${(i + 1).toString().padLeft(3, '0')}',
        studentNumber: i + 1,
        prefix: 'ด.ช.',
        firstName: 'สมชาย',
        lastName: 'ลำดับที่ ${i + 1}',
        status: StudentLifecycleStatus.active,
        enrolledAt: DateTime(2026, 5, 16),
        transferredOutAt: null,
        specialGradeOverride: i == 0 ? 'ร' : null,
        wasRResolved: false,
        wasMsResolved: false,
        resolvedGradeAt: null,
        version: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final sessions = List<AttendanceSession>.generate(
      sessionCount,
      (i) => AttendanceSession(
        id: 'sess-$i',
        teacherId: 'teacher-1',
        subjectClassId: 'class-1',
        sessionDate: DateTime(2026, 5, 16).add(Duration(days: i * 2)),
        isLocked: true,
        note: '',
        version: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final records = <AttendanceRecord>[
      for (final s in students)
        for (var j = 0; j < sessions.length; j++)
          AttendanceRecord(
            id: 'rec-${s.id}-$j',
            teacherId: 'teacher-1',
            sessionId: sessions[j].id,
            enrollmentId: s.id,
            status: j % 7 == 0
                ? AttendanceStatus.absent
                : AttendanceStatus.present,
            note: '',
            version: 1,
            updatedAt: now,
          ),
    ];

    final categories = <ScoreCategory>[
      ScoreCategory(
        id: 'cat-1',
        teacherId: 'teacher-1',
        subjectClassId: 'class-1',
        name: 'คะแนนเก็บ',
        targetMaxScore: 60,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      ),
      ScoreCategory(
        id: 'cat-2',
        teacherId: 'teacher-1',
        subjectClassId: 'class-1',
        name: 'ปลายภาค',
        targetMaxScore: 40,
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final assignments = List<Assignment>.generate(
      assignmentCount,
      (i) => Assignment(
        id: 'a-$i',
        teacherId: 'teacher-1',
        subjectClassId: 'class-1',
        categoryId: i < assignmentCount - 1 ? 'cat-1' : 'cat-2',
        title: 'ชิ้นงานที่ ${i + 1}',
        maxScore: 10,
        isMandatory: i == 0,
        sortOrder: i,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final scores = <StudentScore>[
      for (final s in students)
        for (final a in assignments)
          StudentScore(
            id: 'sc-${s.id}-${a.id}',
            teacherId: 'teacher-1',
            assignmentId: a.id,
            enrollmentId: s.id,
            submissionStatus: SubmissionStatus.submitted,
            score: 7.75,
            updatedAt: now,
          ),
    ];

    return builder.buildBundle(
      raw: ExportRawClassData(
        subjectClassId: 'class-1',
        enrollments: students,
        attendanceSessions: sessions,
        attendanceRecords: records,
        attendanceRuleConfig: const AttendanceRuleConfig(
          subjectClassId: 'class-1',
          absentThresholdPct: 20,
          lateToAbsentRatio: null,
          countLeaveAsAbsent: false,
        ),
        scoreCategories: categories,
        assignments: assignments,
        studentScores: scores,
        gradingScaleConfig: const GradingScaleConfig(
          subjectClassId: 'class-1',
          scaleType: GradingScaleType.scale0To4,
          rules: GradingScaleConfig.defaultZeroToFourRules,
          missingWorkThreshold: 3,
        ),
      ),
      header: ExportDocumentHeader(
        reportTitle: 'แบบบันทึกผลการพัฒนาคุณภาพผู้เรียน (ปพ.5)',
        schoolName: 'โรงเรียนสาธิตทดสอบ',
        department: 'กลุ่มสาระวิทยาศาสตร์และเทคโนโลยี',
        teacherName: 'ครูสมศรี ทดสอบ',
        academicYearBe: 2569,
        termLabel: '1',
        subjectCode: 'ว31101',
        subjectName: 'วิทยาศาสตร์พื้นฐาน',
        roomName: 'ม.4/1',
        exportedAt: DateTime(2026, 11, 25),
      ),
      options: ExportOptions(
        selectedSections: ExportSection.values.toSet(),
        orientationMode: orientationMode,
        includeSignatureLines: true,
      ),
    );
  }

  group('PdfReportGeneratorService (Sarabun)', () {
    test('generates valid Thai PDF in Portrait and Landscape modes', () async {
      for (final mode in const <ExportOrientationMode>[
        ExportOrientationMode.portrait,
        ExportOrientationMode.landscape,
      ]) {
        final bundle = buildBundle(
          studentCount: 5,
          sessionCount: 4,
          assignmentCount: 3,
          orientationMode: mode,
        );
        final bytes = await pdfGenerator.generate(
          bundle,
          regularFontBytes: regularFont,
          boldFontBytes: boldFont,
        );

        expect(bytes.length, greaterThan(2000));
        expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
      }
    });

    test(
      'handles Stress Case: 45 students x 18 attendance sessions x 12 assignments cleanly',
      () async {
        final bundle = buildBundle(
          studentCount: 45,
          sessionCount: 18,
          assignmentCount: 12,
          orientationMode: ExportOrientationMode.auto,
        );
        expect(
          bundle.orientationDecision.orientation,
          ExportPageOrientation.landscape,
        );

        final bytes = await pdfGenerator.generate(
          bundle,
          regularFontBytes: regularFont,
          boldFontBytes: boldFont,
        );

        expect(bytes.length, greaterThan(10000));
        expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
      },
    );
  });
}
