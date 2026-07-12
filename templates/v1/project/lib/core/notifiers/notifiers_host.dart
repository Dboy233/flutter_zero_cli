import 'dart:async';

import 'package:flutter/material.dart';

import 'loading_service.dart';
import 'toast_service.dart';

/// 统一通知宿主组件——订阅所有 service 的事件管道，
/// 并使用 [BuildContext] 委托渲染。
///
/// 适用场景：fire-and-forget UI 覆盖层——toast、loading HUD、应用内 banner。
/// 不适用于非 UI 副作用：redirect、音效、震动等。
///
/// 将此组件放在 [MaterialApp.builder] 中，使其位于 MaterialApp **内部**
/// （可访问 Directionality / Theme / MediaQuery），但在 Navigator **上层**
/// （toast / loading 遮罩覆盖所有页面）。
///
/// ## 用法
///
/// ```dart
/// MaterialApp.router(
///   builder: (context, child) => NotifiersHost(
///     toasts: [
///       getIt<ToastService>(),
///       getIt<DeskTopToastService>(),
///     ],
///     loadings: [
///       getIt<LoadingService>(),
///     ],
///     child: child!,
///   ),
/// )
/// ```
///
/// ## Wrapper 嵌套顺序
///
/// Loading wrapper 先包裹（内层），然后 toast wrapper 在外层。
/// 顺序很重要：loading 遮罩应在内容上方但在 toast 下方。
///
/// Unified notifiers host widget — subscribes to all services' event
/// pipelines and delegates rendering with [BuildContext].
///
/// Scope: fire-and-forget UI overlays — toast, loading HUD,
/// in-app banner. NOT for non-UI side effects like redirect, sound, haptic.
///
/// Place this in [MaterialApp.builder] so it sits **inside** MaterialApp
/// (with Directionality / Theme / MediaQuery available) but **above** the
/// Navigator (so toast / loading overlays cover all pages).
///
/// ## Usage
///
/// ```dart
/// MaterialApp.router(
///   builder: (context, child) => NotifiersHost(
///     toasts: [
///       getIt<ToastService>(),
///       getIt<DeskTopToastService>(),
///     ],
///     loadings: [
///       getIt<LoadingService>(),
///     ],
///     child: child!,
///   ),
/// )
/// ```
///
/// ## Wrapper nesting order
///
/// Loading wrapper is applied first (inside), then toast wrappers on top.
/// Order matters: loading overlays should be above content but below toasts.
class NotifiersHost extends StatefulWidget {
  /// 创建统一通知宿主组件。
  ///
  /// Creates a unified notifiers host widget.
  const NotifiersHost({
    required this.child,
    super.key,
    this.toasts = const [],
    this.loadings = const [],
  });

  /// 所有要监听的 toast 服务实例。
  ///
  /// All toast service instances to listen to.
  final List<ToastService> toasts;

  /// 所有要监听的 loading 服务实例。
  ///
  /// All loading service instances to listen to.
  final List<LoadingService> loadings;

  /// 要包裹的子组件。
  ///
  /// Child widget to wrap.
  final Widget child;

  @override
  State<NotifiersHost> createState() => _NotifiersHostState();
}

class _NotifiersHostState extends State<NotifiersHost> {
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    assert(
      widget.toasts.isNotEmpty || widget.loadings.isNotEmpty,
      'At least one toast or loading service must be provided.',
    );
    _subscribe();
  }

  @override
  void didUpdateWidget(NotifiersHost old) {
    super.didUpdateWidget(old);
    // 服务变更时重新订阅。
    // Resubscribe if services changed.
    if (old.toasts != widget.toasts || old.loadings != widget.loadings) {
      for (final s in _subscriptions) {
        unawaited(s.cancel());
      }
      _subscriptions.clear();
      _subscribe();
    }
  }

  void _subscribe() {
    for (final toast in widget.toasts) {
      _subscriptions.add(
        toast.effects.listen((event) {
          if (!mounted) return;
          toast.onEvent(context, event);
        }),
      );
    }
    for (final loading in widget.loadings) {
      _subscriptions.add(
        loading.effects.listen((event) {
          if (!mounted) return;
          loading.onEvent(context, event);
        }),
      );
    }
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget current = widget.child;

    // Loading wrapper 放在内层（更靠近内容）。
    // Loading wrappers go inside (closer to content).
    for (final loading in widget.loadings) {
      current = loading.build(context, current);
    }

    // Toast wrapper 放在外层（loading 之上）。
    // Toast wrappers go on top (above loading).
    for (final toast in widget.toasts) {
      current = toast.build(context, current);
    }

    return current;
  }
}
