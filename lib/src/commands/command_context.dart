// 命令上下文（值对象）。
//
// 命令入口把解析后的参数 + 模板版本打包成本对象，
// 交给版本专属适配器执行。version / projectRoot 由 BaseCommand 统一填充，
// 各命令的子类上下文再补充自有参数（featureName、skipHandlePatch 等）。
//
// Command context (value object).
//
// The command entry wraps parsed args + the template version into this object
// and hands it to a version-specific adapter. `version` / `projectRoot` are
// filled by [BaseCommand]; each command's context subclass adds its own args.

import 'package:fluzer/src/util/semantic_version.dart';

/// 命令级上下文基类。
///
/// Base command context.
class CommandContext {
  /// 创建上下文。
  ///
  /// Creates the context.
  const CommandContext({
    required this.version,
    required this.projectRoot,
  });

  /// 模板版本号（由 BaseCommand 读取模板自带声明得到）。
  ///
  /// Template version (read by [BaseCommand] from the template's own声明).
  final SemanticVersion version;

  /// 项目根目录绝对路径。
  ///
  /// Absolute project root path.
  final String projectRoot;
}
