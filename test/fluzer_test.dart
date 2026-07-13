// fluzer 单元测试 / Unit tests for fluzer
//
// 采用 hermetic 测试：模板砖与项目结构均在临时目录中构造，
// 不依赖外部仓库或网络。
//
// Hermetic tests: bricks and project scaffolding are built in temp dirs,
// no dependency on external repos or network.

import 'dart:io';

import 'package:codemod_recipe/codemod_recipe.dart';
import 'package:fluzer/src/codemod/code_mod.dart';
import 'package:fluzer/src/codemod/insert_at_method_end_transform.dart';
import 'package:fluzer/src/codemod/ordered_import_transform.dart';
import 'package:fluzer/src/config/project_config.dart';
import 'package:fluzer/src/template/brick_loader.dart';
import 'package:fluzer/src/template/brick_renderer.dart';
import 'package:fluzer/src/template/feature_generator.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// 在 [root] 下构造一个最小可用的 feature brick。
Future<Directory> _buildFeatureBrick(Directory root) async {
  final bricksRoot = Directory(path.join(root.path, 'bricks'));
  final brickDir = Directory(path.join(bricksRoot.path, 'feature'));
  final brickLib = Directory(
    path.join(brickDir.path, '__brick__', 'lib', 'features', '{{name}}'),
  );
  await brickLib.create(recursive: true);

  await File(path.join(brickDir.path, 'brick.yaml')).writeAsString('''
name: feature
description: test brick
version: 0.1.0
environment:
  mason: ^0.1.2
vars:
  name:
    type: string
  package_name:
    type: string
''');

  await File(path.join(brickLib.path, '{{name}}_model.dart')).writeAsString('''
import 'package:{{package_name}}/core/network/dio_client.dart';

// {{#pascalCase}}{{name}}{{/pascalCase}} 数据模型。
class {{#pascalCase}}{{name}}{{/pascalCase}}Model {}
''');
  return bricksRoot;
}

/// 构造一个最小 flutter_zero 项目（含 injection_base.dart）。
Future<Directory> _buildProject(Directory root) async {
  final projectDir = Directory(path.join(root.path, 'project'));
  await projectDir.create(recursive: true);

  await File(path.join(projectDir.path, 'flutter_zero_config.yaml'))
      .writeAsString('''
version: "1.0.0"
template_name: flutter_zero
''');

  await File(path.join(projectDir.path, 'pubspec.yaml'))
      .writeAsString('name: test_app\n');

  final injectionBase = File(
    path.join(projectDir.path, 'lib', 'core', 'di', 'injection_base.dart'),
  );
  await injectionBase.create(recursive: true);
  await injectionBase.writeAsString('''
import 'get_it_instance.dart';

abstract class InjectionBase {
  Future<void> registerAll() async {
    await registerFeatureModules();
  }

  Future<void> registerBaseDependencies();
  Future<void> registerUserDependencies();

  Future<void> registerFeatureModules() async {
    // Register Feature Modules here, e.g.:
  }
}
''');
  return projectDir;
}

