import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/features/audit_log/domain/entities/audit_log_target_type.dart';
import 'package:checklist_student/features/audit_log/domain/entities/score_audit_log_entry.dart';
import 'package:checklist_student/features/audit_log/domain/services/audit_log_export_service.dart';

void main() {
  const service = AuditLogExportService();

  final sampleEntries = <ScoreAuditLogEntry>[
    ScoreAuditLogEntry(
      id: 'log-1',
      teacherId: 'teacher-1',
      academicYearId: 'year-2569',
      targetType: AuditLogTargetType.score,
      studentScoreId: 'score-1',
      enrollmentId: 'enr-1',
      oldValue: null,
      newValue: '8.50',
      isInitialEntry: true,
      changedAt: DateTime.utc(2026, 11, 25, 7, 30),
      yearBe: 2569,
      subjectClassId: 'class-1',
      subjectCode: 'ค31101',
      subjectName: 'คณิตศาสตร์, พื้นฐาน',
      roomName: 'ม.4/1',
      studentNumber: 1,
      studentCode: '67001',
      studentFullName: 'ด.ช.สมชาย "เก่ง" ใจดี',
      assignmentTitle: 'ใบงานที่ 1, บทที่ 1',
    ),
    ScoreAuditLogEntry(
      id: 'log-2',
      teacherId: 'teacher-1',
      academicYearId: 'year-2569',
      targetType: AuditLogTargetType.gradeStatus,
      studentScoreId: null,
      enrollmentId: 'enr-1',
      oldValue: 'ร',
      newValue: null,
      isInitialEntry: false,
      changedAt: DateTime.utc(2026, 11, 26, 8, 0),
      yearBe: 2569,
      subjectClassId: 'class-1',
      subjectCode: 'ค31101',
      subjectName: 'คณิตศาสตร์',
      roomName: 'ม.4/1',
      studentNumber: 1,
      studentCode: '67001',
      studentFullName: 'ด.ช.สมชาย ใจดี',
      assignmentTitle: null,
    ),
  ];

  group('AuditLogExportService', () {
    test('builds UTF-8 BOM CSV with RFC-4180 escaping and all Thai columns', () {
      final csv = service.buildCsvContent(sampleEntries);

      expect(csv.startsWith('\uFEFF'), isTrue);
      final lines = csv.trim().split('\n');
      expect(lines.length, 3); // header + 2 rows

      // Verify all 13 Thai headers exist
      for (final header in AuditLogExportService.csvHeaders) {
        expect(lines.first, contains(header));
      }

      // Verify commas and quotes are escaped per RFC-4180
      expect(lines[1], contains('"คณิตศาสตร์, พื้นฐาน"'));
      expect(lines[1], contains('"ด.ช.สมชาย ""เก่ง"" ใจดี"'));
      expect(lines[1], contains('"ใบงานที่ 1, บทที่ 1"'));
      expect(lines[1], contains('ยังไม่กรอก,8.50,ใช่'));

      // Verify grade_status row handles null student_score_id & newValue
      expect(lines[2], contains('สถานะ ร/มส,สถานะเกรดพิเศษ,ร,เกรดปกติ,ไม่ใช่'));
    });

    test('builds valid pretty-printed JSON with metadata and records', () {
      final exportedAt = DateTime.utc(2026, 11, 25, 12, 0);
      final jsonText = service.buildJsonContent(
        sampleEntries,
        yearBe: 2569,
        exportedAt: exportedAt,
      );

      final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
      expect(decoded['exported_at_iso'], exportedAt.toIso8601String());
      expect(decoded['year_be'], 2569);
      expect(decoded['total_records'], 2);

      final records = decoded['records'] as List<dynamic>;
      expect(records, hasLength(2));
      expect((records[0] as Map<String, dynamic>)['is_initial_entry'], isTrue);
      expect((records[1] as Map<String, dynamic>)['target_type'], 'grade_status');
    });

    test('builds clean filenames for specific year and all years', () {
      final refDate = DateTime(2026, 11, 25);
      expect(
        service.buildExportFileName(yearBe: 2569, extension: 'csv', now: refDate),
        'audit_log_BE2569_20261125.csv',
      );
      expect(
        service.buildExportFileName(yearBe: null, extension: '.json', now: refDate),
        'audit_log_all_20261125.json',
      );
    });
  });
}
