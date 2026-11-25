import 'dart:async';
import 'dart:convert';

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
      return _mapFunctionException(error);
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

  static AppException _mapFunctionException(supabase.FunctionException error) {
    final parsed = _extractFunctionErrorPayload(error.details);
    final errorCode = parsed.errorCode;
    final serverMessage = parsed.message;

    if (errorCode != null) {
      final mapped = mapEdgeFunctionErrorCode(
        errorCode,
        serverMessage: serverMessage,
        cause: error,
      );
      if (mapped != null) {
        return mapped;
      }
    }

    if (serverMessage != null && serverMessage.isNotEmpty) {
      if (error.status == 401) {
        return AuthException(serverMessage, code: 'UNAUTHORIZED', cause: error);
      }
      if (error.status == 403) {
        return PermissionDeniedException(
          serverMessage,
          code: 'FORBIDDEN',
          cause: error,
        );
      }
      if (error.status == 400) {
        return ValidationException(
          serverMessage,
          code: 'BAD_REQUEST',
          cause: error,
        );
      }
      return AppException(
        serverMessage,
        code: '${error.status}',
        cause: error,
      );
    }

    return switch (error.status) {
      401 => AuthException(
        'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่อีกครั้ง',
        code: 'UNAUTHORIZED',
        cause: error,
      ),
      403 => PermissionDeniedException(
        'บัญชีของคุณยังไม่ได้เปิดใช้งานฟีเจอร์ AI อ่านรายชื่อ',
        code: 'AI_FEATURE_DISABLED',
        cause: error,
      ),
      404 => AppException(
        'ไม่พบบริการ AI (parse-roster-ai) กรุณาตรวจสอบว่าได้ Deploy Edge Function แล้ว',
        code: 'FUNCTION_NOT_FOUND',
        cause: error,
      ),
      429 => AppException(
        'โควตา Gemini API ชั่วคราวเต็ม กรุณารอสักครู่แล้วลองใหม่อีกครั้ง',
        code: 'GEMINI_QUOTA_EXCEEDED',
        cause: error,
      ),
      _ => AppException(
        'ไม่สามารถเรียกใช้บริการ AI ได้ในขณะนี้ (HTTP ${error.status}) กรุณาลองใหม่อีกครั้ง',
        code: '${error.status}',
        cause: error,
      ),
    };
  }

  /// Maps structured `error_code` values returned by the `parse-roster-ai`
  /// Edge Function into safe Thai [AppException] instances.
  static AppException? mapEdgeFunctionErrorCode(
    String errorCode, {
    String? serverMessage,
    Object? cause,
  }) {
    final trimmedMessage = serverMessage?.trim();
    final hasThaiServerMsg =
        trimmedMessage != null &&
        trimmedMessage.isNotEmpty &&
        RegExp(r'[\u0E00-\u0E7F]').hasMatch(trimmedMessage);

    String pick(String fallback) => hasThaiServerMsg ? trimmedMessage : fallback;

    return switch (errorCode.trim().toUpperCase()) {
      'UNAUTHORIZED' => AuthException(
        pick('เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่อีกครั้ง'),
        code: 'UNAUTHORIZED',
        cause: cause,
      ),
      'AI_FEATURE_DISABLED' => PermissionDeniedException(
        pick('บัญชีของคุณยังไม่ได้เปิดใช้งานฟีเจอร์ AI อ่านรายชื่อ'),
        code: 'AI_FEATURE_DISABLED',
        cause: cause,
      ),
      'INVALID_FILE' => ValidationException(
        pick('ไฟล์ที่เลือกไม่รองรับหรือเสียหาย กรุณาเลือกไฟล์ JPG, PNG หรือ PDF ใหม่'),
        code: 'INVALID_FILE',
        cause: cause,
      ),
      'FILE_TOO_LARGE' => ValidationException(
        pick('ขนาดไฟล์เกิน 500 KB ไม่สามารถส่งประมวลผลได้'),
        code: 'FILE_TOO_LARGE',
        cause: cause,
      ),
      'STORAGE_DOWNLOAD_FAILED' => AppException(
        pick('ไม่พบไฟล์ต้นฉบับในพื้นที่จัดเก็บ กรุณาอัปโหลดใหม่อีกครั้ง'),
        code: 'STORAGE_DOWNLOAD_FAILED',
        cause: cause,
      ),
      'MISSING_GEMINI_API_KEY' => AppException(
        pick(
          'ยังไม่ได้ตั้งค่า GEMINI_API_KEY บนเซิร์ฟเวอร์ Supabase Edge Functions กรุณาตั้งค่า Secret ก่อนใช้งาน',
        ),
        code: 'MISSING_GEMINI_API_KEY',
        cause: cause,
      ),
      'GEMINI_INVALID_API_KEY' => AppException(
        pick(
          'คีย์ GEMINI_API_KEY บนเซิร์ฟเวอร์ไม่ถูกต้องหรือไม่มีสิทธิ์เรียกใช้ Gemini API',
        ),
        code: 'GEMINI_INVALID_API_KEY',
        cause: cause,
      ),
      'GEMINI_MODEL_UNAVAILABLE' => AppException(
        pick(
          'โมเดล AI ที่ตั้งค่าไว้ไม่พร้อมใช้งาน กรุณาตรวจสอบค่า GEMINI_MODEL บนเซิร์ฟเวอร์',
        ),
        code: 'GEMINI_MODEL_UNAVAILABLE',
        cause: cause,
      ),
      'GEMINI_QUOTA_EXCEEDED' => AppException(
        pick('โควตา Gemini API ชั่วคราวเต็ม กรุณารอสักครู่แล้วลองใหม่อีกครั้ง'),
        code: 'GEMINI_QUOTA_EXCEEDED',
        cause: cause,
      ),
      'GEMINI_API_ERROR' => AppException(
        pick(
          'บริการ Gemini AI ไม่สามารถประมวลผลไฟล์นี้ได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง',
        ),
        code: 'GEMINI_API_ERROR',
        cause: cause,
      ),
      'INVALID_AI_RESPONSE' => AppException(
        pick(
          'ไม่สามารถอ่านโครงสร้างรายชื่อจากไฟล์นี้ได้ กรุณาตรวจสอบความคมชัดของเอกสารแล้วลองใหม่',
        ),
        code: 'INVALID_AI_RESPONSE',
        cause: cause,
      ),
      _ => null,
    };
  }

  static ({String? errorCode, String? message}) _extractFunctionErrorPayload(
    Object? details,
  ) {
    Map<String, dynamic>? map;
    if (details is Map) {
      map = Map<String, dynamic>.from(details);
    } else if (details is String && details.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(details);
        if (decoded is Map) {
          map = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        map = null;
      }
    }
    if (map == null) {
      return (errorCode: null, message: null);
    }
    final code = map['error_code'] is String
        ? (map['error_code'] as String).trim()
        : null;
    final msg = map['message'] is String
        ? (map['message'] as String).trim()
        : (map['error'] is String ? (map['error'] as String).trim() : null);
    return (errorCode: code, message: msg);
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
