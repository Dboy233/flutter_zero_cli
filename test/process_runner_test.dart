import 'dart:io';

import 'package:fluzer/src/process/process_runner.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

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
      'fluzer_cap_${DateTime.now().microsecondsSinceEpoch}.log',
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
      'fluzer_script_${DateTime.now().microsecondsSinceEpoch}.dart',
    ),
  );
  await file.writeAsString(source);
  return file;
}

void main() {
  group('ProcessRunner.run 输出策略（显示 / 隐藏）', () {
    test('showLive:true —— 实时透传子进程输出到 sink', () async {
      final content = await _capture(
        (out, err) => ProcessRunner.run(
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
        (out, err) => ProcessRunner.run(
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
        (out, err) => ProcessRunner.run(
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
        (out, err) => ProcessRunner.run(
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
      final code = await ProcessRunner.run(Platform.resolvedExecutable, [
        'run',
        'this_package_does_not_exist_xyz',
      ], showLive: false);
      expect(code, isNonZero);
    });
  });
}
