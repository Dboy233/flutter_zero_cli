import 'dart:io';

import 'package:fluzer/src/process/process_runner.dart';
import 'package:test/test.dart';

void main() {
  group('ProcessRunner.run', () {
    test('成功执行返回 0', () async {
      // 用当前 dart 可执行文件自身，必然存在且 --version 返回 0
      final code = await ProcessRunner.run(
        Platform.executable,
        ['--version'],
      );
      expect(code, 0);
    });

    test('非零退出码原样返回', () async {
      // Windows 下 runInShell 走 cmd.exe：cmd /c exit 3 返回 3
      final code = await ProcessRunner.run('cmd', ['/c', 'exit', '3']);
      expect(code, 3);
    });

    test('不存在的命令：非 Windows 抛异常 / Windows 返回非 0', () async {
      const missing = 'definitely_not_a_real_cmd_zzz_12345';
      if (!Platform.isWindows) {
        expect(
          () => ProcessRunner.run(missing, []),
          throwsA(isA<ProcessException>()),
        );
      } else {
        final code = await ProcessRunner.run(missing, []);
        expect(code, isNonZero);
      }
    });
  });
}
