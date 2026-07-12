import 'package:dio/dio.dart';

import '../error/app_exception.dart';
import '../network/dio_client.dart';

/// 所有仓库的抽象基类。
///
/// 提供通用 CRUD 模式、JSON 解析工具和统一的 [DioClient] 访问。
/// 具体仓库继承此类，定义自己的领域专用方法。
///
/// ## 动机
///
/// 没有基类时，每个仓库都要重复 JSON 解析、空安全检查和错误处理。
/// [BaseRepository] 消除了这些样板代码。
///
/// ## 用法
///
/// ```dart
/// class UserRepository extends BaseRepository {
///   UserRepository({required super.client});
///
///   Future<List<User>> fetchUsers({CancelToken? cancelToken}) async {
///     final response = await client.get<List<dynamic>>('/users',
///         cancelToken: cancelToken);
///     return parseList(response, User.fromJson);
///   }
/// }
/// ```
///
/// Abstract base class for all repositories.
///
/// Provides common CRUD patterns, JSON parsing utilities, and
/// unified access to [DioClient]. Concrete repositories inherit
/// from this class and define their own domain-specific methods.
///
/// ## Motivation
///
/// Without a base class, every repository duplicates JSON parsing,
/// null-safety checks, and error logic. [BaseRepository] eliminates
/// that boilerplate.
///
/// ## Usage
///
/// ```dart
/// class UserRepository extends BaseRepository {
///   UserRepository({required super.client});
///
///   Future<List<User>> fetchUsers({CancelToken? cancelToken}) async {
///     final response = await client.get<List<dynamic>>('/users',
///         cancelToken: cancelToken);
///     return parseList(response, User.fromJson);
///   }
/// }
/// ```
abstract class BaseRepository {
  /// 创建绑定到给定 HTTP [client] 的仓库。
  ///
  /// 测试中可将 client 替换为 mock 对象。
  ///
  /// Creates a repository bound to the given HTTP [client].
  ///
  /// The client can be swapped with a mock in tests.
  const BaseRepository({required this.client});

  /// 本仓库所有网络请求使用的 HTTP 客户端。
  ///
  /// The HTTP client used for all network requests in this repository.
  final DioClient client;

  /// 将 API 响应（其 [Response.data] 预期为 JSON 数组）解析为 [T] 类型列表。
  ///
  /// 当 [Response.data] 为 null 时返回空列表。
  ///
  /// Parses an API response whose [Response.data] is
  /// expected to be a JSON list.
  ///
  /// Returns an empty list when [Response.data] is null.
  List<T> parseList<T>(
    Response<dynamic> response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = response.data;
    if (data == null) return [];

    if (data is! List) {
      throw ArgumentError(
        'Expected response data to be a List, got ${data.runtimeType}',
      );
    }

    return data.map((json) => fromJson(json as Map<String, dynamic>)).toList();
  }

  /// 将 API 响应（其 [Response.data] 预期为单个 JSON 对象）解析为 [T] 类型。
  ///
  /// 当 [Response.data] 为 null 时返回 `null`。
  ///
  /// Parses an API response whose [Response.data] is expected to be a single
  /// JSON object.
  ///
  /// Returns `null` when [Response.data] is null.
  T? parseSingle<T>(
    Response<dynamic> response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = response.data;
    if (data == null) return null;

    return fromJson(data as Map<String, dynamic>);
  }

  /// 将完整 API 响应解析为 freezed / json_serializable 模型。
  ///
  /// 适用场景：后端返回嵌套结构（如 `{data: [...], total: N}`），
  /// 开发者定义 freezed 响应模型，`fromJson` 自动处理嵌套解析。
  ///
  /// 与 [parseList] / [parseSingle] 的区别：
  /// - [parseList] 只处理 `Response.data` 是纯数组的扁平响应
  /// - [parseSingle] 只处理 `Response.data` 是纯对象的扁平响应
  /// - [parseResponse] 处理任意嵌套结构，交给 freezed 模型的 fromJson
  ///
  /// 用法：
  /// ```dart
  /// // 1. 定义 freezed 响应模型
  /// @freezed
  /// class ApiResponse with _$ApiResponse {
  ///   const factory ApiResponse({
  ///     required List<UserModel> data,
  ///     required int total,
  ///   }) = _ApiResponse;
  ///   factory ApiResponse.fromJson(Map<String, dynamic> json) =>
  ///       _$ApiResponseFromJson(json);
  /// }
  ///
  /// // 2. Repository 里一步解析
  /// final result = parseResponse<ApiResponse>(
  ///   response, ApiResponse.fromJson);
  /// return result.data;  // freezed 属性，类型安全
  /// ```
  ///
  /// Parses the full API response into a freezed / json_serializable model.
  ///
  /// Use when the backend returns a nested structure
  /// (e.g. `{data: [...], total: N}`). Define a freezed response model
  /// whose `fromJson` handles the nested parsing automatically.
  ///
  /// Unlike [parseList] / [parseSingle]:
  /// - [parseList] only handles flat responses where `Response.data` is a
  ///   plain array.
  /// - [parseSingle] only handles flat responses where `Response.data` is a
  ///   plain object.
  /// - [parseResponse] handles any nested structure by delegating to the
  ///   freezed model's `fromJson`.
  T parseResponse<T>(
    Response<dynamic> response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = response.data;

    if (data is Map<String, dynamic>) {
      try {
        return fromJson(data);
      } on AppException {
        rethrow;
      } catch (e) {
        throw ParseException(
          'Failed to parse response: $e',
          code: 'PARSE',
          originalError: e,
        );
      }
    }

    if (data == null) {
      throw const ParseException('Response data is null', code: 'PARSE_NULL');
    }

    throw ParseException(
      'Expected response data to be a JSON object, got ${data.runtimeType}',
      code: 'PARSE_TYPE',
      originalError: data,
    );
  }
}
