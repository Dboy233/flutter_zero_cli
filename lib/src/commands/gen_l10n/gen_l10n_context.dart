// `gen-l10n` 命令上下文。
//
// 在基类 [CommandContext] 之上补充 handle-patch 两个开关。
//
// `gen-l10n` command context.

import 'package:fluzer/src/commands/command_context.dart';

/// `gen-l10n` 命令上下文。
///
/// Adds the handle-patch toggles on top of [CommandContext].
class GenL10nCommandContext extends CommandContext {
  /// 创建上下文。
  ///
  /// Creates the context.
  const GenL10nCommandContext({
    required super.version,
    required super.projectRoot,
    this.skipHandlePatch = false,
    this.forceHandlePatch = false,
  });

  /// 是否跳过 `defaultToastHandle` 接线（`--skip-handle-patch`）。
  ///
  /// Whether to skip `defaultToastHandle` wiring (`--skip-handle-patch`).
  final bool skipHandlePatch;

  /// 是否强制接线（`--force-handle-patch`）。
  ///
  /// Whether to force wiring (`--force-handle-patch`).
  final bool forceHandlePatch;
}
