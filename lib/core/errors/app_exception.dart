/// Base application exception carrying a user-facing Thai error [message].
///
/// Pure Dart class used across `domain/` and `presentation/` without
/// depending on Flutter UI or Supabase packages.
class AppException implements Exception {
  const AppException(
    this.message, {
    this.code,
    this.cause,
  });

  /// User-friendly Thai message safe to render in Snackbars and Banners.
  final String message;

  /// Optional structured error code for programmatic handling.
  final String? code;

  /// Optional underlying error object for diagnostics/logging only.
  final Object? cause;

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

/// Raised when the device cannot reach the server or a request times out.
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.cause,
  });
}

/// Raised when authentication fails or the active session has expired.
class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.code,
    super.cause,
  });
}

/// Raised when RLS or RPC security rules reject access to a resource.
class PermissionDeniedException extends AppException {
  const PermissionDeniedException(
    super.message, {
    super.code,
    super.cause,
  });
}

/// Raised when input data violates domain, uniqueness, or reference rules.
class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    super.code,
    super.cause,
  });
}

/// Raised when Optimistic Locking (`version`) detects a concurrent edit.
class ConflictException extends AppException {
  const ConflictException(
    super.message, {
    super.code,
    super.cause,
  });
}
