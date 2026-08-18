// `create` 命令上下文。
//
// 把解析后的项目名、组织名、目标目录与查找起点打包，供 [execute] 使用，
// 使校验 / 渲染 / flutter 步骤共享同一份输入。
//
// `create` command context.
//
// Bundles the parsed project name, org, target dir and the lookup start dir
// for [execute], so validation / render / flutter steps share one input.
import 'dart:io';

class CreateCommandContext {
  /// 创建 create 命令上下文。
  ///
  /// Creates the create command context.
  const CreateCommandContext({
    required this.workingDirectory,
    required this.projectName,
    required this.org,
    required this.targetDir,
  });

  /// 项目根目录查找起点（向上查找 / 拼接目标目录的基准）。
  ///
  /// Start dir for walking up / the base for the target dir.
  final Directory? workingDirectory;

  /// 项目名（即 Mason 渲染出的 `{{name}}` 目录名）。
  ///
  /// Project name (the `{{name}}` dir Mason renders).
  final String projectName;

  /// 组织标识（`--org`，默认 com.example）。
  ///
  /// Organization identifier (`--org`, defaults to com.example).
  final String org;

  /// 目标项目目录（工作目录 + 项目名）。
  ///
  /// Target project dir (working dir + project name).
  final String targetDir;
}
