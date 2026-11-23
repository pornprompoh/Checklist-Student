import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'app_exception.dart';

/// Maps raw exceptions (Supabase, network, RPC, and unexpected errors) into
/// safe, user-friendly Thai [AppException] messages.
///
/// Never exposes raw English stack traces or internal database error codes
/// directly to end users.
abstract final class ThaiErrorMapper {
  static const String _fallbackMessage =
      'เกิดข้อผิดพลาดที่ไม่คาดคิด กรุณาลองใหม่อีกครั้ง';
  static const String _networkMessage =
      'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบเครือข่ายแล้วลองใหม่อีกครั้ง';

  /// Returns a Thai user-facing error message for [error].
  static String map(Object error) => toAppException(error).message;

  /// Converts [error] into a typed [AppException] with a Thai message.
  static AppException toAppException(Object error) {
    if (error is AppException) {
      return error;
    }

    if (error is TimeoutException) {
      return NetworkException(
        _networkMessage,
        code: 'TIMEOUT',
        cause: error,
      );
    }

    if (error is supabase.AuthRetryableFetchException) {
      return NetworkException(
        _networkMessage,
        code: error.statusCode,
        cause: error,
      );
    }

    if (error is supabase.AuthApiException) {
      return _mapSupabaseAuthException(error);
    }

    if (error is supabase.AuthException) {
      return _mapSupabaseAuthException(error);
    }

    if (error is supabase.PostgrestException) {
      return _mapPostgrestException(error);
    }

    if (error is supabase.StorageException) {
      return AppException(
        'ไม่สามารถอัปโหลดหรือจัดการไฟล์ได้ กรุณาลองใหม่อีกครั้ง',
        code: error.statusCode,
        cause: error,
      );
    }

    if (error is supabase.FunctionException) {
      return AppException(
        'บริการประมวลผลไม่สามารถใช้งานได้ชั่วคราว กรุณาลองใหม่อีกครั้ง',
        code: '${error.status}',
        cause: error,
      );
    }

    final rawText = error.toString();
    final portalException = _tryMapStudentPortalCode(rawText, error);
    if (portalException != null) {
      return portalException;
    }

    if (_looksLikeNetworkError(rawText)) {
      return NetworkException(
        _networkMessage,
        code: 'NETWORK_ERROR',
        cause: error,
      );
    }

    return AppException(_fallbackMessage, cause: error);
  }

  static AppException _mapSupabaseAuthException(supabase.AuthException error) {
    final normalized = error.message.toLowerCase();
    final code = error.statusCode;

    if (_looksLikeNetworkError(error.message)) {
      return NetworkException(_networkMessage, code: code, cause: error);
    }

    if (normalized.contains('expired') ||
        normalized.contains('jwt') ||
        normalized.contains('refresh_token') ||
        normalized.contains('session')) {
      return AuthException(
        'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่อีกครั้ง',
        code: code,
        cause: error,
      );
    }

    if (normalized.contains('invalid') ||
        normalized.contains('credentials') ||
        normalized.contains('unauthorized')) {
      return AuthException(
        'ไม่สามารถยืนยันตัวตนได้ กรุณาเข้าสู่ระบบใหม่อีกครั้ง',
        code: code,
        cause: error,
      );
    }

    return AuthException(
      'เข้าสู่ระบบไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
      code: code,
      cause: error,
    );
  }

  static AppException _mapPostgrestException(
    supabase.PostgrestException error,
  ) {
    final combinedText = '${error.code ?? ''} ${error.message} ${error.details ?? ''}';
    final portalException = _tryMapStudentPortalCode(combinedText, error);
    if (portalException != null) {
      return portalException;
    }

    return switch (error.code) {
      '23505' => ValidationException(
        'พบข้อมูลซ้ำในระบบ กรุณาตรวจสอบข้อมูลอีกครั้ง',
        code: error.code,
        cause: error,
      ),
      '23503' => ValidationException(
        'ไม่สามารถลบหรือแก้ไขข้อมูลได้ เนื่องจากมีข้อมูลอื่นอ้างอิงอยู่',
        code: error.code,
        cause: error,
      ),
      '42501' => PermissionDeniedException(
        'คุณไม่มีสิทธิ์เข้าถึงหรือแก้ไขข้อมูลนี้',
        code: error.code,
        cause: error,
      ),
      '22P02' || '23502' || '23514' => ValidationException(
        'ข้อมูลไม่ถูกต้องหรือไม่ครบถ้วน กรุณาตรวจสอบอีกครั้ง',
        code: error.code,
        cause: error,
      ),
      '40001' || '409' => ConflictException(
        'ข้อมูลมีการแก้ไขจากอุปกรณ์อื่น กรุณาโหลดข้อมูลล่าสุดแล้วลองใหม่อีกครั้ง',
        code: error.code,
        cause: error,
      ),
      'PGRST116' => ValidationException(
        'ไม่พบข้อมูลที่ต้องการในระบบ',
        code: error.code,
        cause: error,
      ),
      _ => AppException(
        'ไม่สามารถบันทึกหรือดึงข้อมูลได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง',
        code: error.code,
        cause: error,
      ),
    };
  }

  static AppException? _tryMapStudentPortalCode(String text, Object cause) {
    if (text.contains('TEACHER_NOT_FOUND')) {
      return ValidationException(
        'ไม่พบรหัสครูผู้สอน กรุณาตรวจสอบลิงก์หรือติดต่อครูประจำวิชา',
        code: 'TEACHER_NOT_FOUND',
        cause: cause,
      );
    }
    if (text.contains('INVALID_CREDENTIALS')) {
      return AuthException(
        'เลขประจำตัวนักเรียนหรือรหัส PIN 6 หลักไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง',
        code: 'INVALID_CREDENTIALS',
        cause: cause,
      );
    }
    if (text.contains('LOCKED')) {
      return PermissionDeniedException(
        'กรอกรหัสผิดเกินจำนวนครั้งที่กำหนด บัญชีถูกล็อกชั่วคราว กรุณารอสักครู่หรือติดต่อครูผู้สอน',
        code: 'LOCKED',
        cause: cause,
      );
    }
    return null;
  }

  static bool _looksLikeNetworkError(String text) {
    final normalized = text.toLowerCase();
    return normalized.contains('socketexception') ||
        normalized.contains('clientexception') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('failed to fetch') ||
        normalized.contains('xmlhttprequest') ||
        normalized.contains('networkerror') ||
        normalized.contains('connection refused') ||
        normalized.contains('connection closed') ||
        normalized.contains('timed out');
  }
}
