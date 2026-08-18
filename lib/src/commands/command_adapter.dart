// 命令适配器抽象（Strategy + Adapter）。
//
// 每个大版本区间对应一个适配器，封装「该版本下整条命令的执行逻辑」
// （含渲染后把代码接回项目的版本相关集成步骤）。canHandle 由规格认领，
// run 携带行为执行，而非只返回被动模型。
//
// Command adapter abstraction (Strategy + Adapter).
//
// One adapter per major-version range encapsulates the full command execution
// for that version (including the version-specific integration steps that wire
// generated code back into the project). `canHandle` is claimed via a spec;
// `run` carries the behavior instead of returning a passive model.

import 'package:fluzer/src/commands/command_context.dart';
import 'package:fluzer/src/commands/version/version_spec.dart';
import 'package:fluzer/src/util/semantic_version.dart';

/// 命令适配器抽象。
///
/// [C] 为该适配器消费的命令上下文类型（如 [NewCommandContext]）。
///
/// Command adapter.
///
/// [C] is the command-context type this adapter consumes.
abstract class CommandAdapter<C extends CommandContext> {
  /// 创建适配器。
  ///
  /// Creates the adapter.
  const CommandAdapter({required this.spec});

  /// 版本匹配规格（决议本适配器是否处理该版本）。
  ///
  /// Version-matching spec (decides whether this adapter handles the version).
  final VersionSpec spec;

  /// 该适配器是否认领 [version]。
  ///
  /// Whether this adapter claims [version].
  bool canHandle(SemanticVersion version) => spec.isSatisfiedBy(version);

  /// 执行该版本下的整条命令流程，返回进程退出码。
  ///
  /// Runs the full command flow for this version; returns the process exit code.
  Future<int> run(C context);
}
