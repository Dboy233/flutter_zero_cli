import 'dart:io';

import 'package:fluzer/fluzer.dart';
import 'package:fluzer/src/process/process_runner.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// 验证全局 `--log` 开关经 [Fluzer] 注入子命令，使 [ProcessRunner.run]
/// 收到正确的 showLive（是否实时显示子进程输出）。
///
/// 通过构造注入 mock [ProcessRunner] 拦截调用，不再使用全局可变静态变量。
void main() {
  group('Fluzer --log 传播到子命令 ProcessRunner.showLive', () {
    late Directory tempDir;
    bool? capturedShowLive;

    setUp(() async {
      capturedShowLive = null;

      // 搭建最小 flutter_zero 工程，使 gen-l10n 能走到 flutter gen-l10n 步骤。
      tempDir = await Directory.systemTemp.createTemp('fluzer_proj_');
      await File(p.join(tempDir.path, 'flutter_zero_config.yaml')).writeAsString(
        'version: 1.1.0\n'
        'template_name: flutter_zero\n'
        'minCliVersion: 1.0.0\n',
      );
      await File(p.join(tempDir.path, 'pubspec.yaml')).writeAsString(
        'name: demo_app\n',
      );
      await Directory(p.join(tempDir.path, 'lib')).create();
      await Directory(p.join(tempDir.path, 'lib', 'core', 'di'))
          .create(recursive: true);
      await File(
        p.join(tempDir.path, 'lib', 'core', 'di', 'injection_base.dart'),
      ).writeAsString('// stub');
      await Directory(p.join(tempDir.path, 'lib', 'l10n')).create();
      await File(p.join(tempDir.path, 'lib', 'l10n', 'app_en.arb'))
          .writeAsString('{"@":""}');
      await Directory(p.join(tempDir.path, 'lib', 'l10n', 'gen')).create();
      await File(
        p.join(tempDir.path, 'lib', 'l10n', 'gen', 'app_localizations.dart'),
      ).writeAsString(
        'abstract class AppLocalizations {\n'
        '  String get title;\n'
        '  String get hello;\n'
        '  String greeting(Object name);\n'
        '}\n',
      );
    });

    tearDown(() async {
      // Windows 下新建的 .dart 文件可能被杀毒软件短暂锁定，删除失败属常态；
      // 重试几次，仍失败则交予系统临时目录清理，避免误判测试失败。
      for (var i = 0; i < 3; i++) {
        try {
          await tempDir.delete(recursive: true);
          return;
        } on FileSystemException {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }
    });

    /// 创建 mock [ProcessRunner] 拦截 showLive 并记录，将其注入 [Fluzer]。
    Fluzer createFluzer() {
      final mockRunner = ProcessRunner(
        impl: (
          String executable,
          List<String> args, {
          String? workingDirectory,
          bool showLive = false,
          bool runInShell = false,
        }) {
          capturedShowLive = showLive;
          return Future.value(0);
        },
      );
      return Fluzer(workingDirectory: tempDir, processRunner: mockRunner);
    }

    Future<void> runInProject(List<String> args) async {
      await createFluzer().run(args);
    }

    test('--log 时 gen-l10n 的 showLive 为 true（显示子进程输出）', () async {
      await runInProject(['--log', 'gen-l10n', '--skip-version-check']);
      expect(capturedShowLive, isTrue);
    });

    test('无 --log 时 gen-l10n 的 showLive 为 false（隐藏子进程输出）', () async {
      await runInProject(['gen-l10n', '--skip-version-check']);
      expect(capturedShowLive, isFalse);
    });

    test('-l 缩写同样生效（showLive 为 true）', () async {
      await runInProject(['-l', 'gen-l10n', '--skip-version-check']);
      expect(capturedShowLive, isTrue);
    });
  });
}
