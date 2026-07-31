// Fluzer — CLI 根控制器 / CLI root controller
//
// 职责：解析参数、分发到对应命令
// Responsibility: parse arguments, dispatch to commands

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import 'commands/cache_command.dart';
import 'commands/create_command.dart';
import 'commands/gen_l10n_command.dart';
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
          ..argParser.addFlag(
            'verbose',
            abbr: 'v',
            negatable: false,
            help: '输出详细错误信息（含堆栈） / Show verbose errors with stack traces',
          )
          ..addCommand(CreateCommand(logger: logger))
          ..addCommand(NewCommand(logger: logger))
          ..addCommand(GenL10nCommand(logger: logger))
          ..addCommand(VersionCommand(logger: logger))
          ..addCommand(CacheCommand(logger: logger));

    try {
      final result = await runner.run(arguments);
      return result ?? 0;
    } on UsageException catch (e) {
      logger.err(e.message);
      // 附带完整用法（含可用子命令列表），帮助用户自助修正。
      logger.info(e.usage);
      return ExitCode.usage.code;
    } on Object catch (e, st) {
      // 兜底：任何未被命令自身捕获的异常（如参数解析期、命令构造期、
      // 或命令遗漏捕获的运行时错误），统一以退出码 1 返回并给出友好提示，
      // 避免泄漏内部堆栈并以 255 退出。--verbose 时附加完整堆栈。
      logger
        ..err('执行出错 / An unexpected error occurred:')
        ..err('$e');
      if (_isVerbose(arguments)) {
        logger.err('$st');
      }
      return 1;
    }
  }

  /// 解析全局 `--verbose` / `-v` 标志。
  ///
  /// 直接扫描原始参数而非走 [ArgResults]：兜底 catch 可能发生在参数
  /// 解析失败之前，此时拿不到 runner 的解析结果。
  bool _isVerbose(List<String> arguments) {
    return arguments.contains('--verbose') || arguments.contains('-v');
  }
}
