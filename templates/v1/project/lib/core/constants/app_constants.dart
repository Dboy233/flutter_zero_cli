/// 全局应用常量。
///
/// 本文件集中存放应用中复用的值，例如超时时间、默认分页大小和功能开关。
///
///
/// Global application constants.
///
/// This file holds values that are reused across the app, such as
/// timeouts, default page sizes, and feature flags.
class AppConstants {
  AppConstants._();

  /// 网络请求连接超时的默认时长。
  ///
  ///
  /// Default duration for network request timeouts.
  static const Duration connectTimeout = Duration(seconds: 15);

  /// 从服务器接收数据的默认超时时长。
  ///
  ///
  /// Default duration for receiving data from the server.
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// 分页列表请求的默认每页条数。
  ///
  ///
  /// Default page size for paginated list requests.
  static const int defaultPageSize = 20;
}
