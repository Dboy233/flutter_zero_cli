import 'package:get_it/get_it.dart';

/// 全局服务定位器实例。
///
/// 项目内统一通过本文件引用的 [getIt] 解析依赖，避免多处
/// 直接调用 [GetIt.instance]。
///
/// 在应用启动时调用 [Injection.registerAll] 完成注册，
/// 之后即可通过 [getIt<T>()] 获取已注册的服务。
///
/// Global service locator instance.
///
/// Use the [getIt] exported by this file throughout the project instead of
/// calling [GetIt.instance] directly in many places.
///
/// Register all dependencies via [Injection.registerAll] at start-up, then
/// resolve services with [getIt<T>()].
final GetIt getIt = GetIt.instance;
