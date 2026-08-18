// 版本感知命令基类（AdapterCommand）。
//
// 在 [BaseCommand] 之上增加「读取模板自带版本 → 沿本命令的适配器链选择认领者
// → 委托适配器执行整条命令」的 Template Method。版本差异被完全下沉到各命令
// 自己的适配器实现中，命令入口零版本硬编码。
//
// 适用于 `new` / `gen-l10n` 这类「行为随模板版本变化」的命令；其余命令
// 直接继承 [BaseCommand] 即可。
//
// Version-aware command base (AdapterCommand).
//
// Adds, on top of [BaseCommand], the "read the template's own version → walk
// this command's adapter chain to pick the claimant → delegate the full
// command to that adapter" Template Method. Version differences are pushed
// entirely into each command's own adapters; the entry point has zero
// version-specific hard-coding.
//
// For commands whose behavior varies with the template version (`new` /
// `gen-l10n`); other commands extend [BaseCommand] directly.

import 'dart:io';

import 'package:args/args.dart';
import 'package:fluzer/src/commands/base_command.dart';
import 'package:fluzer/src/commands/command_adapter.dart';
import 'package:fluzer/src/commands/command_context.dart';
import 'package:fluzer/src/template/template_version_reader.dart';
import 'package:fluzer/src/commands/version/version_spec.dart';
import 'package:fluzer/src/util/semantic_version.dart';

/// 版本感知命令基类。
///
/// [C] 为该命令的上下文类型（须 extends [CommandContext]，以便携带版本）。
///
/// Version-aware command base.
///
/// [C] is this command's context type (must extend [CommandContext] so it can
/// carry the version).
abstract class AdapterCommand<C extends CommandContext> extends BaseCommand<C> {
  /// 创建版本感知命令基类。
  ///
  /// [versionReader] 由 [translations] 派生（读模板自带 version 声明），无需调用方传入。
  ///
  /// Creates the version-aware command base.
  ///
  /// [versionReader] is derived from [translations] (reads the template's own
  /// version declaration), so callers need not supply it.
  AdapterCommand({
    required super.logger,
    required super.translations,
    required super.versionCheckService,
    super.workingDirectory,
  }) : versionReader = TemplateVersionReader(translations: translations);

  /// 模板版本读取器（读模板自带 version 声明）。
  ///
  /// Template version reader (reads the template's own version宣告).
  final TemplateVersionReader versionReader;

  @override
  Future<C> buildContext(ArgResults args) async {
    final info = await versionReader.read(
      workingDirectory ?? Directory.current,
    );
    return buildAdapterContext(args, info);
  }

  /// 用模板版本信息构建上下文（子类实现）。
  ///
  /// Builds the context from template version info (implemented by subclasses).
  C buildAdapterContext(ArgResults args, ProjectVersionInfo info);

  @override
  Future<int> execute(C ctx) async {
    final adapter = selectAdapter(ctx);
    if (adapter == null) {
      final v = ctx.version;
      final msg = v >= maxSupportedVersion
          ? translations.unsupportedTooNew(
              version: v.toString(),
              maxSupported: maxSupportedVersion.toString(),
            )
          : translations.unsupportedTooOld(version: v.toString());
      logger.err(msg);
      return 1;
    }
    return adapter.run(ctx);
  }

  /// 本命令的适配器链（按版本从旧到新排列）。
  ///
  /// This command's adapter chain (oldest to newest version).
  List<CommandAdapter<C>> get adapters;

  /// 沿适配器链选择认领 [ctx.version] 的适配器；
  /// 全不命中（当前 CLI 不支持该模板版本）时返回 null，
  /// 由 [execute] 直接打印「不支持版本」报错并返回退出码 1。
  ///
  /// Walks the adapter chain to pick the claimant of [ctx.version]; when none
  /// matches (the CLI cannot handle this template version), returns null so
  /// [execute] prints an "unsupported version" error and exits with code 1.
  CommandAdapter<C>? selectAdapter(C ctx) {
    for (final adapter in adapters) {
      if (adapter.canHandle(ctx.version)) return adapter;
    }
    return null;
  }

  /// 本命令已知支持的最高模板版本（不含，即能力上界）。
  /// 由 [adapters] 各 [RangeSpec.upper] 推导，作为单一事实源，避免重复写版本号。
  ///
  /// The highest template version (exclusive) this command supports—its
  /// capability ceiling. Derived from each adapter's [RangeSpec.upper] so the
  /// version number lives in exactly one place.
  SemanticVersion get maxSupportedVersion {
    var max = SemanticVersion(0, 0, 0);
    for (final adapter in adapters) {
      final spec = adapter.spec;
      if (spec is RangeSpec && spec.upper != null && spec.upper! > max) {
        max = spec.upper!;
      }
    }
    return max;
  }
}
