import 'dart:async';

import 'package:flutter/material.dart';

/// Loading 事件类型枚举。
///
/// Loading event type enum.
enum LoadingEventType {
  /// 显示loading
  /// show loading
  show,

  /// 关闭loading
  /// dismiss loading
  dismiss,
}

/// 内部管道中携带的 loading 事件数据。
///
/// Loading event data carried by the internal pipeline.
class LoadingEvent {
  const LoadingEvent._({required this.type, this.status});

  /// show event
  const LoadingEvent.show({String? status})
    : this._(type: LoadingEventType.show, status: status);

  /// dismiss event
  const LoadingEvent.dismiss() : this._(type: LoadingEventType.dismiss);

  final LoadingEventType type;
  final String? status;
}

/// Loading 服务基类——统一 API + 内部事件管道。
///
/// 与 [ToastService] 相同的模式：每个 service **就是**调用入口。
/// `show()` / `dismiss()` 直接在 service 实例上调用。
///
/// ## 如何创建自定义实现
///
/// 1. 继承 [LoadingService]。
///
/// 2. 实现 [build]——用加载库的 wrapper 包裹 child。
///
/// 3. 实现 [onEvent]——事件到达时渲染实际的 loading。
///
/// 4. 注册到 DI。
///
/// Loading service base class — unified API + internal event pipeline.
///
/// Same pattern as [ToastService]: each service **is** the entry point.
/// `show()` / `dismiss()` are called directly on the service instance.
///
/// ## How to create a custom implementation
///
/// 1. Extend [LoadingService].
///
/// 2. Implement [build] — wrap child with your loading library's wrapper.
///
/// 3. Implement [onEvent] — render the actual loading when an event arrives.
///
/// 4. Register in DI.
abstract class LoadingService {
  /// 创建带内部事件管道的 loading 服务。
  ///
  /// Creates a loading service with its own internal event pipeline.
  LoadingService();

  final StreamController<LoadingEvent> _events =
      StreamController<LoadingEvent>.broadcast();

  /// Loading 事件流。[NotifiersHost] 监听此流。
  ///
  /// Stream of loading events. [NotifiersHost] listens to this.
  Stream<LoadingEvent> get effects => _events.stream;

  // ── 统一 API——调用方只关心这些 / Unified API — callers care about these ──

  /// 显示加载指示器，可选 [status] 文字。
  ///
  /// Shows the loading indicator with optional [status] text.
  void show({String? status}) => _events.add(LoadingEvent.show(status: status));

  /// 关闭加载指示器。
  ///
  /// Dismisses the loading indicator.
  void dismiss() => _events.add(const LoadingEvent.dismiss());

  // ── 子类契约 / Subclass contract ────────────────────────────────────

  /// 用所需的 builder/wrapper 包裹 child 组件。
  ///
  /// Wraps the child widget with any needed builder/wrapper.
  Widget build(BuildContext context, Widget child);

  /// 事件到达时渲染实际的 loading。
  /// Context 由 [NotifiersHost] 提供。
  ///
  /// Renders the actual loading when an event arrives.
  /// Context is provided by [NotifiersHost].
  void onEvent(BuildContext context, LoadingEvent event);

  /// 释放内部管道。应用关闭时调用一次。
  ///
  /// Disposes the internal pipeline. Call once when the app shuts down.
  void dispose() {
    unawaited(_events.close());
  }
}
