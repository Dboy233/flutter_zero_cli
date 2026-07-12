import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'storage_service.dart';

/// 基于 [FlutterSecureStorage] 的安全存储代理。
///
/// 代理模式：封装 [FlutterSecureStorage] 的原始 API，
/// 提供统一的 [StorageService] 接口。所有数据经过系统级安全加密
/// （Android: EncryptedSharedPreferences / iOS: Keychain）。
///
/// ## 适用场景
///
/// - 认证令牌 ([TokenStorage])
/// - 用户凭证
/// - API 密钥
/// - 任何不应以明文持久化的敏感数据
///
/// ## 注意
///
/// 仅支持 `String` 类型的读写。如需存储其他类型，
/// 请在上层自行序列化后再写入。
///
///
/// Proxy over [FlutterSecureStorage] for secure data persistence.
///
/// Proxy pattern: wraps [FlutterSecureStorage]'s raw API and presents
/// it through the unified [StorageService] interface. All data is
/// encrypted at the system level (Android: EncryptedSharedPreferences /
/// iOS: Keychain).
///
/// ## Use cases
///
/// - Auth tokens ([TokenStorage])
/// - User credentials
/// - API keys
/// - Any sensitive data that must not be persisted in plain text
///
/// ## Note
///
/// Only `String` read / write is supported. For other types,
/// serialize them before writing.
class SecureStorageService extends StorageService {
  /// 创建一个 [SecureStorageService]。
  ///
  /// [storage] 可选——传入自定义实例便于测试；
  /// 默认使用 [FlutterSecureStorage]。
  ///
  /// Creates a [SecureStorageService].
  ///
  /// [storage] is optional — pass a custom instance for testing;
  /// defaults to [FlutterSecureStorage].
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// 被代理的真实对象。
  ///
  ///
  /// The real subject being proxied.
  final FlutterSecureStorage _storage;

  @override
  Future<T?> read<T>(String key) async {
    final value = await _storage.read(key: key);
    if (value == null) return null;

    // flutter_secure_storage only supports String read/write.
    // 仅支持 String 类型——flutter_secure_storage 底层为纯文本存储。
    if (T != String && T != dynamic) {
      throw UnsupportedError(
        'SecureStorageService only supports String reads. '
        'Got type argument $T for key "$key".',
      );
    }
    return value as T?;
  }

  @override
  Future<void> write<T>(String key, T value) async {
    // flutter_secure_storage 仅支持 String 写入；写入非 String 类型会被静默 toString()，
    // 导致读取时无法恢复原始类型。因此与 read 对称地拒绝非 String 类型。
    // flutter_secure_storage only supports String writes. Non-String values
    // would be silently converted via toString(), so reject them to stay
    // symmetric with [read].
    if (T != String) {
      throw UnsupportedError(
        'SecureStorageService only supports String writes. '
        'Got type argument $T for key "$key".',
      );
    }
    await _storage.write(key: key, value: value as String);
  }

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  @override
  Future<void> clear() async {
    await _storage.deleteAll();
  }

  @override
  Future<bool> containsKey(String key) {
    return _storage.containsKey(key: key);
  }
}
