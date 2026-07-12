import 'package:flutter/material.dart';

import '../data/storage_service.dart';

/// 主题模式状态管理器。
///
/// 使用 [ChangeNotifier] + 代理模式管理当前主题模式。
/// 保存/恢复逻辑通过 [StorageService] 代理执行。
///
/// ## 用法
///
/// ```dart
/// // 在 DI 中注册
/// getIt.registerSingleton<ThemeProvider>(
///   ThemeProvider(storage: getIt<StorageService>()),
/// );
///
/// // 切换主题（自动持久化）
/// getIt<ThemeProvider>().setThemeMode(ThemeMode.dark);
/// ```
///
///
/// Theme mode state manager with proxy-based persistence.
///
/// Uses [ChangeNotifier] + proxy pattern to manage the current theme mode.
/// Save / restore logic is delegated to [StorageService].
///
/// ## Usage
///
/// ```dart
/// // Register in DI
/// getIt.registerSingleton<ThemeProvider>(
///   ThemeProvider(storage: getIt<StorageService>()),
/// );
///
/// // Switch theme (auto-persisted)
/// getIt<ThemeProvider>().setThemeMode(ThemeMode.dark);
/// ```
class ThemeProvider extends ChangeNotifier {
  /// 创建 [ThemeProvider]，注入存储代理。
  ///
  /// 初始模式为 [ThemeMode.system]，调用 [restoreFromStorage] 后恢复用户偏好。
  ///
  ///
  /// Creates a [ThemeProvider] with the injected storage proxy.
  ///
  /// Initial mode is [ThemeMode.system]; call [restoreFromStorage]
  /// to restore the user's saved preference.
  ThemeProvider({required this._storage});

  /// 主题偏好存储 key。
  ///
  ///
  /// Storage key for theme mode preference.
  static const _storageKey = 'app_theme_mode';

  /// 被代理的存储服务。
  ///
  ///
  /// The proxied storage service.
  final StorageService _storage;

  ThemeMode _themeMode = ThemeMode.system;

  /// 当前激活的主题模式。
  ///
  ///
  /// The currently active theme mode.
  ThemeMode get themeMode => _themeMode;

  /// 设置新的主题模式，触发监听者重建 UI 并持久化到存储。
  ///
  /// Sets a new theme mode, notifying listeners to rebuild the UI
  /// and persisting the preference to storage.
  Future<void> setThemeMode(ThemeMode newMode) async {
    if (_themeMode == newMode) return;
    _themeMode = newMode;
    notifyListeners();
    await _storage.write(_storageKey, newMode.name);
  }

  /// 从持久化存储中恢复主题设置。
  ///
  /// 在应用启动时调用。若存储中无记录则保持默认值 [ThemeMode.system]。
  ///
  /// Restores theme preference from persistent storage.
  ///
  /// Called at app startup. Falls back to [ThemeMode.system]
  /// if no preference is stored.
  Future<void> restoreFromStorage() async {
    final saved = await _storage.read<String>(_storageKey);
    if (saved != null) {
      final mode = ThemeMode.values.where((m) => m.name == saved).firstOrNull;
      if (mode != null && mode != _themeMode) {
        _themeMode = mode;
        notifyListeners();
      }
    }
  }
}
