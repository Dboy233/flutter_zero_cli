// `gen-l10n` 命令适配器基类 + 依赖包（Template Method 宿主）。
//
// 版本专属适配器（gen_l10n_v1v2 / gen_l10n_fallback）各自独立成文件，
// 本文件只承载「与版本无关的固定管线」+ 依赖注入。
//
// `gen-l10n` command adapter base + dependency bundle (Template Method host).
//
// Version-specific adapters (gen_l10n_v1v2 / gen_l10n_fallback) live in their
// own files; this file only holds the version-independent pipeline + DI.

import 'dart:io';

import 'package:fluzer/src/commands/command_adapter.dart';
import 'package:fluzer/src/commands/gen_l10n/gen_l10n_context.dart';
import 'package:fluzer/src/gen_l10n/toast_handle_patcher.dart';
import 'package:fluzer/src/i18n/gen/strings.g.dart';
import 'package:fluzer/src/process/process_runner.dart';
import 'package:fluzer/src/version/version_check.dart';
import 'package:mason_logger/mason_logger.dart';

/// `gen-l10n` 命令 flutter gen-l10n 执行器签名。
///
/// `gen-l10n` command flutter gen-l10n executor signature.
typedef FlutterGenL10nRunner = Future<int> Function(String projectRoot);

/// `gen-l10n` 适配器依赖（构造注入）。
///
/// `gen-l10n` adapter dependencies (constructor injection).
class GenL10nAdapterDeps {
  /// 创建依赖包。
  ///
  /// Creates the dependency bundle.
  const GenL10nAdapterDeps({
    required this.logger,
    required this.translations,
    required this.processRunner,
    required this.patcher,
    required this.flutterGenL10nFn,
    required this.workingDirectory,
    required this.versionCheckService,
  });

  /// 日志器。
  ///
  /// Logger.
  final Logger logger;

  /// 本地化消息。
  ///
  /// Localized messages.
  final Translations translations;

  /// 进程执行器。
  ///
  /// Process runner.
  final ProcessRunner processRunner;

  /// Toast handle 补丁器。
  ///
  /// Toast-handle patcher.
  final ToastHandlePatcher patcher;

  /// flutter gen-l10n 执行器。
  ///
  /// flutter gen-l10n executor.
  final FlutterGenL10nRunner flutterGenL10nFn;

  /// 项目根目录查找起点。
  ///
  /// Start dir for walking up to the project.
  final Directory? workingDirectory;

  final VersionCheckService versionCheckService;
}

/// `gen-l10n` 适配器基类（Template Method + Strategy）。
///
/// 固化「校验 → 解析 l10n → flutter gen-l10n → 解析成员 → 生成代码 → 接线」
/// 通用流程；当前 1.x~2.x 结构一致，子类仅通过规格区分区间。
///
/// `gen-l10n` adapter base (Template Method + Strategy).
///
/// Fixes the common "validate → parse l10n → flutter gen-l10n → parse members
/// → generate code → wire" flow; since 1.x~2.x share structure, subclasses
/// differ only by their version spec.
abstract class BaseGenL10nAdapter
    extends CommandAdapter<GenL10nCommandContext> {
  /// 创建基类适配器。
  ///
  /// Creates the base adapter.
  BaseGenL10nAdapter({required this.deps, required super.spec});

  /// 依赖包。
  ///
  /// Dependency bundle.
  final GenL10nAdapterDeps deps;
}
