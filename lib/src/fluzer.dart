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
    // 调试开关：--log 打开后，Logger 进入 verbose 级别（detail/getLog 可见）、
    // 子进程原始输出保留不清除、异常附带完整堆栈。先扫原始参数是因为兜底
    // catch 可能发生在参数解析之前，此时拿不到 runner 的 [ArgResults]。
    final debug = _isDebug(arguments);
    // mason_logger 自带级别区分：--log 时进入 verbose（放行 detail() 调试日志、
    // 子进程原始输出与异常堆栈）；否则默认 info。可见性全部由 logger.level 驱动，
    // 不再需要额外的策略对象。
    final logger = Logger(level: debug ? Level.verbose : Level.info);

    final runner =
        CommandRunner<int>(
            'fluzer',
            'Flutter MVI 模板项目脚手架工具\n'
                'A CLI tool for scaffolding Flutter MVI projects.',
          )
          ..argParser.addFlag(
            'log',
            abbr: 'l',
            negatable: false,
            help: '调试模式：显示详细日志、子进程原始输出与异常堆栈 / '
                'Debug mode: verbose logs, raw subprocess output and stack traces',
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
      // 避免泄漏内部堆栈并以 255 退出。--log 时附加完整堆栈。
      logger
        ..err('执行出错 / An unexpected error occurred:')
        ..err('$e');
      if (debug) {
        logger.err('$st');
      }
      return 1;
    }
  }

  /// 解析全局 `--log` / `-l` 标志。
  ///
  /// 直接扫描原始参数而非走 [ArgResults]：兜底 catch 可能发生在参数
  /// 解析失败之前，此时拿不到 runner 的解析结果。
  bool _isDebug(List<String> arguments) {
    return arguments.contains('--log') || arguments.contains('-l');
  }
}
