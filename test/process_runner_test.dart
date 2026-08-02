import 'dart:io';

import 'package:fluzer/src/process/process_runner.dart';
import 'package:test/test.dart';

void main() {
  group('ProcessRunner.run', () {
    test('成功执行返回 0', () async {
      // 用当前 dart 可执行文件自身，必然存在且 --version 返回 0。
      // 取 resolvedExecutable（绝对路径），避免 PATH 差异导致找不到命令。
      final code = await ProcessRunner.run(
        Platform.resolvedExecutable,
        ['--version'],
      );
      expect(code, 0);
    });

    test('非零退出码原样返回', () async {
      // ProcessRunner 固定 runInShell: true，实际启动的是 shell 本身：
      // Windows → cmd.exe /c ...，POSIX → /bin/sh -c '...'。
      // 因此退出码要用各自 shell 的语法产生，不能共用 cmd 的写法。
      final code = Platform.isWindows
          ? await ProcessRunner.run('cmd', ['/c', 'exit', '3'])
          : await ProcessRunner.run('sh', ['-c', 'exit 3']);
      expect(code, 3);
    });

    test('不存在的命令返回非 0 退出码（shell 兜底，不抛异常）', () async {
      // runInShell: true 时被 Process.start 启动的是 cmd.exe / /bin/sh，
      // 它们一定存在，所以不会抛 ProcessException；
      // “命令不存在”由 shell 自己转成非 0 退出码（sh 为 127、cmd 为 1/9009）。
      const missing = 'definitely_not_a_real_cmd_zzz_12345';
      final code = await ProcessRunner.run(missing, []);
      expect(code, isNonZero);
    });
  });
}
