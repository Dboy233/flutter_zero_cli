import 'package:shared_preferences/shared_preferences.dart';

import 'storage_service.dart';

/// 基于 [SharedPreferences] 的本地存储代理。
///
/// 代理模式：封装 [SharedPreferences] 的原始 API，
/// 提供统一的 [StorageService] 接口，屏蔽底层差异。
///
/// ## 支持的类型
///
/// | Dart 类型 | SharedPreferences 方法 |
/// |---|---|
/// | `String` | `getString` / `setString` |
/// | `int` | `getInt` / `setInt` |
/// | `double` | `getDouble` / `setDouble` |
/// | `bool` | `getBool` / `setBool` |
/// | `List<String>` | `getStringList` / `setStringList` |
///
/// ## 用法示例
///
/// ```dart
/// final storage = getIt<StorageService>();
/// await storage.write('theme_mode', 'dark');
/// final mode = await storage.read<String>('theme_mode'); // 'dark'
/// ```
///
/// Proxy over [SharedPreferences] for local storage.
///
/// Proxy pattern: wraps [SharedPreferences]'s raw API and presents
/// it through the unified [StorageService] interface, abstracting
/// away the underlying engine.
///
/// ## Supported types
///
/// | Dart type | SharedPreferences method |
/// |---|---|
/// | `String` | `getString` / `setString` |
/// | `int` | `getInt` / `setInt` |
/// | `double` | `getDouble` / `setDouble` |
/// | `bool` | `getBool` / `setBool` |
/// | `List<String>` | `getStringList` / `setStringList` |
///
/// ## Usage example
///
/// ```dart
/// final storage = getIt<StorageService>();
/// await storage.write('theme_mode', 'dark');
/// final mode = await storage.read<String>('theme_mode'); // 'dark'
/// ```
class SharedPreferencesStorageService extends StorageService {
  /// 创建一个 [SharedPreferencesStorageService]。
  ///
  /// [prefs] 必须是已初始化的 [SharedPreferences] 实例。
  ///
  /// 通过 `SharedPreferences.getInstance()` 获取实例后传入。
  ///
  /// Creates a [SharedPreferencesStorageService].
  ///
  /// [prefs] must be a ready [SharedPreferences] instance,
  /// obtained via `SharedPreferences.getInstance()`.
  SharedPreferencesStorageService(this._prefs);

  /// 被代理的真实对象。
  ///
  ///
  /// The real subject being proxied.
  final SharedPreferences _prefs;

  @override
  Future<T?> read<T>(String key) async {
    if (!_prefs.containsKey(key)) return null;

    if (T == String) {
      return _prefs.getString(key) as T?;
    } else if (T == int) {
      return _prefs.getInt(key) as T?;
    } else if (T == double) {
      return _prefs.getDouble(key) as T?;
    } else if (T == bool) {
      return _prefs.getBool(key) as T?;
    } else if (_isStringListType<T>()) {
      return _prefs.getStringList(key) as T?;
    }
    return null;
  }

  bool _isStringListType<T>() => T == List<String>;

  @override
  Future<void> write<T>(String key, T value) async {
    if (T == String) {
      await _prefs.setString(key, value as String);
    } else if (T == int) {
      await _prefs.setInt(key, value as int);
    } else if (T == double) {
      await _prefs.setDouble(key, value as double);
    } else if (T == bool) {
      await _prefs.setBool(key, value as bool);
    } else if (_isStringListType<T>()) {
      await _prefs.setStringList(key, value as List<String>);
    } else {
      throw ArgumentError(
        'Unsupported type $T for SharedPreferencesStorageService',
      );
    }
  }

  @override
  Future<void> delete(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    return _prefs.containsKey(key);
  }
}
