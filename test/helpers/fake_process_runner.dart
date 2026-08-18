// 测试用 [ProcessRunner] 替身：记录每次调用、不启动真实进程。
//
// Test double for [ProcessRunner]: records every call and never spawns a real
// process, so tests verify results without shelling out.
//
// 用法：构造时指定 [returnCode]，断言 [calls] 即可。
// 例如验证 build_runner 被正确调用：
// ```dart
// final fake = FakeProcessRunner();
// // 注入到命令后执行……
// expect(
//   fake.calls.any(
//     (c) => c.executable == 'dart' && c.args.contains('build_runner'),
//   ),
//   isTrue,
// );
// ```

import 'dart:io';

import 'package:fluzer/src/process/process_runner.dart';

/// 一次 [ProcessRunner.run] 调用的记录。
///
/// A recorded [ProcessRunner.run] invocation.
class FakeProcessCall {
  /// 创建调用记录 / Creates a call record.
  const FakeProcessCall({
    required this.executable,
    required this.args,
    this.workingDirectory,
    this.showLive = false,
    this.runInShell = false,
  });

  /// 可执行文件（如 `dart`、`flutter`）。
  ///
  /// Executable (e.g. `dart`, `flutter`).
  final String executable;

  /// 参数列表 / Arguments.
  final List<String> args;

  /// 工作目录（可为空）/ Working directory (may be null).
  final String? workingDirectory;

  /// 是否实时透传子进程输出 / Whether child output was forwarded live.
  final bool showLive;

  /// 是否经系统 shell 启动 / Whether launched via the system shell.
  final bool runInShell;
}

/// 测试用 [ProcessRunner] 替身。
///
/// 每次 [run] 仅记录到 [calls] 并返回 [returnCode]，绝不启动真实进程。
///
/// Test double for [ProcessRunner]. Every [run] is recorded into [calls] and
/// returns [returnCode] without spawning a real process.
class FakeProcessRunner extends ProcessRunner {
  /// 创建替身 / Creates a fake.
  ///
  /// [returnCode] 为每次 [run] 的固定返回退出码（默认 0）。
  ///
  /// [returnCode] is the fixed exit code returned by every [run] (default 0).
  FakeProcessRunner({this.returnCode = 0});

  /// 每次 [run] 的固定返回退出码 / Fixed exit code returned by every [run].
  final int returnCode;

  /// 所有调用记录（按发生顺序）/ All recorded calls, in invocation order.
  final List<FakeProcessCall> calls = [];

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
    calls.add(
      FakeProcessCall(
        executable: executable,
        args: args,
        workingDirectory: workingDirectory,
        showLive: showLive,
        runInShell: runInShell,
      ),
    );
    return returnCode;
  }
}
