import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 应用路由路径。
///
/// 集中管理路由字符串，避免在页面组件中硬编码字面量。
///
///
/// Application route paths.
///
/// Centralize route strings so they can be reused for navigation
/// without hard-coding literals in widgets.
class AppRoutes {
  AppRoutes._();

  //TODO(fluzer): 添加路由 / Add routes
  static const String home = '/';
}

/// 为整个应用配置 [GoRouter]。
///
/// 路由只处理导航——[BlocProvider] 放在每个 Page 组件内部，
/// 保持路由轻量化。
///
///
/// Configures [GoRouter] for the whole app.
///
/// Routes only handle navigation — [BlocProvider] is placed
/// inside each Page widget, keeping routes lightweight.
class AppRouter {
  AppRouter._();

  /// 共享的 [GoRouter] 实例。
  ///
  ///
  /// The shared [GoRouter] instance.
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      //TODO(fluzer): 添加路由 / Add routes
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('flutter app'))),
      ),
    ],
  );
}
