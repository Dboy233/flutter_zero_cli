import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 应用级滚动行为，扩展桌面端拖拽支持。
///
/// 默认的 [MaterialScrollBehavior] 仅允许触控拖拽，桌面端用户无法
/// 用鼠标/触控板直接拖拽可滚动区域。此行为扩展 [dragDevices]，
/// 使鼠标、触控板、手写笔等设备均能通过拖拽手势滚动。
///
/// 使用方式：在 [MaterialApp.scrollBehavior] 或
/// [MaterialApp.router] 的 `scrollBehavior` 参数中传入
/// `const AppScrollBehavior()`。
///
///
/// App-level scroll behavior with extended desktop drag support.
///
/// The default [MaterialScrollBehavior] only allows touch dragging.
/// Desktop users cannot directly drag-scroll scrollable areas with
/// a mouse or trackpad. This behavior extends [dragDevices] so that
/// mice, trackpads, styluses, and other pointer devices can scroll
/// via drag gestures.
///
/// Usage: pass `const AppScrollBehavior()` to
/// [MaterialApp.scrollBehavior] or the `scrollBehavior` parameter
/// of [MaterialApp.router].
class AppScrollBehavior extends MaterialScrollBehavior {
  /// 创建 [AppScrollBehavior]。
  ///
  /// 使用 `const` 构造函数以避免每次 rebuild 时创建新实例。
  ///
  ///
  /// Creates an [AppScrollBehavior].
  ///
  /// Use the `const` constructor to avoid creating a new instance
  /// on every rebuild.
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
    // The VoiceAccess sends pointer events with unknown type when
    // scrolling scrollables.
    PointerDeviceKind.unknown,
  };
}
