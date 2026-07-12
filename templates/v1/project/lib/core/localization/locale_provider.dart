import 'package:flutter/material.dart';

import '../data/storage_service.dart';
import 'app_locales.dart';

/// 语言切换状态管理器。
///
/// 使用 [ChangeNotifier] + 代理模式管理当前语言环境。
/// 保存/恢复逻辑通过 [StorageService] 代理执行。
///
/// ## 用法
///
/// ```dart
/// // 在 DI 中注册
/// getIt.registerLazySingleton<LocaleProvider>(
///   () => LocaleProvider(storage: getIt<StorageService>()),
/// );
///
/// // 切换语言（自动持久化）
/// getIt<LocaleProvider>().setLocale(AppLocales.zh);
/// ```
///
///
/// Locale state manager with proxy-based persistence.
///
/// Uses [ChangeNotifier] + proxy pattern to manage the current locale.
/// Save / restore logic is delegated to [StorageService].
///
/// ## Usage
///
/// ```dart
/// // Register in DI
/// getIt.registerLazySingleton<LocaleProvider>(
///   () => LocaleProvider(storage: getIt<StorageService>()),
/// );
///
/// // Switch locale (auto-persisted)
/// getIt<LocaleProvider>().setLocale(AppLocales.zh);
/// ```
class LocaleProvider extends ChangeNotifier {
  /// 创建 [LocaleProvider]，注入存储代理。
  ///
  /// 初始语言为 [AppLocales.zh]，调用 [restoreFromStorage] 后恢复用户偏好。
  ///
  ///
  /// Creates a [LocaleProvider] with the injected storage proxy.
  ///
  /// Initial locale is [AppLocales.zh]; call [restoreFromStorage]
  /// to restore the user's saved preference.
  LocaleProvider({required this._storage});

  /// 语言偏好存储 key。
  ///
  ///
  /// Storage key for locale preference.
  static const _storageKey = 'app_locale';

  /// 被代理的存储服务。
  ///
  ///
  /// The proxied storage service.
  final StorageService _storage;

  Locale _locale = AppLocales.zh;

  /// 当前激活的语言环境。
  ///
  ///
  /// The currently active locale.
  Locale get locale => _locale;

  /// 设置新的语言环境，触发监听者重建 UI 并持久化到存储。
  ///
  /// [newLocale] 必须在 [AppLocales.supported] 中。
  ///
  /// Sets a new locale, notifying listeners to rebuild the UI
  /// and persisting the preference to storage.
  ///
  /// [newLocale] must be in [AppLocales.supported].
  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
    await _storage.write(_storageKey, newLocale.languageCode);
  }

  /// 从持久化存储中恢复语言设置。
  ///
  /// 在应用启动时调用。若存储中无记录则保持默认值 [AppLocales.zh]。
  ///
  /// Restores locale preference from persistent storage.
  ///
  /// Called at app startup. Falls back to [AppLocales.zh]
  /// if no preference is stored.
  Future<void> restoreFromStorage() async {
    final code = await _storage.read<String>(_storageKey);
    if (code != null) {
      final saved = AppLocales.fromCode(code);
      if (saved != null && saved != _locale) {
        _locale = saved;
        notifyListeners();
      }
    }
  }
}