void main() {
  group('OrderedImportTransform', () {
    test('dart import 插入到最前面 / inserts dart import first', () async {
      const source = "import 'package:meta/meta.dart';\n";
      const transform = OrderedImportTransform('dart:async');
      final patches = await transform.apply(source, CodemodContext({}));
      final result = applyPatches(source, patches);
      expect(
        result.indexOf('dart:async'),
        lessThan(result.indexOf('package:meta')),
      );
    });

    test(
      'relative import 插入到 package import 之后 / inserts relative after package',
      () async {
        const source =
            "import 'dart:async';\nimport 'package:meta/meta.dart';\n";
        const transform = OrderedImportTransform(
          '../../features/user_profile/user_profile_module.dart',
        );
        final patches = await transform.apply(source, CodemodContext({}));
        final result = applyPatches(source, patches);
        expect(
          result.indexOf('package:meta'),
          lessThan(result.indexOf('../../features')),
        );
      },
    );

    test('同组内按字典序插入 / inserts within group alphabetically', () async {
      const source = "import 'get_it_instance.dart';\n";
      const transform = OrderedImportTransform(
        '../../features/user_profile/user_profile_module.dart',
      );
      final patches = await transform.apply(source, CodemodContext({}));
      final result = applyPatches(source, patches);
      expect(
        result.indexOf('../../features'),
        lessThan(result.indexOf('get_it_instance')),
      );
    });

    test('已存在时跳过 / skips existing import', () async {
      const source =
          "import '../../features/user_profile/user_profile_module.dart';\n";
      const transform = OrderedImportTransform(
        '../../features/user_profile/user_profile_module.dart',
      );
      final patches = await transform.apply(source, CodemodContext({}));
      expect(patches, isEmpty);
    });
  });

  group('InsertAtMethodEndTransform', () {
    test('在方法体末尾插入 / inserts at method end', () async {
      const source = 'class Foo { void bar() {} }';
      const transform = InsertAtMethodEndTransform(
        className: 'Foo',
        methodName: 'bar',
        code: '    print("done");\n',
      );
      final patches = await transform.apply(source, CodemodContext({}));
      expect(patches, isNotEmpty);
      final result = applyPatches(source, patches);
      expect(result, contains('print("done")'));
    });

    test('=> 表达式方法体跳过 / skips expression body', () async {
      const source = 'class Foo { void bar() => print("done"); }';
      const transform = InsertAtMethodEndTransform(
        className: 'Foo',
        methodName: 'bar',
        code: '    print("again");\n',
      );
      final patches = await transform.apply(source, CodemodContext({}));
      expect(patches, isEmpty);
    });

    test('包含 skipIfContains 时跳过 / skips when skipIfContains matches', () async {
      const source = 'class Foo { void bar() { print("done"); } }';
      const transform = InsertAtMethodEndTransform(
        className: 'Foo',
        methodName: 'bar',
        code: '    print("done");\n',
        skipIfContains: 'print("done")',
      );
      final patches = await transform.apply(source, CodemodContext({}));
      expect(patches, isEmpty);
    });
  });

  group('CodeMod (一键调用工具类)', () {
    late Directory tempDir;
    late File testFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('code_mod_test_');
      testFile = File(path.join(tempDir.path, 'test.dart'));
    });

    tearDown(() => tempDir.delete(recursive: true));

    test('addImport 一键添加 import / one-call addImport', () async {
      await testFile.writeAsString(
        "import 'package:meta/meta.dart';\nclass Foo {}\n",
      );
      await CodeMod(testFile).addImport(
        '../../features/user/user_module.dart',
      );
      final content = await testFile.readAsString();
      expect(
        content,
        contains("import '../../features/user/user_module.dart';"),
      );
    });

    test('insertAtMethodEnd 一键插入 / one-call insertAtMethodEnd', () async {
      await testFile.writeAsString(
        'class Foo { void bar() {} }\n',
      );
      await CodeMod(testFile).insertAtMethodEnd(
        className: 'Foo',
        methodName: 'bar',
        code: '    print("x");\n',
      );
      final content = await testFile.readAsString();
      expect(content, contains('print("x")'));
    });
  });

  group('FeatureGenerator (Mason 集成)', () {
    late Directory sandbox;
    late Directory bricksRoot;
    late Directory projectDir;

    setUp(() async {
      sandbox = Directory.systemTemp.createTempSync('fluzer_feature_int_');
      bricksRoot = await _buildFeatureBrick(sandbox);
      projectDir = await _buildProject(sandbox);
    });

    tearDown(() => sandbox.delete(recursive: true));

    test('生成功能模块并注册到 DI / generates feature and registers DI', () async {
      final config = ProjectConfig(
        version: '1.0.0',
        projectRoot: projectDir.path,
        templateName: 'flutter_zero',
        packageName: 'test_app',
      );
      final generator = FeatureGenerator(
        config: config,
        renderer: BrickRenderer(LocalBrickLoader(bricksRoot)),
      );
      await generator.generate('user_profile');

      // 文件已生成（pascalCase 由 brick 过滤器处理）
      final modelFile = File(
        path.join(
          projectDir.path,
          'lib',
          'features',
          'user_profile',
          'user_profile_model.dart',
        ),
      );
      expect(modelFile.existsSync(), isTrue);
      final modelContent = await modelFile.readAsString();
      expect(modelContent, contains('class UserProfileModel'));
      expect(
        modelContent,
        contains("import 'package:test_app/core/network/dio_client.dart';"),
      );

      // DI 注册（import + 注册语句，幂等）
      final injectionBase = File(
        path.join(projectDir.path, 'lib', 'core', 'di', 'injection_base.dart'),
      );
      final injectionContent = await injectionBase.readAsString();
      expect(
        injectionContent,
        contains("import '../../features/user_profile/user_profile_module.dart';"),
      );
      expect(injectionContent, contains('UserProfileModule.register(getIt);'));
    });

    test('重复生成应报错 / duplicate generation throws', () async {
      final config = ProjectConfig(
        version: '1.0.0',
        projectRoot: projectDir.path,
        templateName: 'flutter_zero',
        packageName: 'test_app',
      );
      final generator = FeatureGenerator(
        config: config,
        renderer: BrickRenderer(LocalBrickLoader(bricksRoot)),
      );
      await generator.generate('user_profile');
      expect(
        () => generator.generate('user_profile'),
        throwsA(isA<CliException>()),
      );
    });
  });
}
