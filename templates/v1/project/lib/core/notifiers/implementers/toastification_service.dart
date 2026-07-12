import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../desktop_toast_service.dart';
import '../toast_service.dart';

/// 基于 Toastification 的 toast 服务（桌面端默认实现）。
///
/// 继承 [DeskTopToastService]——一个类型标记，使得桌面端和移动端
/// toast 服务可以在 DI 中共存。
///
/// 用 [ToastificationWrapper] 包裹 child，使用 [Toastification().show] 渲染。
/// Toastification 的 UI 更适合桌面/横屏布局。
///
/// 要切换桌面端 toast 实现，在 DI 中注册不同的 [DeskTopToastService] 子类即可。
///
/// Toastification-based toast service (desktop default).
///
/// This extends [DeskTopToastService] — a type marker that allows
/// desktop and mobile toast services to coexist in DI.
///
/// Wraps the child with [ToastificationWrapper] and uses
/// [Toastification().show] for rendering. Toastification's UI is
/// better suited for desktop/landscape layouts.
///
/// To swap the desktop toast implementation, register a different
/// [DeskTopToastService] subclass in DI.
class ToastificationToastService extends DeskTopToastService {
  /// 创建基于 toastification 的 toast 服务。
  ///
  /// Creates a toastification-based toast service.
  ToastificationToastService();

  @override
  Widget build(BuildContext context, Widget child) {
    return ToastificationWrapper(child: child);
  }

  @override
  void onEvent(BuildContext context, ToastEvent event) {
    switch (event.type) {
      case ToastEventType.dismiss:
        toastification.dismissAll();
      default:
        toastification.show(
          context: context,
          alignment: Alignment.topCenter,
          type: _mapType(event.type),
          style: ToastificationStyle.fillColored,
          title: Text(event.message!),
          autoCloseDuration: const Duration(seconds: 3),
          showProgressBar: false,
          dragToClose: true,
        );
    }
  }

  /// 将 [ToastEventType] 映射为 [ToastificationType]。
  ///
  /// Maps [ToastEventType] to [ToastificationType].
  ToastificationType _mapType(ToastEventType type) => switch (type) {
    ToastEventType.error => ToastificationType.error,
    ToastEventType.success => ToastificationType.success,
    ToastEventType.info => ToastificationType.info,
    ToastEventType.warning => ToastificationType.warning,
    ToastEventType.dismiss => ToastificationType.info,
  };
}
