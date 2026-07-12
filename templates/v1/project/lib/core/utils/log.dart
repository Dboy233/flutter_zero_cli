import 'package:logger/logger.dart';

/// 应用级日志工具。
///
/// 使用 [Log.d] 输出调试信息，[Log.i] 输出普通信息，[Log.w] 输出警告，[Log.e] 输出错误。
/// 日志配置为美观打印，并截断堆栈轨迹，适合 Flutter 开发调试。
///
///
/// Application-wide logger.
///
/// Use [Log.d] for debug, [Log.i] for info, [Log.w] for warnings and
/// [Log.e] for errors. The logger is configured with pretty printing
/// and a truncated stack trace suitable for Flutter development.
class Log {
  Log._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(dateTimeFormat: DateTimeFormat.dateAndTime),
  );

  /// 输出调试日志。
  ///
  ///
  /// Logs a debug message.
  static void d(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// 输出普通信息日志。
  ///
  ///
  /// Logs an info message.
  static void i(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// 输出警告日志。
  ///
  ///
  /// Logs a warning message.
  static void w(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// 输出错误日志。
  ///
  ///
  /// Logs an error message.
  static void e(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
