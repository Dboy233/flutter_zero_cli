// project brick 渲染冒烟测试。
//
// 需要网络（从远程 registry / zip 拉取模板），验证渲染后的目录结构：
// brick 的 {{name}} 层应展开为 outputDir 下的 <name>/ 子目录。
//
// Smoke test for the project brick. Requires network access to fetch the
// template from the remote registry / zip.

import 'dart:io';

import 'package:fluzer/src/template/brick_renderer.dart';
import 'package:fluzer/src/template/template_source.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  test('测试生成brick / project brick renders into outputDir', () async {
    final outputDir = await Directory.systemTemp.createTemp('fluzer_brick_');
    addTearDown(() async {
      if (outputDir.existsSync()) await outputDir.delete(recursive: true);
    });

    final brickLoader =
        await TemplateSourceResolver(logger: Logger()).resolve();
    final renderer = BrickRenderer(brickLoader);
    await renderer.generate(
      brickName: 'project',
      outputDir: outputDir,
      vars: {'name': 'test_project'},
    );

    // brick 的 {{name}} 层展开为 outputDir/<name>/，pubspec 在其中。
    final pubspec = File(join(outputDir.path, 'test_project', 'pubspec.yaml'));
    expect(pubspec.existsSync(), isTrue);
  });
}
