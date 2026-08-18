// 启动版本检查提示（独立工具函数）。
//
// 把「启动版本提示」这一横切关注点从命令基类的 mixin 抽离为独立顶层函数，
// 由需要提示的命令显式 opt-in 调用。这样做的原因：
//  - 原 [VersionCheckMixin] 被强塞进 [BaseCommand] 并自动执行，导致不依赖项目、
//    或自身已做版本检查的命令（如 `version` 命令）被迫重复检查（双查隐患）；
//  - 抽成函数后，调用关系一目了然：仅 `new` / `gen-l10n` / `create` 在 [execute]
//    开头调用，`version` 自行检查、`cache` 不检查，各命令行为可独立推理。
//
// 行为（与原 mixin 一致）：仅提示、不阻断主流程；无更新 / 网络异常均静默降级。
//  - 缓存命中且存在更新：瞬时提示（无 spinner，不打扰主流程）；
//  - 缓存未命中/过期：以 spinner 包裹一次网络检查，确有更新才提示；
//  - 无更新 / 网络不可用：静默降级，不打印任何内容，不阻断主流程。
//
// Startup version-check notice (standalone utility function).
//
// Extracting the "startup version notice" cross-cutting concern out of the
// command base mixin into a standalone top-level function lets each command
// opt in explicitly. The original [VersionCheckMixin] was forced onto
// [BaseCommand] and ran automatically, which made commands that don't need the
// project (or already check versions themselves, e.g. `version`) run a redundant
// check. As a function, the call graph is explicit: only `new` / `gen-l10n` /
// `create` call it at the start of [execute]; `version` checks on its own and
// `cache` never checks, so every command's behavior is independently reasoned.

import 'package:fluzer/src/i18n/gen/strings.g.dart';
import 'package:fluzer/src/util/spinner.dart';
import 'package:fluzer/src/version/version_check.dart';
import 'package:mason_logger/mason_logger.dart';

/// 在命令主体执行前调用，确保用户获知可能的版本更新。
///
/// 由调用方（需要提示的命令）显式传入 [logger] / [translations] / [versionCheckService]，
/// 不再依赖命令继承关系，因此 `version` 命令可安全不调用（避免与自身
/// `checkForUpdate` 双查）。
///
/// Call before a command body to make sure users learn about available updates.
///
/// The caller (the command that wants the notice) passes [logger] / [translations] /
/// [versionCheckService] explicitly instead of relying on inheritance, so the
/// `version` command can safely skip it (avoiding a double check with its own
/// `checkForUpdate`).
Future<void> ensureUpdateNotified({
  required Logger logger,
  required Translations translations,
  required VersionCheckService versionCheckService,
}) async {
  final cached = versionCheckService.peekCachedUpdate();
  if (cached != null) {
    if (cached.hasUpdate) {
      logger.info(translations.version.updateHint(latest: cached.latest));
    } else {
      logger.detail(translations.versionCheck.cacheLatest);
    }
    return;
  }

  // 缓存未命中：用 spinner 覆盖 pub.dev 网络等待（--log 模式下由 logger.level
  // 控制不显示 spinner，直接执行）；结果打印在 work 闭包外，避免破坏动画行。
  final result = await runWithSpinner<VersionCheckResult>(
    logger: logger,
    translations: translations,
    message: translations.version.checking,
    work: () => versionCheckService.checkForUpdate(),
  );
  if (result.hasUpdate) {
    logger.info(translations.version.updateHint(latest: result.latest));
  } else {
    logger.detail(translations.versionCheck.pubdevLatest);
  }
}
