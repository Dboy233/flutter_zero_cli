import 'dart:io';

import 'package:fluzer/src/process/process_runner.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'helpers/fake_process_runner.dart';

/// 运行 [body]，将其 stdout / stderr 捕获到同一临时文件，返回文件内容。
///
/// 返回内容包含 [ProcessRunner] 实际写入 sink 的子进程输出（若 [showLive]
/// 为 true），或为空（若 [showLive] 为 false，子进程输出被隐藏/丢弃）。
Future<String> _capture(
  Future<int> Function(IOSink out, IOSink err) body,
) async {
  final file = File(
    p.join(
      Directory.systemTemp.path,
      'fluzer_cap_${pid}_${DateTime.now().microsecondsSinceEpoch}.log',
    ),
  );
  final sink = file.openWrite();
  try {
    await body(sink, sink);
    await sink.flush();
  } finally {
    await sink.close();
  }
  final content = await file.readAsString();
  await file.delete();
  return content;
}

/// 写一个临时 dart 脚本并返回其路径（用于产生可控的多行输出）。
Future<File> _writeScript(String source) async {
  final file = File(
    p.join(
      Directory.systemTemp.path,
      'fluzer_script_${pid}_${DateTime.now().microsecondsSinceEpoch}.dart',
    ),
  );
  await file.writeAsString(source);
  return file;
}

void main() {
  late ProcessRunner runner;

  setUp(() {
    runner = RealProcessRunner();
  });

  group('ProcessRunner.run 输出策略（显示 / 隐藏）', () {
    test('showLive:true —— 实时透传子进程输出到 sink', () async {
      final content = await _capture(
        (out, err) => runner.run(
          Platform.resolvedExecutable,
          ['--version'],
          showLive: true,
          stdoutSink: out,
          stderrSink: err,
        ),
      );
      expect(content, contains('Dart SDK version'));
    });

    test('showLive:false —— 子进程输出完全隐藏（不打印）', () async {
      final content = await _capture(
        (out, err) => runner.run(
          Platform.resolvedExecutable,
          ['--version'],
          showLive: false,
          stdoutSink: out,
          stderrSink: err,
        ),
      );
      expect(content, isNot(contains('Dart SDK version')));
    });

    test('超长折行输出 + showLive:false —— 同样完全隐藏', () async {
      final script = await _writeScript(
        "import 'dart:io';\n"
        "void main() {\n"
        "  stdout.write('${'a' * 400}\\n');\n"
        "  stdout.write('resolving dependencies...\\n');\n"
        "  stderr.write('${'b' * 300}\\n');\n"
        '}',
      );
      final content = await _capture(
        (out, err) => runner.run(
          Platform.resolvedExecutable,
          ['run', script.path],
          showLive: false,
          stdoutSink: out,
          stderrSink: err,
        ),
      );
      await script.delete();
      expect(content, isNot(contains('resolving dependencies')));
      expect(content, isNot(contains('a' * 400)));
    });

    test('超长折行输出 + showLive:true —— 实时显示（含折行内容）', () async {
      final script = await _writeScript(
        "import 'dart:io';\n"
        "void main() {\n"
        "  stdout.write('${'a' * 400}\\n');\n"
        "  stdout.write('resolving dependencies...\\n');\n"
        '}',
      );
      final content = await _capture(
        (out, err) => runner.run(
          Platform.resolvedExecutable,
          ['run', script.path],
          showLive: true,
          stdoutSink: out,
          stderrSink: err,
        ),
      );
      await script.delete();
      expect(content, contains('resolving dependencies'));
      expect(content, contains('a' * 400));
    });

    test('非零退出码如实返回', () async {
      final code = await runner.run(Platform.resolvedExecutable, [
        'run',
        'this_package_does_not_exist_xyz',
      ], showLive: false);
      expect(code, isNonZero);
    });

    test('showLive:false —— 高频写 stderr 不触发管道背压死锁', () async {
      // 旧实现串行消费（先 stdout 后 stderr）：子进程把大量诊断写进 stderr、
      // 而 stdout 空闲时，stderr 管道被写满，子进程在 write 上阻塞且永远等
      // 不到 stdout 的 EOF，形成死锁。新实现并发 drain 两流，应在短时间内返回。
      final script = await _writeScript(
        "import 'dart:io';\n"
        "void main() {\n"
        "  final chunk = '${'x' * 1024}';\n"
        "  for (var i = 0; i < 300; i++) {\n"
        '    stderr.write(chunk);\n'
        "  }\n"
        '}\n',
      );
      final code = await runner
          .run(
            Platform.resolvedExecutable,
            ['run', script.path],
            showLive: false,
          )
          .timeout(const Duration(seconds: 5));
      await script.delete();
      expect(code, 0);
    }, timeout: const Timeout(Duration(seconds: 10)));
  });

  group('ProcessRunner 依赖注入（FakeProcessRunner）', () {
    // FakeProcessRunner 记录每次调用、不启动真实进程：既消灭全局可变状态，
    // 又让测试在领域层验证「是否调用 / 传参是否正确」，无需 shell 出去。
    test('FakeProcessRunner 记录调用且不启动真实进程', () async {
      final fake = FakeProcessRunner(returnCode: 42);
      final code = await fake.run(
        'dart',
        ['--version'],
        showLive: true,
        workingDirectory: '/tmp/x',
      );
      expect(code, 42);
      expect(fake.calls, hasLength(1));
      final call = fake.calls.single;
      expect(call.executable, 'dart');
      expect(call.args, ['--version']);
      expect(call.showLive, isTrue);
      expect(call.workingDirectory, '/tmp/x');
    });

    test('showLive 默认为 false', () async {
      final fake = FakeProcessRunner();
      await fake.run('dart', ['--version']);
      expect(fake.calls.single.showLive, isFalse);
    });

    test('即使 showLive:true 也绝不触碰真实进程（固定返回 returnCode）', () async {
      // 若 FakeProcessRunner 错误地把调用落回真实进程，dart --version 会成功
      // 返回 0；这里用 returnCode 固定返回 7，验证全程走注入实现。
      final fake = FakeProcessRunner(returnCode: 7);
      final code = await fake.run(
        Platform.resolvedExecutable,
        ['--version'],
        showLive: true,
      );
      expect(code, 7);
    });
  });
}
