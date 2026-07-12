import 'dart:async';

import 'package:flutter/material.dart';

/// Toast 事件类型枚举。
///
/// Toast event type enum.
enum ToastEventType { error, success, info, warning, dismiss }

/// 内部管道中携带的 toast 事件数据。
///
/// Toast event data carried by the internal pipeline.
class ToastEvent {
  const ToastEvent._({required this.type, this.message});

  const ToastEvent.error(String msg)
    : this._(type: ToastEventType.error, message: msg);

  const ToastEvent.success(String msg)
    : this._(type: ToastEventType.success, message: msg);

  const ToastEvent.info(String msg)
    : this._(type: ToastEventType.info, message: msg);

  const ToastEvent.warning(String msg)
    : this._(type: ToastEventType.warning, message: msg);

  const ToastEvent.dismiss() : this._(type: ToastEventType.dismiss);

  final ToastEventType type;
  final String? message;
}

/// Toast 服务基类——统一 API + 内部事件管道。
///
/// ## 为什么这样设计
///
/// 每个 service **就是**调用入口。`showError()` / `showSuccess()` 等直接
/// 在 service 实例上调用，不需要经过单独的 controller。
/// 内部 [Stream] 将调用从无 context 环境（BLoC）桥接到有 context 环境（Host Widget），
/// 使得 Toastification 这类需要 [BuildContext] 的实现也能正常工作，
/// 而调用方完全不需要接触 context。
///
/// ## 如何创建自定义实现
///
/// 1. 继承 [ToastService]（桌面端用 [DeskTopToastService]）。
///
/// 2. 实现 [build]——如果库需要 wrapper 组件则包裹 child。
///
/// 3. 实现 [onEvent]——事件到达时渲染实际的 toast。
///
/// 4. 以期望的类型注册到 DI。
///
/// ```dart
/// class MyCustomToast extends ToastService {
///   // build + onEvent
/// }
/// getIt.registerLazySingleton<ToastService>(MyCustomToast.new);
/// getIt<ToastService>().showError('error'); // caller API unchanged
/// ```
///
/// Toast service base class — unified API + internal event pipeline.
///
/// ## Why this design
///
/// Each service **is** the entry point for callers. `showError()` / `showSuccess()`
/// etc. are called directly on the service instance, not on a separate controller.
/// The internal [Stream] bridges calls from context-free environments (BLoC) to
/// context-aware environments (Host Widget), so that implementations like
/// Toastification which require [BuildContext] can work without the caller
/// ever touching context.
///
/// ## How to create a custom implementation
///
/// 1. Extend [ToastService]（or [DeskTopToastService] for desktop-style toasts）.
///
/// 2. Implement [build] — wrap child if your library needs a wrapper widget.
///
/// 3. Implement [onEvent] — render the actual toast when an event arrives.
///
/// 4. Register in DI under the desired type.
///
/// ```dart
/// class MyCustomToast extends ToastService {
///   // build + onEvent
/// }
/// getIt.registerLazySingleton<ToastService>(MyCustomToast.new);
/// getIt<ToastService>().showError('error'); // caller API unchanged
/// ```
abstract class ToastService {
  /// 创建带内部事件管道的 toast 服务。
  ///
  /// Creates a toast service with its own internal event pipeline.
  ToastService();

  final StreamController<ToastEvent> _effects =
      StreamController<ToastEvent>.broadcast();

  /// Toast 事件流。[NotifiersHost] 监听此流。
  ///
  /// Stream of toast events. [NotifiersHost] listens to this.
  Stream<ToastEvent> get effects => _effects.stream;

  // ── 统一 API——调用方只关心这些 / Unified API — callers care about these ──

  /// 显示错误 toast。
  ///
  /// Shows an error toast.
  void showError(String message) => _effects.add(ToastEvent.error(message));

  /// 显示成功 toast。
  ///
  /// Shows a success toast.
  void showSuccess(String message) => _effects.add(ToastEvent.success(message));

  /// 显示信息 toast。
  ///
  /// Shows an info toast.
  void showInfo(String message) => _effects.add(ToastEvent.info(message));

  /// 显示警告 toast。
  ///
  /// Shows a warning toast.
  void showWarning(String message) => _effects.add(ToastEvent.warning(message));

  /// 关闭所有可见 toast。
  ///
  /// Dismisses all visible toasts.
  void dismissAll() => _effects.add(const ToastEvent.dismiss());

  // ── 子类契约 / Subclass contract ────────────────────────────────────

  /// 用所需的 overlay/wrapper 层包裹 child 组件。
  ///
  /// Wraps the child widget with any needed overlay/wrapper layer.
  ///
  /// 如果不需要 wrapper 组件，直接返回 [child]。
  ///
  /// Return [child] directly if no wrapper widget is required.
  Widget build(BuildContext context, Widget child);

  /// 事件到达时渲染实际的 toast UI。
  /// Context 由 [NotifiersHost] 提供。
  ///
  /// Renders the actual toast UI when an event arrives.
  /// Context is provided by [NotifiersHost].
  void onEvent(BuildContext context, ToastEvent event);

  /// 释放内部管道。应用关闭时调用一次。
  ///
  /// Disposes the internal pipeline. Call once when the app shuts down.
  void dispose() {
    unawaited(_effects.close());
  }
}
