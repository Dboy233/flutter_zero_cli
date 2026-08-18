import 'dart:io';

import 'package:fluzer/src/config/project_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('ProjectConfig.load', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('fluzer_pc_');
    });

    tearDown(() async => deleteTempDir(dir));

    Future<Directory> scaffold({
      String version = '1.0.1',
      String configName = 'flutter_zero_config.yaml',
    }) async {
      final buf = StringBuffer()
        ..writeln('version: "$version"')
        ..writeln('template_name: flutter_zero');
      await File(p.join(dir.path, configName)).writeAsString(buf.toString());
      await File(p.join(dir.path, 'pubspec.yaml'))
          .writeAsString('name: sample_app\n');
      return dir;
    }

    test('读取 version / templateName / packageName', () async {
      final d = await scaffold();
      final config = await ProjectConfig.load(start: d);
      expect(config.version, '1.0.1');
      expect(config.templateName, 'flutter_zero');
      expect(config.packageName, 'sample_app');
      expect(config.projectRoot, d.path);
    });

    test('v2 文件名 fluzer.yaml 仅存在时 load 成功（双名兼容）', () async {
      final d = await scaffold(configName: 'fluzer.yaml');
      final config = await ProjectConfig.load(start: d);
      expect(config.version, '1.0.1');
      expect(config.projectRoot, d.path);
    });

    test('v1/v2 同时存在时优先 v1（fileNames 顺序）', () async {
      // 同时写两个文件，内容不同以便区分命中的是哪个。
      final bufV1 = StringBuffer()
        ..writeln('version: "1.0.1"')
        ..writeln('template_name: flutter_zero');
      await File(p.join(dir.path, 'flutter_zero_config.yaml'))
          .writeAsString(bufV1.toString());
      final bufV2 = StringBuffer()
        ..writeln('version: "2.0.0"')
        ..writeln('template_name: flutter_zero');
      await File(p.join(dir.path, 'fluzer.yaml'))
          .writeAsString(bufV2.toString());
      await File(p.join(dir.path, 'pubspec.yaml'))
          .writeAsString('name: sample_app\n');

      final config = await ProjectConfig.load(start: dir);
      expect(config.version, '1.0.1'); // 命中 v1
    });

    test('缺失 version 字段 → 抛 CliException', () async {
      await File(p.join(dir.path, 'flutter_zero_config.yaml')).writeAsString(
        'template_name: flutter_zero\n',
      );
      await File(p.join(dir.path, 'pubspec.yaml')).writeAsString('name: x\n');
      expect(
        () => ProjectConfig.load(start: dir),
        throwsA(isA<CliException>()),
      );
    });

    test('template_name 非 flutter_zero → 抛 CliException', () async {
      await File(p.join(dir.path, 'flutter_zero_config.yaml')).writeAsString(
        'version: "1.0.1"\n'
        'template_name: other\n',
      );
      await File(p.join(dir.path, 'pubspec.yaml')).writeAsString('name: x\n');
      expect(
        () => ProjectConfig.load(start: dir),
        throwsA(isA<CliException>()),
      );
    });

    test('缺失 pubspec.yaml → 抛 CliException（仍需读取 package 名）', () async {
      await File(p.join(dir.path, 'flutter_zero_config.yaml')).writeAsString(
        'version: "1.0.1"\ntemplate_name: flutter_zero\n',
      );
      expect(
        () => ProjectConfig.load(start: dir),
        throwsA(isA<CliException>()),
      );
    });
  });

  group('ProjectConfig.findConfigFile v1/v2 兼容', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('fluzer_fcf_');
    });

    tearDown(() async => deleteTempDir(dir));

    test('仅 fluzer.yaml 时定位到 v2 文件', () async {
      await File(p.join(dir.path, 'fluzer.yaml'))
          .writeAsString('version: "1.0.1"\ntemplate_name: flutter_zero\n');
      final file = await ProjectConfig.findConfigFile(dir);
      expect(file, isNotNull);
      expect(p.basename(file!.path), 'fluzer.yaml');
    });

    test('二者都不存在时返回 null', () async {
      final file = await ProjectConfig.findConfigFile(dir);
      expect(file, isNull);
    });

    test('从子目录向上可命中父目录的配置文件', () async {
      final child = Directory(p.join(dir.path, 'a', 'b'))
        ..createSync(recursive: true);
      await File(p.join(dir.path, 'flutter_zero_config.yaml'))
          .writeAsString('version: "1.0.1"\ntemplate_name: flutter_zero\n');
      final file = await ProjectConfig.findConfigFile(child);
      expect(file, isNotNull);
      expect(p.basename(file!.path), 'flutter_zero_config.yaml');
    });
  });
}
