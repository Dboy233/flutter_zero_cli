import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../toast_service.dart';

/// 基于 EasyLoading 的 toast 服务（移动端默认实现）。
///
/// 使用 [EasyLoading.showToast] / [EasyLoading.showSuccess] /
/// [EasyLoading.showError] / [EasyLoading.showInfo] 进行渲染。
///
/// EasyLoading 自带的 toast 使用自己的 overlay——无需额外的 wrapper 组件。
///
/// 要切换移动端 toast 实现，在 DI 中注册不同的 [ToastService] 子类即可。
///
/// EasyLoading-based toast service (mobile default).
///
/// Uses [EasyLoading.showToast] / [EasyLoading.showSuccess] /
/// [EasyLoading.showError] / [EasyLoading.showInfo] for rendering.
///
/// EasyLoading's built-in toast uses its own overlay — no extra
/// wrapper widget is needed.
///
/// To swap the mobile toast implementation, register a different
/// [ToastService] subclass in DI.
class EasyLoadingToastService extends ToastService {
  /// 创建基于 EasyLoading 的 toast 服务。
  ///
  /// Creates an EasyLoading-based toast service.
  EasyLoadingToastService();

  @override
  Widget build(BuildContext context, Widget child) {
    // EasyLoading 的 toast 使用自己的 overlay，无需 wrapper。
    // EasyLoading's toast uses its own overlay, no wrapper needed.
    return child;
  }

  @override
  void onEvent(BuildContext context, ToastEvent event) {
    switch (event.type) {
      case ToastEventType.error:
        unawaited(EasyLoading.showError(event.message!));
      case ToastEventType.success:
        unawaited(EasyLoading.showSuccess(event.message!));
      case ToastEventType.info:
        unawaited(EasyLoading.showInfo(event.message!));
      case ToastEventType.warning:
        unawaited(
          EasyLoading.showToast(
            event.message!,
            toastPosition: EasyLoadingToastPosition.center,
          ),
        );
      case ToastEventType.dismiss:
        unawaited(EasyLoading.dismiss());
    }
  }
}
