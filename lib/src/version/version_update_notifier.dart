// 启动版本检查提示。
//
// 把「启动版本提示」这一横切关注点从命令基类的 mixin 抽离为独立类，
// 由需要提示的命令显式 opt-in 调用。这样做的原因：
//  - 原 [VersionCheckMixin] 被强塞进 [BaseCommand] 并自动执行，导致不依赖项目、
//    或自身已做版本检查的命令（如 `version` 命令）被迫重复检查（双查隐患）；
//  - 抽成类后，调用关系一目了然：仅 `new` / `gen-l10n` / `create` 在 [notify]
//    开头调用，`version` 自行检查、`cache` 不检查，各命令行为可独立推理。
//
// 行为（与原 mixin 一致）：仅提示、不阻断主流程；无更新 / 网络异常均静默降级。
//  - 缓存命中且存在更新：瞬时提示（不注册步骤，不打扰主流程）；
//  - 缓存未命中/过期：向调用方传入的 [StepRunner] 注册一个网络检查步骤，由命令
//    统一在 `runAll` 中串行执行，确有更新才提示；
//  - 无更新 / 网络不可用：静默降级，不打印任何内容，不阻断主流程。
//
// Startup version-check notice.
//
// Extracting the "startup version notice" cross-cutting concern out of the
// command base mixin into a standalone class lets each command opt in
// explicitly. The original [VersionCheckMixin] was forced onto [BaseCommand]
// and ran automatically, which made commands that don't need the project (or
// already check versions themselves, e.g. `version`) run a redundant check. As
// a class, the call graph is explicit: only `new` / `gen-l10n` / `create` call
// [notify]; `version` checks on its own and `cache` never checks, so every
// command's behavior is independently reasoned.

import 'package:fluzer/src/i18n/gen/strings.g.dart';
import 'package:fluzer/src/util/step_runner.dart';
import 'package:fluzer/src/version/version_check.dart';
import 'package:mason_logger/mason_logger.dart';

/// 启动版本检查提示器。
///
/// 由调用方（需要提示的命令）在构造时注入 [logger] / [translations] /
/// [versionCheckService]，不再依赖命令继承关系，因此 `version` 命令可安全
/// 不调用（避免与自身 `checkForUpdate` 双查）。
///
/// Startup version-check notifier. The caller (the command that wants the
/// notice) injects [logger] / [translations] / [versionCheckService] at
/// construction instead of relying on inheritance, so the `version` command
/// can safely skip it (avoiding a double check with its own `checkForUpdate`).
class VersionUpdateNotifier {
  /// 创建提示器。
  ///
  /// [logger] / [translations] / [versionCheckService] 为命令级固定注入。
  ///
  /// Creates the notifier. [logger] / [translations] / [versionCheckService]
  /// are the command-level fixed injections.
  VersionUpdateNotifier({
    required this._logger,
    required this._translations,
    required this._versionCheckService,
  });

  final Logger _logger;
  final Translations _translations;
  final VersionCheckService _versionCheckService;

  /// 在命令注册业务步骤前调用，确保用户获知可能的版本更新。
  ///
  /// 缓存命中时立即打印提示并返回（**不**向 [stepRunner] 注册步骤）；缓存未命中
  /// 时仅向 [stepRunner] **注册**一个网络检查步骤，真正的检查与提示发生在调用方
  /// 执行 [StepRunner.runAll] 时。因此该步骤会计入「步骤 i/N」编号，且编号是否
  /// 包含它取决于缓存是否命中。
  ///
  /// Call before a command registers its business steps so users learn about
  /// available updates. On a cache hit it prints immediately and returns
  /// without registering a step; on a cache miss it only *registers* a network
  /// check step on [stepRunner] — the actual check and notice happen when the
  /// caller runs [StepRunner.runAll].
  Future<void> notify(StepRunner stepRunner) async {
    final cached = await _versionCheckService.peekCachedUpdate();
    if (cached != null) {
      if (cached.hasUpdate) {
        _logger.info(_translations.version.updateHint(latest: cached.latest));
      } else {
        _logger.detail(_translations.versionCheck.cacheLatest);
      }
      return;
    }

    stepRunner.add(
      _translations.version.checking,
      () => _versionCheckService.checkForUpdate(),
      onDone: (result) {
        if (result.hasUpdate) {
          _logger.info(_translations.version.updateHint(latest: result.latest));
        } else {
          _logger.detail(_translations.versionCheck.pubdevLatest);
        }
      },
    );
  }
}
