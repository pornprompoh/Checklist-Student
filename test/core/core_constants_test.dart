import 'package:checklist_student/core/constants/app_routes.dart';
import 'package:checklist_student/core/constants/attendance_status.dart';
import 'package:checklist_student/core/constants/submission_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRoutes', () {
    test('builds student portal path with and without external browser flag', () {
      expect(
        AppRoutes.studentPortalPath('kru-somchai'),
        '/student/kru-somchai',
      );
      expect(
        AppRoutes.studentPortalPath('kru-somchai', openExternalBrowser: true),
        '/student/kru-somchai?openExternalBrowser=1',
      );
    });
  });

  group('AttendanceStatus', () {
    test('matches PostgreSQL attendance_records.status values', () {
      expect(AttendanceStatus.present.dbValue, 'present');
      expect(AttendanceStatus.late.dbValue, 'late');
      expect(AttendanceStatus.leave.dbValue, 'leave');
      expect(AttendanceStatus.absent.dbValue, 'absent');

      for (final status in AttendanceStatus.values) {
        expect(AttendanceStatus.fromDbValue(status.dbValue), status);
      }
      expect(() => AttendanceStatus.fromDbValue('invalid'), throwsArgumentError);
    });
  });

  group('SubmissionStatus', () {
    test('matches PostgreSQL student_scores.submission_status values', () {
      expect(SubmissionStatus.submitted.dbValue, 'submitted');
      expect(SubmissionStatus.late.dbValue, 'late');
      expect(SubmissionStatus.missing.dbValue, 'missing');

      for (final status in SubmissionStatus.values) {
        expect(SubmissionStatus.fromDbValue(status.dbValue), status);
      }
      expect(() => SubmissionStatus.fromDbValue('unknown'), throwsArgumentError);
    });
  });
}
