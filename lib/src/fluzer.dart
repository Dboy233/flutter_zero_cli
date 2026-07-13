// Fluzer — CLI 根控制器 / CLI root controller
//
// 职责：解析参数、分发到对应命令
// Responsibility: parse arguments, dispatch to commands

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import 'commands/create_command.dart';
import 'commands/new_command.dart';
import 'commands/version_command.dart';

/// CLI 主类，注册并分发命令 / Main CLI class, registers and dispatches commands
class Fluzer {
  /// 创建 CLI 实例 / Creates a CLI instance
  const Fluzer();

  /// 运行 CLI / Runs the CLI
  Future<int> run(List<String> arguments) async {
    var logger = Logger();

    final runner =
        CommandRunner<int>(
            'fluzer',
            'Flutter MVI 模板项目脚手架工具\n'
                'A CLI tool for scaffolding Flutter MVI projects.',
          )
          ..addCommand(CreateCommand(logger: logger))
          ..addCommand(NewCommand(logger: logger))
          ..addCommand(VersionCommand(logger: logger));

    try {
      final result = await runner.run(arguments);
      return result ?? 0;
    } on UsageException catch (e) {
      logger.err(e.message);
      return ExitCode.usage.code;
    }
  }
}
