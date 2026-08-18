// 命令基类（Template Method）。
//
// 封装所有命令的公共流程：把解析参数打包成上下文 → 委托 [execute] 执行整条命令。
// 基类不假设任何「版本 / 适配器 / 启动提示」语义：
//  - 版本差异交给子类（[AdapterCommand] 按模板版本选适配器，其余命令直接实现
//    [execute]）；
//  - 「启动版本检查提示」这一横切关注点已抽离为独立顶层函数 [ensureUpdateNotified]，
//    由各命令在 [execute] 中显式 opt-in 调用，避免基类强塞导致不需要提示的命令
//    （如 `version` 自身会双查）被迫执行。
// 命令入口零版本硬编码。
//
// Base command (Template Method).
//
// Encapsulates the common flow shared by all commands: wrap parsed args into a
// context → delegate the whole command to [execute]. The base assumes nothing
// about versions/adapters/startup-hints: version differences are left to
// subclasses ([AdapterCommand] picks an adapter by template version); the
// "startup version-check notice" cross-cutting concern is extracted into the
// standalone top-level [ensureUpdateNotified], which each command opts into
// explicitly from [execute] so commands that must not notify (e.g. `version`,
// which runs its own check) are never forced to.

import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fluzer/src/config/project_config.dart';
import 'package:fluzer/src/i18n/gen/strings.g.dart';
import 'package:fluzer/src/version/version_check.dart';
import 'package:mason_logger/mason_logger.dart';

/// 命令基类。
///
/// [C] 为该命令的上下文类型（由 [buildContext] 构造、[execute] 消费）。
///
/// Base command.
///
/// [C] is this command's context type (built by [buildContext], consumed by
/// [execute]).
abstract class BaseCommand<C> extends Command<int> {
  /// 创建命令基类。
  ///
  /// [logger] / [messages] / [versionCheckService] 为必填：外部（[Fluzer]）统一注入，
  /// 不再各自兜底默认值，避免子类与基类双重默认。[versionCheckService] 供需要
  /// 启动版本提示的命令在 [execute] 中显式调用 [ensureUpdateNotified]。
  ///
  /// Creates the base command.
  ///
  /// [logger] / [messages] / [versionCheckService] are required: the external
  /// [Fluzer] injects them once so no fallback default lives in the base, which
  /// avoids the subclass/base double-default. [versionCheckService] is retained so
  /// commands that opt into the startup notice can call [ensureUpdateNotified].
  BaseCommand({
    required this.logger,
    required this.translations,
    required this.versionCheckService,
    this.workingDirectory,
  });

  /// 日志器（命令构造注入；供 [execute] 中显式调用 [ensureUpdateNotified]）。
  final Logger logger;

  /// 本地化消息（命令构造注入）。
  final Translations translations;

  /// 版本检查服务（供命令显式 opt-in 启动版本提示；不需要的命令可忽略）。
  ///
  /// Version-check service (commands opt in to the startup notice; commands
  /// that don't need it can simply ignore it).
  final VersionCheckService versionCheckService;

  /// 工作目录查找起点（向上查找项目根 / 拼接目标目录的基准）。
  /// 省略时回退到当前工作目录。
  ///
  /// Start dir for walking up to the project root / the base for target dirs.
  /// Defaults to the current directory.
  final Directory? workingDirectory;

  @override
  Future<int> run() async {
    try {
      final ctx = await buildContext(argResults!);
      return await execute(ctx);
    } on CliException catch (e) {
      logger.err(e.message);
      return 1;
    } on Object catch (e) {
      logger.err('命令执行出错: $e');
      return 1;
    }
  }

  /// 把解析后的参数打包成本命令的上下文。
  ///
  /// Wraps parsed args into this command's context.
  Future<C> buildContext(ArgResults args);

  /// 执行本命令（上下文已就绪）。
  ///
  /// 需要启动版本提示的命令应在此开头显式调用 [ensureUpdateNotified]（见各
  /// 命令子类）；不需要的命令（如 [VersionCommand] 自身执行检查）则直接执行。
  ///
  /// Executes this command (context already built).
  ///
  /// Commands that want the startup version notice should call
  /// [ensureUpdateNotified] at the start (see command subclasses); commands
  /// that don't (e.g. [VersionCommand] runs its own check) just execute.
  Future<int> execute(C ctx);
}
