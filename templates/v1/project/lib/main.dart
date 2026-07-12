import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/injection.dart';

/// 应用入口。
///
/// 在运行应用前初始化依赖注入容器。
///
///
/// Application entry point.
///
/// Initializes the dependency injection container before running the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 注册所有服务（Dio、仓库、BLoC 等）。
  // Register all services (Dio, repositories, BLoCs, etc.).
  await Injection().registerAll();

  runApp(const App());
}
