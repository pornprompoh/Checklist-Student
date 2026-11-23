import 'dart:async';

import 'package:checklist_student/core/errors/app_exception.dart';
import 'package:checklist_student/core/errors/thai_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  group('ThaiErrorMapper', () {
    test('returns existing AppException message unchanged', () {
      const exception = ValidationException('ข้อความผิดพลาดเฉพาะทาง');
      expect(ThaiErrorMapper.map(exception), 'ข้อความผิดพลาดเฉพาะทาง');
    });

    test('maps PostgrestException SQLSTATE codes to Thai messages', () {
      final duplicate = ThaiErrorMapper.toAppException(
        const supabase.PostgrestException(
          message: 'duplicate key value violates unique constraint',
          code: '23505',
        ),
      );
      expect(duplicate, isA<ValidationException>());
      expect(duplicate.message, contains('ซ้ำ'));

      final foreignKey = ThaiErrorMapper.toAppException(
        const supabase.PostgrestException(
          message: 'update or delete violates foreign key constraint',
          code: '23503',
        ),
      );
      expect(foreignKey, isA<ValidationException>());
      expect(foreignKey.message, contains('อ้างอิง'));

      final permission = ThaiErrorMapper.toAppException(
        const supabase.PostgrestException(
          message: 'new row violates row-level security policy',
          code: '42501',
        ),
      );
      expect(permission, isA<PermissionDeniedException>());
      expect(permission.message, contains('ไม่มีสิทธิ์'));
    });

    test('maps Student Portal RPC error codes', () {
      final notFound = ThaiErrorMapper.toAppException(
        const supabase.PostgrestException(message: 'TEACHER_NOT_FOUND'),
      );
      expect(notFound, isA<ValidationException>());
      expect(notFound.code, 'TEACHER_NOT_FOUND');

      final invalid = ThaiErrorMapper.toAppException(
        const supabase.PostgrestException(message: 'INVALID_CREDENTIALS'),
      );
      expect(invalid, isA<AuthException>());
      expect(invalid.code, 'INVALID_CREDENTIALS');

      final locked = ThaiErrorMapper.toAppException(
        const supabase.PostgrestException(message: 'LOCKED'),
      );
      expect(locked, isA<PermissionDeniedException>());
      expect(locked.code, 'LOCKED');
    });

    test('maps Supabase AuthException and TimeoutException', () {
      final expired = ThaiErrorMapper.toAppException(
        const supabase.AuthApiException(
          'JWT expired',
          statusCode: '401',
          code: 'session_expired',
        ),
      );
      expect(expired, isA<AuthException>());
      expect(expired.message, contains('เซสชันหมดอายุ'));

      final timeout = ThaiErrorMapper.toAppException(
        TimeoutException('Connection timed out'),
      );
      expect(timeout, isA<NetworkException>());
      expect(timeout.message, contains('อินเทอร์เน็ต'));
    });

    test('returns safe Thai fallback for unexpected errors', () {
      final mapped = ThaiErrorMapper.map(Exception('Raw internal crash 0xFF'));
      expect(mapped, 'เกิดข้อผิดพลาดที่ไม่คาดคิด กรุณาลองใหม่อีกครั้ง');
    });
  });
}
