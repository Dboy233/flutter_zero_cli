// 进程执行封装：启动外部进程，按 [showLive] 处理其 stdout / stderr 输出。
//
// Process execution wrapper: spawns external processes and forwards their
// stdout / stderr according to [showLive].
//
// 输出策略（由调用方按 [Logger.level] 决定后传入 [showLive]）：
// - [showLive] 为 true（即 --log 调试模式，[Logger.level] == [Level.verbose]）：
//   实时把子进程 stdout / stderr 透传到控制台，便于调试查看真实运行内容。
// - [showLive] 为 false（默认，无 --log）：子进程输出完全隐藏——仅缓冲于
//   内存并丢弃，不打印到控制台（重定向到文件 / CI 场景同样不输出）。
//
// 命令层通过默认实现统一走 [ProcessRunner.run]；[runOverride] 仅供测试替换
// 实现（拦截 [showLive] 等行为，避免真正拉起子进程）。

import 'dart:async';
import 'dart:io';

/// 进程执行函数签名（可执行文件 + 参数 → 退出码）。
///
/// 与 [ProcessRunner.run] 的公开形参一致（去掉仅测试使用的 sink 形参），
/// 允许在测试中整体替换 [ProcessRunner.run] 的实现。
///
/// Signature matching [ProcessRunner.run] (minus test-only sinks), so the
/// implementation can be swapped in tests.
typedef ProcessRunFn =
    Future<int> Function(
      String executable,
      List<String> args, {
      String? workingDirectory,
      bool showLive,
    });

/// 外部进程执行器。
///
/// 统一负责：启动进程、按策略转发 stdout / stderr、返回退出码。
///
/// External process executor: starts the process, forwards stdout / stderr
/// according to the policy, and returns the exit code.
class ProcessRunner {
  const ProcessRunner._();

  /// 测试可替换的 [run] 实现；生产代码保持 `null`。
  ///
  /// 设为非 null 时，[run] 会直接委托给它（参数原样转发），
  /// 既不真正启动子进程，也不触碰 stdout / stderr，便于在测试中拦截
  /// [showLive] 等可见性决策。
  ///
  /// Test-only override for [run]. When non-null, [run] delegates to it
  /// without spawning a real process.
  static ProcessRunFn? runOverride;

  /// 在 [workingDirectory] 下执行 [executable]（参数 [args]），返回退出码。
  ///
  /// [showLive] 为 true 时实时透传子进程输出到控制台（仅终端有意义，
  /// 用于 `--log` 调试模式）；为 false 时子进程输出完全隐藏（仅缓冲并丢弃）。
  ///
  /// [stdoutSink] / [stderrSink] 默认指向全局 stdout / stderr；测试可传入
  /// 捕获用的 [IOSink] 以断言可见性策略。
  ///
  /// Runs [executable] with [args] under [workingDirectory] and returns the
  /// exit code. See file header for the output policy.
  static Future<int> run(
    String executable,
    List<String> args, {
    String? workingDirectory,
    bool showLive = false,
    IOSink? stdoutSink,
    IOSink? stderrSink,
  }) async {
    // 测试钩子：直接委托，不启动真实子进程。
    if (runOverride != null) {
      return runOverride!(
        executable,
        args,
        workingDirectory: workingDirectory,
        showLive: showLive,
      );
    }

    final outSink = stdoutSink ?? stdout;
    final errSink = stderrSink ?? stderr;

    if (showLive) {
      // 实时（显示）模式：把子进程输出直接透传到终端（--log 调试）。
      return _runLive(executable, args, workingDirectory, outSink, errSink);
    } else {
      // 非实时（隐藏）模式：缓冲子进程输出并丢弃，不打印到控制台。
      return _runHidden(executable, args, workingDirectory: workingDirectory);
    }
  }

  static Future<int> _runLive(
    String executable,
    List<String> args,
    String? workingDirectory,
    IOSink outSink,
    IOSink errSink,
  ) async {
    // 实时（显示）模式：把子进程输出直接透传到终端（--log 调试）。
    final process = await Process.start(
      executable,
      args,
      workingDirectory: workingDirectory,
      runInShell: true,
    );

    final outDone = process.stdout
        .transform(const SystemEncoding().decoder)
        .forEach(outSink.write);
    final errDone = process.stderr
        .transform(const SystemEncoding().decoder)
        .forEach(errSink.write);
    final code = await process.exitCode;
    await Future.wait([outDone, errDone]);
    return code;
  }

  /// 隐藏模式执行：启动进程、收齐输出、直接丢弃，返回退出码。
  ///
  /// 子进程输出不打印到控制台（无 --log 时用户无需看到），仅缓冲于内存后
  /// 丢弃——避免污染 fluzer 自身的步骤日志。重定向到文件 / CI 场景同样隐藏。
  static Future<int> _runHidden(
    String executable,
    List<String> args, {
    String? workingDirectory,
  }) async {
    final process = await Process.start(
      executable,
      args,
      workingDirectory: workingDirectory,
      runInShell: true,
    );
    // 必须排空两个流，否则子进程可能因管道写满而阻塞；内容直接丢弃。
    await process.stdout
        .transform(const SystemEncoding().decoder)
        .forEach((_) {});
    await process.stderr
        .transform(const SystemEncoding().decoder)
        .forEach((_) {});
    return process.exitCode;
  }
}
