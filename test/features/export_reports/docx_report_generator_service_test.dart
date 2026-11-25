import 'dart:convert';

import 'package:archive/archive.dart';
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
import 'package:checklist_student/features/export_reports/domain/services/docx_report_generator_service.dart';
import 'package:checklist_student/features/export_reports/domain/services/export_report_builder_service.dart';
import 'package:checklist_student/features/grading/domain/entities/assignment.dart';
import 'package:checklist_student/features/grading/domain/entities/grading_scale_config.dart';
import 'package:checklist_student/features/grading/domain/entities/score_category.dart';
import 'package:checklist_student/features/grading/domain/entities/student_score.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/class_enrollment.dart';
import 'package:checklist_student/features/homeroom_roster/domain/entities/student_lifecycle_status.dart';

void main() {
  const builder = ExportReportBuilderService();
  const generator = DocxReportGeneratorService();
  final now = DateTime.utc(2026, 11, 25);

  String readArchiveXml(Archive archive, String path) {
    final file = archive.findFile(path);
    expect(file, isNotNull, reason: 'Missing OOXML part: $path');
    return utf8.decode(file!.content as List<int>);
  }

  ExportReportBundle buildBundle({
    int studentCount = 3,
    int sessionCount = 4,
    int assignmentCount = 3,
    ExportOrientationMode orientationMode = ExportOrientationMode.auto,
    Set<ExportSection>? sections,
    bool includeSignatureLines = true,
    bool includeTeacherResolvedBadges = false,
    String? customSchoolName,
    String? customFirstAssignmentTitle,
    double? firstStudentTotalOverride,
    bool markFirstStudentResolved = false,
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
        firstName: i == 0 ? 'สมชาย' : 'กิตติ',
        lastName: 'ลำดับที่ ${i + 1}',
        status: StudentLifecycleStatus.active,
        enrolledAt: DateTime(2026, 5, 16),
        transferredOutAt: null,
        specialGradeOverride: null,
        wasRResolved: i == 0 && markFirstStudentResolved,
        wasMsResolved: false,
        resolvedGradeAt: (i == 0 && markFirstStudentResolved) ? now : null,
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
        categoryId: i == assignmentCount - 1 ? 'cat-2' : 'cat-1',
        title: (i == 0 && customFirstAssignmentTitle != null)
            ? customFirstAssignmentTitle
            : 'ชิ้นงานที่ ${i + 1}',
        maxScore: (firstStudentTotalOverride != null && i == 0) ? 100 : 10,
        isMandatory: i == 0,
        sortOrder: i,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final scores = <StudentScore>[
      for (final s in students)
        for (var j = 0; j < assignments.length; j++)
          StudentScore(
            id: 'sc-${s.id}-${assignments[j].id}',
            teacherId: 'teacher-1',
            assignmentId: assignments[j].id,
            enrollmentId: s.id,
            submissionStatus: SubmissionStatus.submitted,
            score: (s.id == 'e-0' && firstStudentTotalOverride != null)
                ? (j == 0 ? firstStudentTotalOverride : 0)
                : 7.75,
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
        schoolName: customSchoolName ?? 'โรงเรียนสาธิตทดสอบ',
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
        selectedSections: sections ?? ExportSection.values.toSet(),
        orientationMode: orientationMode,
        includeSignatureLines: includeSignatureLines,
        includeTeacherResolvedBadges: includeTeacherResolvedBadges,
      ),
    );
  }

  group('DocxReportGeneratorService', () {
    test('produces valid 6-part OOXML ZIP with UTF-8 Thai text', () {
      final bundle = buildBundle();
      final bytes = generator.generate(bundle);
      expect(bytes.length, greaterThan(1500));

      final archive = ZipDecoder().decodeBytes(bytes);
      final partNames = archive.files.map((f) => f.name).toSet();
      expect(
        partNames,
        containsAll(<String>[
          '[Content_Types].xml',
          '_rels/.rels',
          'word/_rels/document.xml.rels',
          'word/styles.xml',
          'word/footer1.xml',
          'word/document.xml',
        ]),
      );

      final documentXml = readArchiveXml(archive, 'word/document.xml');
      final footerXml = readArchiveXml(archive, 'word/footer1.xml');
      expect(documentXml, contains('โรงเรียนสาธิตทดสอบ'));
      expect(documentXml, contains('สมชาย'));
      expect(footerXml, contains('PAGE'));
      expect(footerXml, contains('NUMPAGES'));
    });

    test(
      'applies TH Sarabun New + w:szCs + repeating headers + cantSplit + signature lines',
      () {
        final bundle = buildBundle(includeSignatureLines: true);
        final archive = ZipDecoder().decodeBytes(generator.generate(bundle));
        final stylesXml = readArchiveXml(archive, 'word/styles.xml');
        final docXml = readArchiveXml(archive, 'word/document.xml');

        expect(stylesXml, contains('TH Sarabun New'));
        expect(stylesXml, contains('w:szCs w:val="32"'));
        expect(stylesXml, contains('w:bidi="th-TH"'));

        expect(docXml, contains('TH Sarabun New'));
        expect(docXml, contains('w:szCs'));
        expect(docXml, contains('<w:tblHeader/>'));
        expect(docXml, contains('<w:cantSplit/>'));
        expect(docXml, contains('ครูผู้สอน'));
        expect(docXml, contains('หัวหน้ากลุ่มสาระการเรียนรู้'));
        expect(docXml, contains('ผู้อำนวยการสถานศึกษา'));
      },
    );

    test('sets A4 Portrait vs Landscape w:pgSz accurately', () {
      final portraitBundle = buildBundle(
        orientationMode: ExportOrientationMode.portrait,
      );
      final landscapeBundle = buildBundle(
        orientationMode: ExportOrientationMode.landscape,
      );

      final portraitDoc = readArchiveXml(
        ZipDecoder().decodeBytes(generator.generate(portraitBundle)),
        'word/document.xml',
      );
      final landscapeDoc = readArchiveXml(
        ZipDecoder().decodeBytes(generator.generate(landscapeBundle)),
        'word/document.xml',
      );

      expect(portraitDoc, contains('<w:pgSz w:w="11906" w:h="16838"/>'));
      expect(portraitDoc, isNot(contains('w:orient="landscape"')));
      expect(
        landscapeDoc,
        contains('<w:pgSz w:w="16838" w:h="11906" w:orient="landscape"/>'),
      );
    });

    test(
      'preserves exact decimal 79.99 -> grade 3.5 and hides teacher-only resolved badge by default',
      () {
        final bundle = buildBundle(
          studentCount: 2,
          assignmentCount: 2,
          firstStudentTotalOverride: 79.99,
          markFirstStudentResolved: true,
          includeTeacherResolvedBadges: false,
          sections: const <ExportSection>{ExportSection.gradeSummary},
        );
        final docXml = readArchiveXml(
          ZipDecoder().decodeBytes(generator.generate(bundle)),
          'word/document.xml',
        );

        expect(docXml, contains('>79.99<'));
        expect(docXml, contains('>3.5<'));
        expect(docXml, isNot(contains('เคยแก้')));
        expect(docXml, contains('สรุปแจกแจงระดับผลการเรียน'));
      },
    );

    test('escapes XML special characters (< > & " \') safely', () {
      final bundle = buildBundle(
        customSchoolName: 'โรงเรียน A & B <สาธิต> "รุ่น \'69"',
        customFirstAssignmentTitle: 'ใบงาน <1> & "2" \'ทดลอง\'',
      );
      final docXml = readArchiveXml(
        ZipDecoder().decodeBytes(generator.generate(bundle)),
        'word/document.xml',
      );

      expect(
        docXml,
        contains(
          'โรงเรียน A &amp; B &lt;สาธิต&gt; &quot;รุ่น &apos;69&quot;',
        ),
      );
      expect(
        docXml,
        contains('ใบงาน &lt;1&gt; &amp; &quot;2&quot; &apos;ทดลอง&apos;'),
      );
      expect(docXml, isNot(contains('<สาธิต>')));
      expect(docXml, isNot(contains('<1>')));
    });

    test(
      'Stress Case: 45 students x 18 sessions x 12 assignments auto-chunks with ชุดที่ 2 and respects section subset',
      () {
        final stressBundle = buildBundle(
          studentCount: 45,
          sessionCount: 18,
          assignmentCount: 12,
          orientationMode: ExportOrientationMode.auto,
        );
        expect(
          stressBundle.orientationDecision.orientation,
          ExportPageOrientation.landscape,
        );

        final stressDoc = readArchiveXml(
          ZipDecoder().decodeBytes(generator.generate(stressBundle)),
          'word/document.xml',
        );
        expect(stressDoc, contains('ชุดที่ 1:'));
        expect(stressDoc, contains('ชุดที่ 2:'));
        expect(stressDoc, contains('ลำดับที่ 45'));
        expect(stressDoc, contains('w:orient="landscape"'));

        final rosterOnlyBundle = buildBundle(
          sections: const <ExportSection>{ExportSection.roster},
          includeSignatureLines: false,
        );
        final rosterDoc = readArchiveXml(
          ZipDecoder().decodeBytes(generator.generate(rosterOnlyBundle)),
          'word/document.xml',
        );
        expect(rosterDoc, contains('ใบรายชื่อนักเรียน'));
        expect(rosterDoc, isNot(contains('สรุปคะแนนและผลการเรียน (ปพ.5)')));
        expect(rosterDoc, isNot(contains('ผู้อำนวยการสถานศึกษา')));
      },
    );
  });
}
