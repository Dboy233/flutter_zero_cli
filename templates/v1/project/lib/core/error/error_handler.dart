import 'package:dio/dio.dart';

import 'app_exception.dart';

/// 将原始异常映射为类型化的 [AppException] 实例。
///
/// ## 用法
///
/// ```dart
/// try {
///   await fetchData();
/// } catch (e, stackTrace) {
///   final ex = ErrorHandler.handle(e);
///   // ex.message 可以安全地在 toast 中展示
///
///   // ex.message is safe to show in a toast
/// }
/// ```
///
/// 这是**唯一的转换点**——所有 BLoC / Repository
/// 的错误路径都经过此处，保证一致的用户体验。
///
/// Maps raw exceptions into typed [AppException] instances.
///
/// ## Usage
///
/// ```dart
/// try {
///   await fetchData();
/// } catch (e, stackTrace) {
///   final ex = ErrorHandler.handle(e);
///   // ex.message is safe to show in a toast
/// }
/// ```
///
/// This is the **single conversion point** — all BLoC / Repository
/// error paths go through here, guaranteeing consistent UX.
class ErrorHandler {
  ErrorHandler._();

  /// 将任意 [error] 转换为类型化的 [AppException]。
  ///
  /// 当错误是被取消的请求（主动中止）时返回 `null`，应静默忽略。
  ///
  /// Converts any [error] into a typed [AppException].
  ///
  /// Returns `null` when the error is a cancelled request (intentional
  /// abort) and should be silently ignored.
  static AppException? handle(Object error, [StackTrace? stackTrace]) {
    if (error is DioException) {
      return _handleDioException(error);
    }

    if (error is AppException) {
      return error;
    }

    if (error is Exception) {
      return UnknownException(error.toString(), originalError: error);
    }

    return UnknownException(error.toString(), originalError: error);
  }

  /// 当错误是主动取消时返回 `true`，此时**不应**弹出 toast 或更新状态。
  ///
  /// Returns `true` when the error was intentionally cancelled and
  /// should **not** trigger a toast or state update.
  static bool isCancelled(Object error) {
    return error is DioException && error.type == DioExceptionType.cancel;
  }

  // ── Internal helpers ──────────────────────────────────────────────

  static AppException _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.cancel:
        return UnknownException(
          'Request cancelled',
          code: 'CANCEL',
          originalError: error,
        );

      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          'Connection timed out. Please check your network.',
          code: 'TIMEOUT',
          originalError: error,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.connectionError:
        return NetworkException(
          'No internet connection. Please check your network.',
          originalError: error,
        );

      default:
        return UnknownException(
          error.message ?? 'An unexpected error occurred.',
          originalError: error,
        );
    }
  }

  static AppException _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final code = statusCode?.toString() ?? 'unknown';

    // 优先使用服务端返回的消息。
    // Try server-provided message first.
    final data = error.response?.data;
    String message;

    if (data is Map<String, dynamic> && data.containsKey('message')) {
      message = data['message'] as String;
    } else {
      message = _statusCodeMessage(statusCode);
    }

    if (statusCode == 401 || statusCode == 403) {
      return AuthException(message, code: code, originalError: error);
    }

    if (statusCode != null && statusCode >= 500) {
      return ServerException(message, code: code, originalError: error);
    }

    return ServerException(message, code: code, originalError: error);
  }

  static String _statusCodeMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please try again.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'Access denied.';
      case 404:
        return 'The requested resource was not found.';
      case 422:
        return 'Validation failed. Please check your input.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Internal server error. Please try again later.';
      case 502:
        return 'Bad gateway. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return 'Server returned an error ($statusCode). Please try again.';
    }
  }
}
