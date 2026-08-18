// `new` 命令上下文。
//
// NewCommandContext（extends CommandContext）
//
// `new` command context.

import 'package:fluzer/src/commands/command_context.dart';

/// `new` 命令上下文。
///
/// 在基类 [CommandContext] 之上补充功能名与 build_runner 开关。
///
/// `new` command context.
///
/// Adds the feature name and the build-runner toggle on top of [CommandContext].
class NewCommandContext extends CommandContext {
  /// 创建上下文。
  ///
  /// Creates the context.
  const NewCommandContext({
    required super.version,
    required super.projectRoot,
    this.featureName,
  });

  /// 要生成的功能模块名（snake_case）；为 `null` 表示用户未提供。
  ///
  /// Feature module name (snake_case); `null` means the user omitted it.
  final String? featureName;
}
