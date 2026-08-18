// `new` 命令适配器基类 + 依赖包（Template Method 宿主）。
//
// 版本专属适配器（new_v1 / new_v2 / new_fallback）各自独立成文件，
// 本文件只承载「与版本无关的固定管线」+ 依赖注入，避免每个版本重复整条流程。
//
// `new` command adapter base + dependency bundle (Template Method host).
//
// Version-specific adapters (new_v1 / new_v2 / new_fallback) live in their own
// files; this file only holds the version-independent pipeline + DI, so each
// version doesn't have to duplicate the whole flow.

import 'dart:io';

import 'package:fluzer/src/commands/command_adapter.dart';
import 'package:fluzer/src/commands/new/new_context.dart';
import 'package:fluzer/src/i18n/gen/strings.g.dart';
import 'package:fluzer/src/process/process_runner.dart';
import 'package:fluzer/src/template/brick_loader.dart';
import 'package:mason_logger/mason_logger.dart';

/// `new` 适配器依赖（构造注入）。
///
/// `new` adapter dependencies (constructor injection).
class NewAdapterDeps {
  /// 创建依赖包。
  ///
  /// Creates the dependency bundle.
  const NewAdapterDeps({
    required this.logger,
    required this.translations,
    required this.loader,
    required this.processRunner,
    required this.workingDirectory,
  });

  /// 日志器。
  ///
  /// Logger.
  final Logger logger;

  /// 本地化消息。
  ///
  /// Localized messages.
  final Translations translations;

  /// Brick 加载器（测试可注入本地目录）；为 `null` 时由解析器下载。
  ///
  /// Brick loader (tests inject a local dir); falls back to download when null.
  final BrickLoader? loader;

  /// 进程执行器（默认 build_runner 用）。
  ///
  /// Process runner (for the default build_runner).
  final ProcessRunner processRunner;

  /// 项目根目录查找起点。
  ///
  /// Start dir for walking up to the project.
  final Directory? workingDirectory;
}

/// `new` 适配器基类（Template Method + Strategy）。
///
/// 固化「加载配置 → 解析 brick → 渲染 → 注册 → build_runner」通用流程，
/// 版本差异仅由 [diTargetPath] 钩子承载。
///
/// `new` adapter base (Template Method + Strategy).
///
/// Fixes the common "load config → resolve brick → render → register →
/// build_runner" flow; version differences live only behind [diTargetPath].
abstract class BaseNewAdapter extends CommandAdapter<NewCommandContext> {
  /// 创建基类适配器。
  ///
  /// Creates the base adapter.
  BaseNewAdapter({required this.deps, required super.spec});

  /// 依赖包。
  ///
  /// Dependency bundle.
  final NewAdapterDeps deps;

  String get diTargetPath => 'lib/core/di/injection_base.dart';
}
