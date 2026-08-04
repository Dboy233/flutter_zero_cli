import 'dart:io';

import 'package:fluzer/src/config/project_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('ProjectConfig.isCliCompatible', () {
    ProjectConfig cfg(String minCliVersion) => ProjectConfig(
          version: '1.0.1',
          projectRoot: '.',
          templateName: 'flutter_zero',
          packageName: 'app',
          minCliVersion: minCliVersion,
        );

    test('minCliVersion <= cliVersion → true', () {
      expect(cfg('1.0.0').isCliCompatible('1.1.0'), isTrue);
    });

    test('minCliVersion > cliVersion → false（需升级 CLI）', () {
      expect(cfg('1.1.0').isCliCompatible('1.0.0'), isFalse);
    });

    test('相等边界 → true', () {
      expect(cfg('1.1.0').isCliCompatible('1.1.0'), isTrue);
    });

    test('minCliVersion 0.0.0 → 任意 CLI 兼容（老项目兜底）', () {
      expect(cfg('0.0.0').isCliCompatible('0.0.1'), isTrue);
    });
  });

  group('ProjectConfig.load 解析 minCliVersion', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('fluzer_pc_');
    });

    tearDown(() async => deleteTempDir(dir));

    Future<Directory> scaffold({String? minCliVersion}) async {
      final buf = StringBuffer()
        ..writeln('version: "1.0.1"')
        ..writeln('template_name: flutter_zero');
      if (minCliVersion != null) {
        buf.writeln('minCliVersion: "$minCliVersion"');
      }
      await File(p.join(dir.path, 'flutter_zero_config.yaml'))
          .writeAsString(buf.toString());
      await File(p.join(dir.path, 'pubspec.yaml'))
          .writeAsString('name: sample_app\n');
      await Directory(p.join(dir.path, 'lib')).create(recursive: true);
      await Directory(p.join(dir.path, 'lib', 'core', 'di'))
          .create(recursive: true);
      await File(p.join(dir.path, 'lib', 'core', 'di', 'injection_base.dart'))
          .writeAsString('// placeholder\n');
      return dir;
    }

    test('显式 minCliVersion 被正确解析', () async {
      final d = await scaffold(minCliVersion: '1.1.0');
      final config = await ProjectConfig.load(start: d);
      expect(config.minCliVersion, '1.1.0');
    });

    test('缺失 minCliVersion 默认 0.0.0（老项目兼容）', () async {
      final d = await scaffold();
      final config = await ProjectConfig.load(start: d);
      expect(config.minCliVersion, '0.0.0');
    });

    test('minCliVersion 非字符串 → 默认 0.0.0（宽松兼容，不报错）', () async {
      final d = await scaffold();
      await File(p.join(d.path, 'flutter_zero_config.yaml')).writeAsString(
        'version: "1.0.1"\n'
        'template_name: flutter_zero\n'
        'minCliVersion: 100\n', // 整数，yaml 解析为 int 而非 string
      );
      final config = await ProjectConfig.load(start: d);
      expect(config.minCliVersion, '0.0.0');
    });
  });
}
