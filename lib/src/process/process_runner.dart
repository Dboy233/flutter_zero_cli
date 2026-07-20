// 进程执行封装：启动外部进程并将 stdout / stderr 透传到控制台。
//
// Process execution wrapper: spawns external processes and pipes their
// stdout / stderr through to the console.
//
// 命令层通过 [ProcessRunFn] typedef 注入替代实现以保持可测试性；
// 默认实现统一走 [ProcessRunner.run]，避免每个命令各写一份样板代码。

import 'dart:async';
import 'dart:io';

/// 进程执行函数签名（项目根目录 → 退出码）。
///
/// 命令层以此 typedef 声明可注入的执行器（flutter create / pub get /
/// gen-l10n / build_runner 等），测试时替换为 stub。
///
/// Signature for an injectable process runner (project root → exit code).
typedef ProcessRunFn = Future<int> Function(String projectRoot);

/// 外部进程执行器。
///
/// 统一负责：启动进程、[unawaited] 转发 stdout / stderr（不阻塞退出码
/// 返回）、返回 [Process.exitCode]。
///
/// External process executor: starts the process, pipes stdout / stderr
/// without blocking, and returns the exit code.
class ProcessRunner {
  const ProcessRunner._();

  /// 在 [workingDirectory] 下执行 [executable]（参数 [args]），返回退出码。
  ///
  /// Runs [executable] with [args] under [workingDirectory] and returns
  /// the exit code.
  static Future<int> run(
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

    unawaited(
      process.stdout
          .transform(const SystemEncoding().decoder)
          .forEach(stdout.write),
    );
    unawaited(
      process.stderr
          .transform(const SystemEncoding().decoder)
          .forEach(stderr.write),
    );

    return process.exitCode;
  }
}
