import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../loading_service.dart';

/// 基于 EasyLoading 的 loading 服务。
///
/// 这是默认的 loading 实现者。它在 [build] 中用 [FlutterEasyLoading] 包裹 child，
/// 并使用 [EasyLoading.show/dismiss] 进行渲染。
///
/// 要切换到其他 loading 库，创建新的 [LoadingService] 实现者
/// 并在 DI 中注册即可。
///
/// EasyLoading-based loading service.
///
/// This is the default loading implementer. It wraps the child with
/// [FlutterEasyLoading] in [build] and uses [EasyLoading.show/dismiss]
/// for rendering.
///
/// To swap to a different loading library, create a new [LoadingService]
/// implementer and register it in DI instead.
class EasyLoadingLoadingService extends LoadingService {
  /// 创建基于 EasyLoading 的 loading 服务。
  ///
  /// Creates an EasyLoading-based loading service.
  EasyLoadingLoadingService();

  @override
  Widget build(BuildContext context, Widget child) {
    return FlutterEasyLoading(child: child);
  }

  @override
  void onEvent(BuildContext context, LoadingEvent event) {
    if (event.type == LoadingEventType.dismiss) {
      unawaited(EasyLoading.dismiss());
    } else {
      unawaited(
        EasyLoading.show(
          status: event.status ?? 'Loading...',
          dismissOnTap: false,
          maskType: EasyLoadingMaskType.black,
        ),
      );
    }
  }
}
