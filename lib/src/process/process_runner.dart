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
// [ProcessRunner] 为抽象基类：生产用 [RealProcessRunner] 真正启动进程，
// 测试用 FakeProcessRunner（位于 test/helpers）记录调用、不触碰真实进程。

import 'dart:async';
import 'dart:io';

/// 外部进程执行器抽象基类。
///
/// 统一约定：在 [workingDirectory] 下执行 [executable]（参数 [args]），
/// 返回退出码。具体实现决定输出策略与是否真正启动进程。
///
/// 生产用 [RealProcessRunner]；测试用 FakeProcessRunner（位于 test/helpers）。
///
/// External process executor base. Implementations decide output policy and
/// whether to spawn a real process. Use [RealProcessRunner] in production and
/// a fake in tests.
abstract class ProcessRunner {
  /// 创建执行器基类。
  ///
  /// Creates a base runner.
  const ProcessRunner();

  /// 在 [workingDirectory] 下执行 [executable]（参数 [args]），返回退出码。
  ///
  /// [showLive] 为 true 时实时透传子进程输出到控制台（仅终端有意义，
  /// 用于 `--log` 调试模式）；为 false 时子进程输出完全隐藏（仅缓冲并丢弃）。
  ///
  /// [runInShell] 为 true 时通过系统 shell 启动进程。原生可执行文件
  /// （如 dart）可传 false 以减少一层 shell 开销；批处理类入口（如 Windows
  /// 上的 flutter.bat）必须传 true，否则系统找不到可执行文件。
  ///
  /// [stdoutSink] / [stderrSink] 默认指向全局 stdout / stderr；测试可传入
  /// 捕获用的 [IOSink] 以断言可见性策略。
  ///
  /// Runs [executable] with [args] under [workingDirectory] and returns the
  /// exit code. See file header for the output policy.
  Future<int> run(
    String executable,
    List<String> args, {
    String? workingDirectory,
    bool showLive = false,
    bool runInShell = false,
    IOSink? stdoutSink,
    IOSink? stderrSink,
  });
}

/// 真实进程执行器（生产默认）。
///
/// 启动进程、按策略转发 stdout / stderr、返回退出码。
///
/// Real process runner (production default): starts the process, forwards
/// stdout / stderr according to the policy, and returns the exit code.
class RealProcessRunner extends ProcessRunner {
  /// 创建执行器 / Creates a runner.
  const RealProcessRunner();

  @override
  Future<int> run(
    String executable,
    List<String> args, {
    String? workingDirectory,
    bool showLive = false,
    bool runInShell = false,
    IOSink? stdoutSink,
    IOSink? stderrSink,
  }) async {
    final outSink = stdoutSink ?? stdout;
    final errSink = stderrSink ?? stderr;

    if (showLive) {
      return _runLive(
        executable,
        args,
        workingDirectory,
        outSink,
        errSink,
        runInShell,
      );
    } else {
      return _runHidden(
        executable,
        args,
        workingDirectory: workingDirectory,
        runInShell: runInShell,
      );
    }
  }

  Future<int> _runLive(
    String executable,
    List<String> args,
    String? workingDirectory,
    IOSink outSink,
    IOSink errSink,
    bool runInShell,
  ) async {
    final process = await Process.start(
      executable,
      args,
      workingDirectory: workingDirectory,
      runInShell: runInShell,
    );

    // 关闭子进程 stdin：fluzer 为非交互 CLI，默认不向子进程转发终端输入。
    // 若不关闭，stdin 管道写端会一直空闲；一旦子进程读取 stdin（如交互式
    // 确认提示），会因永远等不到数据而静默挂死。关闭后子进程读到 EOF，
    // 会走默认值 / 干净退出。
    await process.stdin.close();

    // 直接透传原始字节（不经 SystemEncoding 逐字节解码），两流并发转发。
    // 用 forEach(outSink.add) 替代 pipe：同一 IOSink 被多个 pipe 绑定会抛
    // "StreamSink is bound to a stream"；forEach 内部以 add 写入，对共享 sink 安全。
    final outDone = process.stdout.forEach(outSink.add);
    final errDone = process.stderr.forEach(errSink.add);
    final code = await process.exitCode;
    await Future.wait([outDone, errDone]);
    return code;
  }

  /// 隐藏模式执行：启动进程、并发排空两个流并直接丢弃字节，返回退出码。
  ///
  /// 子进程输出不打印到控制台（无 --log 时用户无需看到），仅缓冲于内存后
  /// 丢弃——避免污染 fluzer 自身的步骤日志。重定向到文件 / CI 场景同样隐藏。
  ///
  /// 旧实现串行消费（先 await stdout 的 EOF 再读 stderr）会使 stderr 管道
  /// 写满，build_runner 等高频写 stderr 的子进程因此被背压阻塞而卡慢。
  /// 这里并发 drain 两流即可消除背压。
  Future<int> _runHidden(
    String executable,
    List<String> args, {
    String? workingDirectory,
    bool runInShell = false,
  }) async {
    final process = await Process.start(
      executable,
      args,
      workingDirectory: workingDirectory,
      runInShell: runInShell,
    );
    // 关闭子进程 stdin：同上，避免子进程因等不到 stdin 而静默挂死。
    await process.stdin.close();

    // 并发排空两个流并丢弃原始字节，避免管道背压导致子进程阻塞。
    final outDone = process.stdout.drain<void>();
    final errDone = process.stderr.drain<void>();
    final code = await process.exitCode;
    await Future.wait([outDone, errDone]);
    return code;
  }
}
