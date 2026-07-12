/// 本地存储服务抽象接口。
///
/// 采用**代理模式**：所有实现类作为底层存储引擎的代理，
/// 统一对外暴露类型安全的读写 API。
///
/// ## 代理模式结构
///
/// - **Subject（抽象主题）** — [StorageService] 接口
/// - **Proxy（代理）** — [SharedPreferencesStorageService] /
///   [SecureStorageService]
/// - **RealSubject（真实主题）** — `SharedPreferences` /
///   `FlutterSecureStorage`
///
/// 调用方（BLoC / Repository）只依赖 [StorageService] 接口，
/// 底层实现可通过 DI 随意替换。
///
///
/// Abstract interface for local storage.
///
/// Uses the **proxy pattern**: every implementation acts as a proxy
/// over the underlying storage engine, exposing a unified, type-safe
/// read / write API.
///
/// ## Proxy pattern structure
///
/// - **Subject** — [StorageService] interface
/// - **Proxy** — [SharedPreferencesStorageService] /
///   [SecureStorageService]
/// - **RealSubject** — `SharedPreferences` / `FlutterSecureStorage`
///
/// Callers (BLoC / Repository) depend only on the [StorageService]
/// interface, allowing the backend to be swapped via DI.
abstract class StorageService {
  /// 读取指定 [key] 对应的值。
  ///
  /// 键不存在时返回 `null`。
  ///
  /// Reads the value associated with [key].
  ///
  /// Returns `null` when the key does not exist.
  Future<T?> read<T>(String key);

  /// 将 [value] 写入 [key]。
  ///
  /// 覆盖已有值。
  ///
  /// Writes [value] to [key].
  ///
  /// Overwrites any existing value.
  Future<void> write<T>(String key, T value);

  /// 删除 [key] 及其关联的值。
  ///
  /// Deletes [key] and its associated value.
  Future<void> delete(String key);

  /// 清空当前存储命名空间下的所有数据。
  ///
  /// Clears all data under the current storage namespace.
  Future<void> clear();

  /// 检查 [key] 是否存在。
  ///
  /// Checks whether [key] exists.
  Future<bool> containsKey(String key);
}
