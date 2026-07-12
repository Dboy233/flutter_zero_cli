import 'toast_service.dart';

/// 桌面端 toast 服务——用于 DI 区分的类型标记。
///
/// 这是一个纯粹的类型标记。它从 [ToastService] 继承了所有公开 API
/// （[showError]、[showSuccess] 等），不添加任何新方法。
///
/// ## 用法
///
/// ```dart
/// // DI — mobile default + desktop variant coexist
/// getIt.registerLazySingleton<ToastService>(EasyLoadingToastService.new);
/// getIt.registerLazySingleton<DeskTopToastService>(ToastificationToastService.new);
///
/// // Caller
/// getIt<ToastService>().showError('mobile style');
/// getIt<DeskTopToastService>().showError('desktop style');
/// ```
///
/// ## 创建桌面端实现
///
/// 继承 [DeskTopToastService] 而不是 [ToastService]：
///
/// ```dart
/// class MyDesktopToast extends DeskTopToastService {
///   // build + onEvent
/// }
/// ```
///
/// Desktop-style toast service — type marker for DI differentiation.
///
/// This is a pure type marker. It inherits all public API ([showError],
/// [showSuccess], etc.) from [ToastService] without adding any new methods.
///
/// ## Usage
///
/// ```dart
/// // DI — mobile default + desktop variant coexist
/// getIt.registerLazySingleton<ToastService>(EasyLoadingToastService.new);
/// getIt.registerLazySingleton<DeskTopToastService>(ToastificationToastService.new);
///
/// // Caller
/// getIt<ToastService>().showError('mobile style');
/// getIt<DeskTopToastService>().showError('desktop style');
/// ```
///
/// ## Creating desktop implementations
///
/// Extend [DeskTopToastService] instead of [ToastService]:
///
/// ```dart
/// class MyDesktopToast extends DeskTopToastService {
///   // build + onEvent
/// }
/// ```
abstract class DeskTopToastService extends ToastService {
  /// 创建桌面端 toast 服务。
  ///
  /// Creates a desktop-style toast service.
  DeskTopToastService();
}
