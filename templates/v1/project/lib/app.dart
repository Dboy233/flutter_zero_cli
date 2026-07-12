import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:toastification/toastification.dart';

import 'core/di/injection.dart';
import 'core/localization/context_l10n.dart';
import 'core/localization/locale_provider.dart';
import 'core/notifiers/desktop_toast_service.dart';
import 'core/notifiers/loading_service.dart';
import 'core/notifiers/notifiers_host.dart';
import 'core/notifiers/toast_service.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'l10n/gen/app_localizations.dart';
import 'router/app_router.dart';

/// 应用根组件。
///
/// 配置国际化、屏幕适配、通知（Toast + Loading）以及全局路由。
/// 依赖由 `main()` 中配置的服务定位器（[getIt]）解析。
///
/// ## 国际化
///
/// 使用 Flutter [`gen-l10n`] 工具从 `lib/l10n/*.arb` 文件生成
/// [AppLocalizations]。语言切换通过 [LocaleProvider] 管理，
/// 切换时自动重建整个 widget 树。
/// UI 层可通过 `context.l` 扩展快捷获取翻译文案。
///
/// ## 通知架构
///
/// [NotifiersHost] 放在 [MaterialApp.builder] 中，使其位于 MaterialApp
/// **内部**（可访问 Directionality / Theme / MediaQuery），但在 Navigator
/// **上层**（toast / loading 遮罩覆盖所有页面）。
///
/// 每个 service 的 [build] 用各自的 wrapper 组件包裹 child
/// （如 [FlutterEasyLoading]、[ToastificationWrapper]）。无需额外的
/// `MaterialApp.builder` 处理。
///
/// 切换实现：在 [getIt] 中注册不同的子类即可。
///
///
/// Root application widget.
///
/// Configures localization, screen adaptation, notifiers (toast +
/// loading) and the global router. Dependencies are resolved from the
/// service locator ([getIt]) configured in `main()`.
///
/// ## Localization
///
/// Uses Flutter's [`gen-l10n`] tool to generate [AppLocalizations]
/// from `lib/l10n/*.arb` files. Locale switching is managed by
/// [LocaleProvider], which rebuilds the entire widget tree on change.
/// The UI layer can use the `context.l` extension for quick access.
///
/// ## Notifier architecture
///
/// [NotifiersHost] is placed inside [MaterialApp.builder] so it sits
/// **inside** MaterialApp (with Directionality / Theme / MediaQuery
/// available) but **above** the Navigator (so toast / loading overlay
/// covers all pages).
///
/// Each service's [build] wraps the child with its own wrapper widget
/// (e.g. [FlutterEasyLoading], [ToastificationWrapper]). No extra
/// `MaterialApp.builder` hack is needed.
///
/// Swapping implementation: register a different subclass in [getIt].
class App extends StatelessWidget {
  /// 创建根应用组件。
  ///
  ///
  /// Creates the root app widget.
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = getIt<LocaleProvider>();
    final themeProvider = getIt<ThemeProvider>();
    return ListenableBuilder(
      listenable: Listenable.merge([localeProvider, themeProvider]),
      builder: (context, _) {
        return ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp.router(
              onGenerateTitle: (context) => context.l.appTitle,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              locale: localeProvider.locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              scrollBehavior: const AppScrollBehavior(),
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: AppRouter.router,
              builder: (context, child) {
                return NotifiersHost(
                  toasts: [
                    getIt<ToastService>(), // mobile default
                    getIt<DeskTopToastService>(), // desktop variant
                  ],
                  loadings: [
                    getIt<LoadingService>(), // main loading
                  ],
                  child: child!,
                );
              },
            );
          },
        );
      },
    );
  }
}
