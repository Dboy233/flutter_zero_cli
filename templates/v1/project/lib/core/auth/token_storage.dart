import 'package:flutter/foundation.dart';

import '../data/secure_storage_service.dart';

/// 认证令牌生命周期管理器。
///
/// 采用**缓存优先**策略：
/// - 应用启动时从 [SecureStorageService] 加载 token 到内存。
/// - 运行时 [_cachedToken] 提供同步读取（零 I/O），供
///   [AuthInterceptor] 直接使用。
/// - 写入时间步更新内存和持久化存储。
///
/// ## 用法
///
/// ```dart
/// // 初始化（在 registerBaseDependencies 中）
/// await getIt<TokenStorage>().init();
///
/// // 登录成功时保存
/// await getIt<TokenStorage>().saveToken(accessToken);
///
/// // 退出时清除
/// await getIt<TokenStorage>().clearToken();
/// ```
///
/// Auth token lifecycle manager.
///
/// Uses a **cache-first** strategy:
/// - Loads token from [SecureStorageService] into memory at startup.
/// - [_cachedToken] provides synchronous reads (zero I/O) at runtime,
///   consumed directly by [AuthInterceptor].
/// - Writes update both memory and persistent storage atomically.
///
/// ## Usage
///
/// ```dart
/// // Initialize (inside registerBaseDependencies)
/// await getIt<TokenStorage>().init();
///
/// // Save token on successful login
/// await getIt<TokenStorage>().saveToken(accessToken);
///
/// // Clear token on logout
/// await getIt<TokenStorage>().clearToken();
/// ```
class TokenStorage extends ChangeNotifier {
  /// 创建一个 [TokenStorage]。
  ///
  /// [_secureStorage] 用于 token 的加密持久化。
  ///
  /// Creates a [TokenStorage].
  ///
  /// [_secureStorage] persists tokens with encryption.
  TokenStorage({required this._secureStorage});

  /// 持久化存储代理（安全存储）。
  ///
  /// 必须使用 [SecureStorageService]——token 为敏感数据，不可明文存储。
  ///
  /// The secure persistent storage proxy.
  ///
  /// MUST be a [SecureStorageService] — tokens are sensitive and
  /// must never be persisted in plain text.
  final SecureStorageService _secureStorage;

  String? _cachedToken;

  static const _tokenKey = 'auth_token';

  /// 当前内存中的认证令牌。
  ///
  /// 未登录或已清除时返回 `null`。
  ///
  /// The in-memory auth token.
  ///
  /// Returns `null` when not logged in or cleared.
  String? get token => _cachedToken;

  /// 是否已登录（持有有效 token）。
  ///
  ///
  /// Whether a valid token currently exists.
  bool get isLoggedIn => _cachedToken != null && _cachedToken!.isNotEmpty;

  /// 从安全存储中加载 token 到内存。
  ///
  /// 必须在 [saveToken] 或 [clearToken] 之前调用一次。
  /// 通常在 [Injection.registerBaseDependencies] 中调用。
  ///
  /// Loads the token from secure storage into memory.
  ///
  /// Must be called once before [saveToken] or [clearToken].
  /// Typically called inside [Injection.registerBaseDependencies].
  Future<void> init() async {
    _cachedToken = await _secureStorage.read<String>(_tokenKey);
    notifyListeners();
  }

  /// 保存 token 到内存和持久化存储。
  ///
  /// [token] 为空字符串或 `null` 时行为同 [clearToken]。
  ///
  /// Saves [token] to both memory and persistent storage.
  ///
  /// Passing an empty string or `null` behaves identically to
  /// [clearToken].
  Future<void> saveToken(String? token) async {
    if (token == null || token.isEmpty) {
      await clearToken();
      return;
    }
    _cachedToken = token;
    await _secureStorage.write(_tokenKey, token);
    notifyListeners();
  }

  /// 清除 token（内存 + 持久化存储）。
  ///
  /// 通常在用户退出登录或 401 时调用。
  ///
  /// Clears the token from both memory and persistent storage.
  ///
  /// Typically called on user logout or 401 responses.
  Future<void> clearToken() async {
    _cachedToken = null;
    await _secureStorage.delete(_tokenKey);
    notifyListeners();
  }
}
