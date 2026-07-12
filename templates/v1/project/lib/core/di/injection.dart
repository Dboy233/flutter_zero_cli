import 'package:shared_preferences/shared_preferences.dart';

import '../auth/token_storage.dart';
import '../data/secure_storage_service.dart';
import '../data/shared_preferences_storage_service.dart';
import '../data/storage_service.dart';
import '../localization/locale_provider.dart';
import '../network/auth_interceptor.dart';
import '../network/dio_client.dart';
import '../notifiers/desktop_toast_service.dart';
import '../notifiers/implementers/easyloading_service.dart';
import '../notifiers/implementers/easyloading_toast_service.dart';
import '../notifiers/implementers/toastification_service.dart';
import '../notifiers/loading_service.dart';
import '../notifiers/toast_service.dart';
import '../theme/theme_provider.dart';
import 'get_it_instance.dart';
import 'injection_base.dart';

export 'get_it_instance.dart';

/// 用户可修改的 DI 子类。
///
/// 继承 [InjectionBase] 并实现 [registerBaseDependencies] 与
/// [registerUserDependencies]。父类已定义好注册顺序并自动维护
/// Feature Modules 的注册区域。
///
/// 如需替换某个基础设施实现（如桌面端使用 [ToastificationToastService]），
/// 直接在本文件中修改对应注册即可。
///
/// User-editable DI subclass.
///
/// Extends [InjectionBase] and implements [registerBaseDependencies] and
/// [registerUserDependencies]. The base class defines the registration order
/// and automatically maintains the Feature Modules registration area.
///
/// To swap an infrastructure implementation (e.g. use [ToastificationToastService]
/// on desktop), edit the corresponding registration in this file.
class Injection extends InjectionBase {
  @override
  Future<void> registerBaseDependencies() async {
    await _registerStorageLayer();
    await _registerAuthLayer();
    _registerNotifiersLayer();
    _registerNetworkLayer();
    await _registerLocalizationLayer();
    await _registerThemeLayer();
  }

  @override
  Future<void> registerUserDependencies() async {
    // 在此添加自定义依赖 / 第三方 SDK。
    // Add custom dependencies or third-party SDKs here.
  }

  /// 注册存储层依赖。
  ///
  /// Registers the storage layer dependencies.
  Future<void> _registerStorageLayer() async {
    // SharedPreferences — general-purpose key-value storage.
    // SharedPreferences — 通用键值存储。
    final prefs = await SharedPreferences.getInstance();
    getIt
      ..registerLazySingleton<StorageService>(
        () => SharedPreferencesStorageService(prefs),
      )
      // SecureStorage — encrypted storage for tokens & credentials.
      // SecureStorage — 加密存储，存放 token 和凭证。
      ..registerLazySingleton<SecureStorageService>(SecureStorageService.new);
  }

  /// 注册 Auth 层依赖。
  ///
  /// Registers the auth layer dependencies.
  Future<void> _registerAuthLayer() async {
    // TokenStorage — cache-first token lifecycle manager.
    // TokenStorage — 缓存优先的 token 生命周期管理。
    final tokenStorage = TokenStorage(
      secureStorage: getIt<SecureStorageService>(),
    );
    await tokenStorage.init();
    getIt.registerSingleton<TokenStorage>(tokenStorage);
  }

  /// 注册 Notifiers 层依赖（Toast / Loading 服务）。
  ///
  /// Registers the notifier layer dependencies (Toast / Loading services).
  void _registerNotifiersLayer() {
    getIt
      ..registerLazySingleton<ToastService>(EasyLoadingToastService.new)
      ..registerLazySingleton<DeskTopToastService>(
        ToastificationToastService.new,
      )
      ..registerLazySingleton<LoadingService>(EasyLoadingLoadingService.new);
  }

  /// 注册网络层依赖。
  ///
  /// Registers the network layer dependencies.
  void _registerNetworkLayer() {
    // DioClient 注入 AuthInterceptor，自动为每个请求附加 Bearer token。
    // DioClient is wired with AuthInterceptor, which auto-attaches
    // the Bearer token to every request.
    getIt.registerLazySingleton<DioClient>(
      () => DioClient(
        interceptors: [AuthInterceptor(tokenStorage: getIt<TokenStorage>())],
      ),
    );
  }

  /// 注册国际化层依赖。
  ///
  /// Registers the localization layer dependencies.
  Future<void> _registerLocalizationLayer() async {
    // LocaleProvider 注入 StorageService，切换语言时自动持久化，
    // 启动时从存储恢复用户上次选择的语言。
    // LocaleProvider is wired with StorageService: locale changes are
    // auto-persisted, and the saved preference is restored at startup.
    final localeProvider = LocaleProvider(storage: getIt<StorageService>());
    await localeProvider.restoreFromStorage();
    getIt.registerSingleton<LocaleProvider>(localeProvider);
  }

  /// 注册主题层依赖。
  ///
  /// Registers the theme layer dependencies.
  Future<void> _registerThemeLayer() async {
    // ThemeProvider 注入 StorageService，切换主题时自动持久化，
    // 启动时从存储恢复用户上次选择的主题模式。
    // ThemeProvider is wired with StorageService: theme changes are
    // auto-persisted, and the saved preference is restored at startup.
    final themeProvider = ThemeProvider(storage: getIt<StorageService>());
    await themeProvider.restoreFromStorage();
    getIt.registerSingleton<ThemeProvider>(themeProvider);
  }
}
