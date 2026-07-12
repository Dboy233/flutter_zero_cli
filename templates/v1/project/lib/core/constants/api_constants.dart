/// API 接口与配置常量。
///
/// 将后端相关路径集中管理，避免在业务代码中硬编码 URL。
///
///
/// API endpoint and configuration constants.
///
/// Keep all backend-related paths in one place so the rest of the app
/// does not hard-code URLs.
class ApiConstants {
  ApiConstants._();

  /// [DioClient] 使用的基础 URL。
  ///
  /// 替换为你的实际后端地址。
  ///
  ///
  /// Base URL used by [DioClient].
  ///
  /// Replace with your actual backend URL.
  static const String baseUrl = 'https://api.example.com';
}
