import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/token_storage.dart';

/// 认证令牌拦截器。
///
/// 在每次请求的 [onRequest] 中自动注入 Bearer token，
/// 在 [onError] 中处理 401 响应（清除 token 并通知监听者）。
///
/// ## 工作原理
///
/// 1. **请求阶段** — 从 [TokenStorage.token]（内存缓存，同步读取）
///    取 token，写入 `Authorization: Bearer <token>` 头。
/// 2. **响应阶段** — 拦截 401 状态码，调用 [TokenStorage.clearToken]
///    清除本地和持久化 token。
///
/// ## 注册方式
///
/// ```dart
/// // 在 DioClient 初始化时添加到 dio 实例
/// dio.interceptors.add(AuthInterceptor(tokenStorage: tokenStorage));
/// ```
///
/// ## 参考
///
/// - [Dio 拦截器文档](https://pub.dev/packages/dio#interceptors)
///
///
/// Auth token interceptor.
///
/// Automatically injects a Bearer token in [onRequest] for every
/// outgoing request, and handles 401 responses in [onError]
/// (clears token and notifies listeners).
///
/// ## How it works
///
/// 1. **Request phase** — reads token from [TokenStorage.token]
///    (in-memory cache, synchronous) and adds the
///    `Authorization: Bearer <token>` header.
/// 2. **Response phase** — intercepts 401 status codes, calls
///    [TokenStorage.clearToken] to wipe the token locally and from
///    persistent storage.
///
/// ## Registration
///
/// ```dart
/// dio.interceptors.add(AuthInterceptor(tokenStorage: tokenStorage));
/// ```
///
/// ## See also
///
/// - [Dio interceptor docs](https://pub.dev/packages/dio#interceptors)
class AuthInterceptor extends Interceptor {
  /// 创建一个 [AuthInterceptor]。
  ///
  /// [tokenStorage] 提供同步的内存 token 读取和清除能力。
  /// [onUnauthorized] 在收到 401 时回调（如跳转登录页）。
  ///
  /// Creates an [AuthInterceptor].
  ///
  /// [tokenStorage] provides synchronous in-memory token reads and
  /// async clear. [onUnauthorized] is called on 401 (e.g. to navigate
  /// to the login screen).
  AuthInterceptor({required this.tokenStorage, this.onUnauthorized});

  /// Token 生命周期管理器。
  ///
  ///
  /// Token lifecycle manager.
  final TokenStorage tokenStorage;

  /// 401 时的回调（例如导航到登录页）。
  ///
  ///
  /// Callback invoked on 401 (e.g. navigate to login screen).
  final VoidCallback? onUnauthorized;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenStorage.token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 仅处理 401：token 已失效，必须清理并引导重新登录。
    // 403 表示权限不足，不一定需要清除 token；
    // 业务方如需统一处理，可在 [onUnauthorized] 中根据具体错误码决定。
    // Only handle 401: the token is no longer valid, so clear it and let
    // the caller redirect to login. 403 means insufficient permission and
    // does not necessarily require clearing the token; business logic can
    // handle it in [onUnauthorized] if needed.
    if (err.response?.statusCode == 401) {
      unawaited(tokenStorage.clearToken());
      onUnauthorized?.call();
    }
    handler.next(err);
  }
}
