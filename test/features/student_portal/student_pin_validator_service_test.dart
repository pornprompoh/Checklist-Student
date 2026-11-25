import 'package:checklist_student/features/student_portal/domain/services/student_pin_validator_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = StudentPinValidatorService();

  group('StudentPinValidatorService.validateStudentCode', () {
    test('accepts valid trimmed student codes up to 50 characters', () {
      expect(service.validateStudentCode('67001'), isNull);
      expect(service.validateStudentCode('  STD-2569-01  '), isNull);
      expect(service.validateStudentCode('a' * 50), isNull);
    });

    test('rejects blank or whitespace-only student codes', () {
      expect(service.validateStudentCode(''), isNotNull);
      expect(service.validateStudentCode('   '), isNotNull);
    });

    test('rejects student codes longer than 50 characters', () {
      expect(service.validateStudentCode('1' * 51), isNotNull);
    });
  });

  group('StudentPinValidatorService.validatePin', () {
    test('accepts strictly 6 ASCII digits', () {
      expect(service.validatePin('000000'), isNull);
      expect(service.validatePin('246810'), isNull);
      expect(service.validatePin('987654'), isNull);
    });

    test('rejects empty, too short, too long, or non-numeric PINs', () {
      expect(service.validatePin(''), isNotNull);
      expect(service.validatePin('12345'), isNotNull);
      expect(service.validatePin('1234567'), isNotNull);
      expect(service.validatePin('12ab56'), isNotNull);
      expect(service.validatePin('123 45'), isNotNull);
      expect(service.validatePin('๑๒๓๔๕๖'), isNotNull);
    });
  });

  group('StudentPinValidatorService.validatePinSetup', () {
    test('accepts matching 6-digit PINs', () {
      expect(
        service.validatePinSetup(pin: '246810', confirmPin: '246810'),
        isNull,
      );
    });

    test('rejects invalid primary PIN, empty confirmation, or mismatch', () {
      expect(
        service.validatePinSetup(pin: '12345', confirmPin: '12345'),
        isNotNull,
      );
      expect(
        service.validatePinSetup(pin: '246810', confirmPin: ''),
        isNotNull,
      );
      expect(
        service.validatePinSetup(pin: '246810', confirmPin: '246811'),
        contains('ไม่ตรงกัน'),
      );
    });
  });

  group('StudentPinValidatorService.formatLockoutRemainingThai', () {
    final now = DateTime.utc(2026, 11, 25, 10, 0, 0);

    test('formats minutes and seconds cleanly while locked', () {
      expect(
        service.formatLockoutRemainingThai(
          now.add(const Duration(minutes: 14, seconds: 30)),
          now: now,
        ),
        'เหลืออีก 14 นาที 30 วินาที',
      );
      expect(
        service.formatLockoutRemainingThai(
          now.add(const Duration(minutes: 5)),
          now: now,
        ),
        'เหลืออีก 5 นาที',
      );
      expect(
        service.formatLockoutRemainingThai(
          now.add(const Duration(seconds: 42)),
          now: now,
        ),
        'เหลืออีก 42 วินาที',
      );
    });

    test('returns expired message when lockout time has passed or reached 0', () {
      expect(
        service.formatLockoutRemainingThai(now, now: now),
        'หมดเวลาล็อกแล้ว กรุณาลองใหม่',
      );
      expect(
        service.formatLockoutRemainingThai(
          now.subtract(const Duration(seconds: 5)),
          now: now,
        ),
        'หมดเวลาล็อกแล้ว กรุณาลองใหม่',
      );
    });
  });
}
