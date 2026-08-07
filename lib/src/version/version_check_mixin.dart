// 命令版本检查提示 mixin / Version-check hint mixin for commands.
//
// 通过组合复用 [VersionCheckService]：缓存命中且存在更新时瞬时提示（无 spinner）；
// 缓存未命中/过期时以 [runWithSpinner] 包裹一次网络检查，仅在确有更新时提示。
// 仅提示、不阻断主流程；无更新 / 网络异常均静默降级。
//
// 设计要点：mixin 与命令处于不同 library，Dart 跨库无法访问命令的私有成员，
// 故要求命令通过公开 getter 暴露 [logger] 与 [versionCheckService]。

import 'package:args/command_runner.dart';
import 'package:fluzer/src/i18n/gen/strings.g.dart';
import 'package:mason_logger/mason_logger.dart';

import '../logging/spinner.dart';
import 'version_check.dart';

/// 为命令提供「启动版本检查提示」能力的 mixin。
///
/// Mixin that lets a command surface a version-update hint at startup.
mixin VersionCheckMixin on Command<int> {
  /// 命令必须暴露的 logger（命令内部用私有 `_logger` 实现该 getter 即可）。
  ///
  /// Logger the command must expose (backed by its private `_logger` field).
  Logger get logger;

  /// 命令必须暴露的版本检查服务（命令内部用私有 `_versionCheckService` 实现即可）。
  ///
  /// The version-check service the command must expose.
  VersionCheckService get versionCheckService;

  /// 命令必须暴露的本地化消息（命令内部用私有 `_messages` 实现即可）。
  ///
  /// The localized messages the command must expose.
  Translations get messages;

  /// 在命令主体执行前调用，确保用户获知可能的版本更新。
  ///
  /// - 缓存命中且存在更新：瞬时提示（无 spinner，不打扰主流程）；
  /// - 缓存未命中/过期：以 spinner 包裹一次网络检查，确有更新才提示；
  /// - 无更新 / 网络不可用：静默降级，不打印任何内容，不阻断主流程。
  ///
  /// Call before the command body to make sure users learn about available
  /// updates. Silent when there is no update or the check is unavailable.
  Future<void> ensureUpdateNotified() async {
    final cached = versionCheckService.peekCachedUpdate();
    if (cached != null) {
      if (cached.hasUpdate) {
        logger.info(messages.version.updateHint(latest: cached.latest));
      } else {
        logger.detail(messages.versionCheck.cacheLatest);
      }
      return;
    }

    // 缓存未命中：用 spinner 覆盖 pub.dev 网络等待（--log 模式下由 logger.level
    // 控制不显示 spinner，直接执行）；结果打印在 work 闭包外，避免破坏动画行。
    final result = await runWithSpinner<VersionCheckResult>(
      logger: logger,
      messages: messages,
      message: messages.version.checking,
      work: () => versionCheckService.checkForUpdate(),
    );
    if (result.hasUpdate) {
      logger.info(messages.version.updateHint(latest: result.latest));
    } else {
      logger.detail(messages.versionCheck.pubdevLatest);
    }
  }
}
