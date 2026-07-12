/// 应用级异常的密封类层级。
///
/// 每个异常都携带面向用户的 [message]，并可附带 [code]
/// （如 HTTP 状态码）和 [originalError]。
/// [ErrorHandler] 将底层异常（DioException 等）映射到此层级，
/// 使得应用其余部分无需接触原始传输层错误。
///
/// Sealed hierarchy of application-specific exceptions.
///
/// Every exception carries a user-facing [message] and optionally
/// a [code] (e.g. HTTP status code) and the [originalError].
/// [ErrorHandler] maps low-level exceptions (DioException, etc.)
/// into this hierarchy so the rest of the app never touches
/// raw transport-layer errors.
sealed class AppException implements Exception {
  const AppException(this.message, {this.code, this.originalError});

  /// 适合在 toast 中展示的可读消息。
  ///
  /// Human-readable message suitable for display in a toast.
  final String message;

  /// 可选的错误码（如 '404'、'AUTH_EXPIRED'）。
  ///
  /// Optional error code (e.g. '404', 'AUTH_EXPIRED').
  final String? code;

  /// 触发此异常的原始底层异常。
  ///
  /// The original low-level exception that triggered this one.
  final Object? originalError;
}

/// 设备无网络连接或 DNS 解析失败时抛出。
///
/// Raised when the device has no network connectivity or DNS fails.
final class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
}

/// 服务器返回错误响应（4xx / 5xx）时抛出。
///
/// Raised when the server returns an error response (4xx / 5xx).
final class ServerException extends AppException {
  const ServerException(super.message, {super.code, super.originalError});
}

/// 401 / token 过期等认证场景时抛出。
///
/// Raised on 401 / token-expired scenarios.
final class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

/// 请求超时（连接 / 发送 / 接收）时抛出。
///
/// Raised when the request times out (connect / send / receive).
final class TimeoutException extends AppException {
  const TimeoutException(super.message, {super.code, super.originalError});
}

/// JSON 解析或响应数据结构不符预期时抛出。
///
/// Raised when JSON parsing fails or response data structure
/// does not match expectations (e.g. expected Map but got List).
final class ParseException extends AppException {
  const ParseException(super.message, {super.code, super.originalError});
}

/// 无法进一步分类的错误通用类型。
///
/// Catch-all for errors that cannot be classified further.
final class UnknownException extends AppException {
  const UnknownException(super.message, {super.code, super.originalError});
}
