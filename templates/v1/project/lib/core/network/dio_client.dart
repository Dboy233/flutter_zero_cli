import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

/// 基于 [Dio] 的轻量封装，集中管理 HTTP 配置。
///
/// 本客户端配置基础 URL、默认超时、日志拦截器、认证拦截器
/// 以及统一的错误处理，作为应用中所有网络请求的单一入口。
///
/// A thin wrapper around [Dio] that centralizes HTTP configuration.
///
/// This client configures the base URL, default timeouts, interceptors
/// for logging and authentication, and a unified error handler. Use it
/// as the single entry point for all network requests in the app.
class DioClient {
  /// 创建一个配置好的 [Dio] 实例。
  ///
  /// 在单元测试或生产构建中若不需要请求/响应日志，可将 [enableLogging] 设为 `false`。
  ///
  /// 也可传入预先配置好的 [dio] 实例，便于测试或自定义配置。
  ///
  /// 通过 [interceptors] 传入额外的 Dio 拦截器（如 [AuthInterceptor]）。
  /// 注入顺序：自定义拦截器 → 日志拦截器。
  ///
  /// Creates a configured [Dio] instance.
  ///
  /// Pass [enableLogging] as `false` in unit tests or production builds
  /// where request/response logs are not wanted.
  ///
  /// Optionally pass a preconfigured [dio] instance for testing or custom
  /// configurations.
  ///
  /// Additional Dio interceptors (e.g. [AuthInterceptor]) can be passed
  /// via [interceptors]. Order: custom interceptors → log interceptor.
  DioClient({
    bool enableLogging = true,
    Dio? dio,
    List<Interceptor> interceptors = const [],
  }) : _dio = dio ?? _createDio(enableLogging, interceptors);

  final Dio _dio;

  static Dio _createDio(
    bool enableLogging,
    List<Interceptor> extraInterceptors,
  ) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Custom interceptors (e.g. AuthInterceptor) — registered first.
    // 自定义拦截器（如 AuthInterceptor）——先注册。
    extraInterceptors.forEach(dio.interceptors.add);

    if (enableLogging) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
        ),
      );
    }

    return dio;
  }

  /// 向 [path] 发起 GET 请求。
  ///
  /// 将 [queryParameters] 与 [options] 透传给 Dio。
  ///
  /// 传入 [cancelToken] 允许调用方取消进行中的请求
  /// （例如用户离开页面时）。
  ///
  /// 失败时抛出 [DioException]，由调用方或仓库转换为业务异常。
  ///
  /// Performs a GET request to [path].
  ///
  /// [queryParameters] and [options] are forwarded to Dio.
  ///
  /// Passing [cancelToken] allows callers to cancel an in-flight request
  /// (e.g. when the user navigates away from a page).
  ///
  /// Throws a [DioException] on failure so callers or repositories can
  /// convert it to domain-specific exceptions.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// 向 [path] 发起 POST 请求。
  ///
  /// Performs a POST request to [path].
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// 向 [path] 发起 PUT 请求。
  ///
  /// Performs a PUT request to [path].
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// 向 [path] 发起 DELETE 请求。
  ///
  /// Performs a DELETE request to [path].
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// 上传文件至 [path]（multipart/form-data）。
  ///
  /// 将 [formData] 中的文件和字段以 multipart 式发送。
  /// [onSendProgress] 可用于监听上传进度（0~100）。
  ///
  /// Uploads files to [path] via multipart/form-data.
  ///
  /// [formData] carries the files and fields to send.
  /// [onSendProgress] can be used to monitor upload progress (0–100).
  Future<Response<T>> uploadFile<T>(
    String path, {
    required FormData formData,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    return _dio.post<T>(
      path,
      data: formData,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    );
  }
}
