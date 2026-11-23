import 'package:checklist_student/core/utils/thai_date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThaiDateFormatter', () {
    test('converts between Christian Era and Buddhist Era years', () {
      expect(ThaiDateFormatter.toBuddhistYear(2026), 2569);
      expect(ThaiDateFormatter.toChristianYear(2569), 2026);
      expect(ThaiDateFormatter.toBuddhistYear(2000), 2543);
      expect(ThaiDateFormatter.toChristianYear(2543), 2000);
    });

    test('formats DateTime to zero-padded ISO date for PostgreSQL DATE', () {
      expect(ThaiDateFormatter.toIsoDate(DateTime(2026, 5, 4)), '2026-05-04');
      expect(
        ThaiDateFormatter.toIsoDate(DateTime(2026, 11, 23)),
        '2026-11-23',
      );
    });

    test('parses valid ISO dates and returns null for invalid inputs', () {
      expect(
        ThaiDateFormatter.parseIsoDate('2026-05-04'),
        DateTime(2026, 5, 4),
      );
      expect(
        ThaiDateFormatter.parseIsoDate('  2026-11-23  '),
        DateTime(2026, 11, 23),
      );
      expect(ThaiDateFormatter.parseIsoDate(null), isNull);
      expect(ThaiDateFormatter.parseIsoDate(''), isNull);
      expect(ThaiDateFormatter.parseIsoDate('23/11/2569'), isNull);
      expect(ThaiDateFormatter.parseIsoDate('2026-5-4'), isNull);
      expect(ThaiDateFormatter.parseIsoDate('2026-02-30'), isNull);
      expect(ThaiDateFormatter.parseIsoDate('2026-13-01'), isNull);
    });

    test('formats short, full, and numeric Thai Buddhist Era dates', () {
      final date = DateTime(2026, 11, 23);
      expect(ThaiDateFormatter.formatShortDate(date), '23 พ.ย. 2569');
      expect(ThaiDateFormatter.formatFullDate(date), '23 พฤศจิกายน 2569');
      expect(ThaiDateFormatter.formatNumericDate(date), '23/11/2569');

      final singleDigitDate = DateTime(2026, 5, 4);
      expect(ThaiDateFormatter.formatShortDate(singleDigitDate), '4 พ.ค. 2569');
      expect(
        ThaiDateFormatter.formatFullDate(singleDigitDate),
        '4 พฤษภาคม 2569',
      );
      expect(
        ThaiDateFormatter.formatNumericDate(singleDigitDate),
        '04/05/2569',
      );
    });

    test('formats DateTime in local time with Thai Buddhist Era date', () {
      final localDateTime = DateTime(2026, 11, 23, 14, 30);
      expect(
        ThaiDateFormatter.formatDateTime(localDateTime),
        '23 พ.ย. 2569 เวลา 14:30 น.',
      );

      final morning = DateTime(2026, 1, 5, 8, 5);
      expect(
        ThaiDateFormatter.formatDateTime(morning),
        '5 ม.ค. 2569 เวลา 08:05 น.',
      );

      final utcDateTime = DateTime.utc(2026, 11, 23, 7, 30);
      final expectedLocal = utcDateTime.toLocal();
      expect(
        ThaiDateFormatter.formatDateTime(utcDateTime),
        ThaiDateFormatter.formatDateTime(expectedLocal),
      );
    });

    test('formats Thai Buddhist Era date range', () {
      expect(
        ThaiDateFormatter.formatDateRange(
          DateTime(2026, 5, 16),
          DateTime(2026, 10, 10),
        ),
        '16 พ.ค. 2569 – 10 ต.ค. 2569',
      );
    });

    test('returns full and short Thai weekday names for ISO weekdays 1..7', () {
      expect(ThaiDateFormatter.weekdayThaiName(1), 'จันทร์');
      expect(ThaiDateFormatter.weekdayThaiName(1, short: true), 'จ.');
      expect(ThaiDateFormatter.weekdayThaiName(4), 'พฤหัสบดี');
      expect(ThaiDateFormatter.weekdayThaiName(4, short: true), 'พฤ.');
      expect(ThaiDateFormatter.weekdayThaiName(7), 'อาทิตย์');
      expect(ThaiDateFormatter.weekdayThaiName(7, short: true), 'อา.');

      expect(() => ThaiDateFormatter.weekdayThaiName(0), throwsRangeError);
      expect(() => ThaiDateFormatter.weekdayThaiName(8), throwsRangeError);
    });
  });
}
