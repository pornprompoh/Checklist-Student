import 'package:flutter_test/flutter_test.dart';

import 'package:checklist_student/core/utils/export_filename_builder.dart';

void main() {
  group('ExportFilenameBuilder', () {
    test('sanitizes forbidden OS characters while preserving Thai & dots', () {
      expect(ExportFilenameBuilder.sanitizeSegment('ม.4/1'), 'ม.4-1');
      expect(
        ExportFilenameBuilder.sanitizeSegment('  ว31101:วิทย์*ขั้นสูง?  '),
        'ว31101-วิทย์-ขั้นสูง',
      );
      expect(
        ExportFilenameBuilder.sanitizeSegment(r'ห้อง\4/2   "<test>"|ok'),
        'ห้อง-4-2-test-ok',
      );
      expect(
        ExportFilenameBuilder.sanitizeSegment('   ///   ', fallback: 'ห้อง'),
        'ห้อง',
      );
    });

    test('resolves concise Thai prefix from selected section keys', () {
      expect(
        ExportFilenameBuilder.resolveReportPrefix(const ['roster']),
        'ใบรายชื่อ',
      );
      expect(
        ExportFilenameBuilder.resolveReportPrefix(const ['attendance']),
        'เวลาเรียน',
      );
      expect(
        ExportFilenameBuilder.resolveReportPrefix(const ['assignments']),
        'รายการงาน',
      );
      expect(
        ExportFilenameBuilder.resolveReportPrefix(const ['gradeSummary']),
        'ปพ5',
      );
      expect(
        ExportFilenameBuilder.resolveReportPrefix(const [
          'roster',
          'gradeSummary',
        ]),
        'ปพ5',
      );
      expect(
        ExportFilenameBuilder.resolveReportPrefix(const [
          'roster',
          'attendance',
        ]),
        'รายงานรวม',
      );
    });

    test('builds standardized OS-safe filenames for xlsx, pdf, and docx', () {
      final refDate = DateTime(2026, 11, 25);

      expect(
        ExportFilenameBuilder.build(
          reportPrefix: 'ปพ5',
          subjectCode: 'ว31101',
          roomName: 'ม.4/1',
          termLabel: '1',
          yearBe: 2569,
          extension: '.PDF',
          exportedAt: refDate,
        ),
        'ปพ5_ว31101_ม.4-1_เทอม1-2569_20261125.pdf',
      );
      expect(
        ExportFilenameBuilder.build(
          reportPrefix: 'เวลาเรียน',
          subjectCode: 'ค31101',
          roomName: 'ม.5/2',
          termLabel: '2',
          yearBe: 2569,
          extension: 'xlsx',
          exportedAt: refDate,
        ),
        'เวลาเรียน_ค31101_ม.5-2_เทอม2-2569_20261125.xlsx',
      );
      expect(
        ExportFilenameBuilder.build(
          reportPrefix: 'ใบรายชื่อ',
          subjectCode: 'ท31101',
          roomName: 'ม.6/3',
          termLabel: '1',
          yearBe: 2569,
          extension: '.docx',
          exportedAt: refDate,
        ),
        'ใบรายชื่อ_ท31101_ม.6-3_เทอม1-2569_20261125.docx',
      );
    });
  });
}
