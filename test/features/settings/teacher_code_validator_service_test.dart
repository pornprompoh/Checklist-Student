import 'package:checklist_student/features/settings/domain/services/teacher_code_validator_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TeacherCodeValidatorService', () {
    test('normalizes whitespace and uppercase characters', () {
      expect(
        TeacherCodeValidatorService.normalize('  Kru-Somchai-01  '),
        'kru-somchai-01',
      );
      expect(TeacherCodeValidatorService.normalize('T-8492'), 't-8492');
    });

    test('accepts valid codes matching ^[a-z0-9-]{3,30}\$', () {
      expect(TeacherCodeValidatorService.validate('t-8492'), isNull);
      expect(TeacherCodeValidatorService.validate('kru-somchai-01'), isNull);
      expect(TeacherCodeValidatorService.validate('  ABC-123  '), isNull);
      expect(TeacherCodeValidatorService.validate('abc'), isNull);
      expect(
        TeacherCodeValidatorService.validate('a' * 30),
        isNull,
      );
    });

    test('rejects empty, too short, and too long codes', () {
      expect(TeacherCodeValidatorService.validate(''), isNotNull);
      expect(TeacherCodeValidatorService.validate('   '), isNotNull);
      expect(TeacherCodeValidatorService.validate('ab'), isNotNull);
      expect(TeacherCodeValidatorService.validate('a' * 31), isNotNull);
    });

    test('rejects Thai characters, spaces, underscores, and symbols', () {
      expect(TeacherCodeValidatorService.validate('ครูสมชาย'), isNotNull);
      expect(TeacherCodeValidatorService.validate('kru_somchai'), isNotNull);
      expect(TeacherCodeValidatorService.validate('kru@school'), isNotNull);
      expect(TeacherCodeValidatorService.validate('kru somchai'), isNotNull);
    });
  });
}
