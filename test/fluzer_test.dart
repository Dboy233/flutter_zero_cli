// fluzer 单元测试 / Unit tests for fluzer
//
// 采用 hermetic 测试：模板砖与项目结构均在临时目录中构造，
// 不依赖外部仓库或网络。
//
// Hermetic tests: bricks and project scaffolding are built in temp dirs,
// no dependency on external repos or network.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:codemod_recipe/codemod_recipe.dart';
import 'package:fluzer/src/codemod/code_mod.dart';
import 'package:fluzer/src/codemod/insert_at_method_end_transform.dart';
import 'package:fluzer/src/codemod/ordered_import_transform.dart';
import 'package:fluzer/src/commands/cache_command.dart';
import 'package:fluzer/src/commands/create_command.dart';
import 'package:fluzer/src/commands/new_command.dart';
import 'package:fluzer/src/commands/version_command.dart';
import 'package:fluzer/src/config/project_config.dart';
import 'package:fluzer/src/template/brick_loader.dart';
import 'package:fluzer/src/template/brick_renderer.dart';
import 'package:fluzer/src/template/feature_generator.dart';
import 'package:fluzer/src/version/version_check.dart';
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

/// 在 [root] 下构造一个最小可用的 project brick（用于 create 命令测试）。
///
/// Builds a minimal `project` brick under [root] for `create` command tests.
Future<Directory> _buildProjectBrick(Directory root) async {
  final bricksRoot = Directory(path.join(root.path, 'bricks'));
  final brickDir = Directory(path.join(bricksRoot.path, 'project'));
  final brickLib = Directory(
    path.join(brickDir.path, '__brick__', '{{name}}'),
  );
  await brickLib.create(recursive: true);

  await File(path.join(brickDir.path, 'brick.yaml')).writeAsString('''
name: project
description: test project brick
version: 0.1.0
environment:
  mason: ^0.1.2
vars:
  name:
    type: string
''');

  await File(path.join(brickLib.path, 'pubspec.yaml')).writeAsString('''
name: {{name}}
''');
  return bricksRoot;
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

  group('Command layer (create/new/version)', () {
    CommandRunner<int> runnerWith(Command<int> cmd) =>
        CommandRunner<int>('fluzer', 'test')..addCommand(cmd);

    // -----------------------------------------------------------------------
    // create 命令：参数校验 / 错误路径 / 完整流程
    // -----------------------------------------------------------------------
    group('CreateCommand', () {
      late Directory sandbox;
      late Directory originalCwd;

      setUp(() {
        sandbox = Directory.systemTemp.createTempSync('fluzer_create_cmd_');
        originalCwd = Directory.current;
        // create 命令以 Directory.current 为基准拼接目标目录
        Directory.current = sandbox;
      });

      tearDown(() {
        Directory.current = originalCwd;
        sandbox.deleteSync(recursive: true);
      });

      test('缺少项目名 → 返回 1 / missing project name returns 1', () async {
        final code = await runnerWith(CreateCommand()).run(['create']);
        expect(code, 1);
      });

      test('非法项目名 → 返回 1 / invalid project name returns 1', () async {
        final code =
            await runnerWith(CreateCommand()).run(['create', 'Bad-Name']);
        expect(code, 1);
      });

      test('目标目录已存在 → 返回 1 / existing target dir returns 1', () async {
        Directory(path.join(sandbox.path, 'existing_app')).createSync();
        final code = await runnerWith(CreateCommand())
            .run(['create', 'existing_app']);
        expect(code, 1);
      });

      test(
        '完整流程（注入运行时）→ 返回 0 并生成项目 / full flow returns 0',
        () async {
          final bricksRoot = await _buildProjectBrick(sandbox);
          final cmd = CreateCommand(
            loader: LocalBrickLoader(bricksRoot),
            flutterCreate: (_, {String? projectName, String? org}) async => 0,
            flutterPubGet: (_) async => 0,
            flutterGenL10n: (_) async => 0,
            buildRunner: (_) async => 0,
          );
          final code = await runnerWith(cmd)
              .run(['create', 'my_app', '--no-build-runner']);
          expect(code, 0);
          final pubspec = File(
            path.join(sandbox.path, 'my_app', 'pubspec.yaml'),
          );
          expect(pubspec.existsSync(), isTrue);
        },
      );

      test(
        'flutter create 失败 → 返回 1 并清理半成品 / '
        'flutter create failure returns 1 and cleans up',
        () async {
          final bricksRoot = await _buildProjectBrick(sandbox);
          final cmd = CreateCommand(
            loader: LocalBrickLoader(bricksRoot),
            flutterCreate: (_, {String? projectName, String? org}) async => 1,
            flutterPubGet: (_) async => 0,
            flutterGenL10n: (_) async => 0,
            buildRunner: (_) async => 0,
          );
          final code = await runnerWith(cmd)
              .run(['create', 'fail_app', '--no-build-runner']);
          expect(code, 1);
          // 失败后应清理半成品目录
          expect(
            Directory(path.join(sandbox.path, 'fail_app')).existsSync(),
            isFalse,
          );
        },
      );
    });

    // -----------------------------------------------------------------------
    // new 命令：参数校验 / 完整流程（注入 loader，跳过网络）
    // -----------------------------------------------------------------------
    group('NewCommand', () {
      late Directory sandbox;
      late Directory originalCwd;
      late Directory bricksRoot;
      late Directory projectDir;

      setUp(() async {
        sandbox = Directory.systemTemp.createTempSync('fluzer_new_cmd_');
        bricksRoot = await _buildFeatureBrick(sandbox);
        projectDir = await _buildProject(sandbox);
        originalCwd = Directory.current;
        // new 命令通过 ProjectConfig.load() 从当前目录向上查找工程
        Directory.current = projectDir;
      });

      tearDown(() {
        Directory.current = originalCwd;
        sandbox.deleteSync(recursive: true);
      });

      test('缺少功能名 → 返回 1 / missing feature name returns 1', () async {
        final code = await runnerWith(NewCommand()).run(['new']);
        expect(code, 1);
      });

      test(
        '完整流程（注入 loader）→ 返回 0 并注册 DI / '
        'full flow returns 0 and registers DI',
        () async {
          final cmd = NewCommand(
            loader: LocalBrickLoader(bricksRoot),
            buildRunner: (_) async => 0,
          );
          final code = await runnerWith(cmd).run(['new', 'user_profile']);
          expect(code, 0);

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

          final injection = File(
            path.join(
              projectDir.path,
              'lib',
              'core',
              'di',
              'injection_base.dart',
            ),
          );
          final content = await injection.readAsString();
          expect(content, contains('UserProfileModule.register(getIt);'));
        },
      );
    });

    // -----------------------------------------------------------------------
    // version 命令：注入 checkForUpdate，覆盖三条分支
    // -----------------------------------------------------------------------
    group('VersionCommand', () {
      test('有可用更新 → 返回 0 / update available returns 0', () async {
        var called = false;
        final result = VersionCheckResult(
          current: '1.0.0',
          latest: '1.1.0',
          hasUpdate: true,
          packageName: 'fluzer',
        );
        final code = await runnerWith(
          VersionCommand(
            checkForUpdateFn: () async {
              called = true;
              return result;
            },
          ),
        ).run(['version']);
        expect(code, 0);
        expect(called, isTrue);
      });

      test('已是最新 → 返回 0 / up to date returns 0', () async {
        final result = VersionCheckResult(
          current: '1.0.0',
          latest: '1.0.0',
          hasUpdate: false,
          packageName: 'fluzer',
        );
        final code = await runnerWith(
          VersionCommand(checkForUpdateFn: () async => result),
        ).run(['version']);
        expect(code, 0);
      });

      test('无法检查 → 静默降级返回 0 / unavailable degrades to 0', () async {
        final result = VersionCheckResult.unavailable(
          current: '1.0.0',
          packageName: 'fluzer',
        );
        final code = await runnerWith(
          VersionCommand(checkForUpdateFn: () async => result),
        ).run(['version']);
        expect(code, 0);
      });
    });

    // -----------------------------------------------------------------------
    // cache 命令：注入临时 cacheDir，覆盖 list / clean
    // -----------------------------------------------------------------------
    group('CacheCommand', () {
      late Directory cacheDir;

      setUp(() {
        cacheDir = Directory.systemTemp.createTempSync('fluzer_cache_cmd_');
      });

      tearDown(() {
        if (cacheDir.existsSync()) cacheDir.deleteSync(recursive: true);
      });

      test('cache list 空目录 → 返回 0 / empty cache list returns 0', () async {
        final code = await runnerWith(CacheCommand(cacheDir: cacheDir))
            .run(['cache', 'list']);
        expect(code, 0);
      });

      test('cache list 有版本 → 返回 0 / cache list with versions returns 0',
          () async {
        Directory(path.join(cacheDir.path, 'template_1.0.0')).createSync();
        Directory(path.join(cacheDir.path, 'template_1.1.0')).createSync();
        // 版本检查缓存文件不应被当作模板版本
        File(path.join(cacheDir.path, 'version_check.json'))
            .writeAsStringSync('{}');
        final code = await runnerWith(CacheCommand(cacheDir: cacheDir))
            .run(['cache', 'list']);
        expect(code, 0);
      });

      test('cache clean 清空版本目录 / clean removes version dirs', () async {
        Directory(path.join(cacheDir.path, 'template_1.0.0')).createSync();
        File(path.join(cacheDir.path, 'version_check.json'))
            .writeAsStringSync('{}');
        final code = await runnerWith(CacheCommand(cacheDir: cacheDir))
            .run(['cache', 'clean']);
        expect(code, 0);
        // 版本目录已删除
        expect(
          Directory(path.join(cacheDir.path, 'template_1.0.0')).existsSync(),
          isFalse,
        );
        // 版本检查缓存文件保留
        expect(
          File(path.join(cacheDir.path, 'version_check.json')).existsSync(),
          isTrue,
        );
      });

      test('cache clean 空目录 → 返回 0 / clean empty cache returns 0',
          () async {
        final code = await runnerWith(CacheCommand(cacheDir: cacheDir))
            .run(['cache', 'clean']);
        expect(code, 0);
      });
    });
  });
}
