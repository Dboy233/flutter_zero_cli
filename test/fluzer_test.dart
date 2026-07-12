// fluzer 单元测试 / Unit tests for fluzer

import 'dart:io';

import 'package:codemod_recipe/codemod_recipe.dart';
import 'package:fluzer/src/codemod/codemod_file_editor.dart';
import 'package:fluzer/src/codemod/insert_at_method_end_transform.dart';
import 'package:fluzer/src/codemod/ordered_import_transform.dart';
import 'package:fluzer/src/config/project_config.dart';
import 'package:fluzer/src/templates/feature_generator.dart';
import 'package:fluzer/src/templates/template_engine.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('TemplateEngine', () {
    late Directory tempDir;
    late TemplateEngine engine;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('template_engine_test_');
      engine = TemplateEngine(templatesDir: tempDir);
    });

    tearDown(() => tempDir.delete(recursive: true));

    test('load 读取模板文件 / loads template file', () async {
      final file = File(path.join(tempDir.path, 'hello.tmpl'));
      await file.writeAsString('Hello {{name}}!');
      final template = await engine.load('hello.tmpl');
      expect(template, 'Hello {{name}}!');
    });

    test('load 不存在时抛出异常 / throws when template is missing', () async {
      expect(() => engine.load('missing.tmpl'), throwsA(isA<StateError>()));
    });

    test('render 替换变量 / replaces variables', () {
      final result = engine.render('Hello {{name}}!', {'name': 'Flutter'});
      expect(result, 'Hello Flutter!');
    });

    test('render 多变量 / replaces multiple variables', () {
      final result = engine.render('{{project_name}}/{{feature_name}}', {
        'project_name': 'my_app',
        'feature_name': 'user',
      });
      expect(result, 'my_app/user');
    });

    test('toPascalCase 转换 / converts to PascalCase', () {
      expect(engine.toPascalCase('user_profile'), 'UserProfile');
      expect(engine.toPascalCase('user'), 'User');
      expect(engine.toPascalCase(''), '');
    });

    test('toCamelCase 转换 / converts to camelCase', () {
      expect(engine.toCamelCase('user_profile'), 'userProfile');
      expect(engine.toCamelCase('user'), 'user');
      expect(engine.toCamelCase(''), '');
    });
  });

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
      'relative import 插入到 package import 之后 / inserts relative import after package',
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

  group('CodemodFileEditor', () {
    late Directory tempDir;
    late File testFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'codemod_file_editor_test_',
      );
      testFile = File(path.join(tempDir.path, 'test.dart'));
    });

    tearDown(() => tempDir.delete(recursive: true));

    test('应用 transform 并写回文件 / applies transform and writes back', () async {
      await testFile.writeAsString('class Foo {}\n');
      final editor = CodemodFileEditor(testFile, format: false);
      await editor.apply([
        const OrderedImportTransform('package:test/test.dart'),
      ]);

      final content = await testFile.readAsString();
      expect(content, contains("import 'package:test/test.dart';"));
    });

    test('无补丁时不写文件 / does not write when no patches', () async {
      await testFile.writeAsString('class Foo {}\n');

      final editor = CodemodFileEditor(testFile, format: false);
      await editor.apply([
        const OrderedImportTransform('package:test/test.dart'),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await editor.apply([
        const OrderedImportTransform('package:test/test.dart'),
      ]);

      final content = await testFile.readAsString();
      expect(content.split("import 'package:test/test.dart';").length - 1, 1);
    });
  });

  group('FeatureGenerator', () {
    late Directory projectDir;
    late Directory templatesDir;
    late TemplateEngine engine;

    setUp(() async {
      final sourceTemplatesDir =
          await TemplateEngine.resolvePackageTemplatesDirectory();
      templatesDir = Directory.systemTemp.createTempSync(
        'feature_generator_templates_',
      );
      await _copyDirectory(sourceTemplatesDir, templatesDir);
      engine = TemplateEngine(templatesDir: templatesDir);

      projectDir = Directory.systemTemp.createTempSync(
        'feature_generator_project_',
      );
      await _createProjectStructure(projectDir);
    });

    tearDown(() {
      projectDir.delete(recursive: true);
      templatesDir.delete(recursive: true);
    });

    test('生成功能模块并注册到 DI / generates feature module and registers DI', () async {
      final config = ProjectConfig(
        version: '1.0.0',
        projectRoot: projectDir.path,
        templateName: 'flutter_zero',
        packageName: 'test_app',
      );
      final generator = FeatureGenerator(config: config, engine: engine);
      await generator.generate('user_profile');

      final featureDir = Directory(
        path.join(projectDir.path, 'lib', 'features', 'user_profile'),
      );
      expect(featureDir.existsSync(), isTrue);

      final moduleFile = File(
        path.join(featureDir.path, 'user_profile_module.dart'),
      );
      expect(moduleFile.existsSync(), isTrue);
      final moduleContent = await moduleFile.readAsString();
      expect(moduleContent, contains('class UserProfileModule'));

      final injectionBase = File(
        path.join(projectDir.path, 'lib', 'core', 'di', 'injection_base.dart'),
      );
      final injectionContent = await injectionBase.readAsString();
      expect(
        injectionContent,
        contains(
          "import '../../features/user_profile/user_profile_module.dart';",
        ),
      );
      expect(injectionContent, contains('UserProfileModule.register(getIt);'));
    });
  });
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  await destination.create(recursive: true);
  await for (final entity in source.list(
    recursive: false,
    followLinks: false,
  )) {
    final newPath = path.join(destination.path, path.basename(entity.path));
    if (entity is Directory) {
      await _copyDirectory(entity, Directory(newPath));
    } else if (entity is File) {
      await entity.copy(newPath);
    }
  }
}

Future<void> _createProjectStructure(Directory projectDir) async {
  final configFile = File(
    path.join(projectDir.path, 'flutter_zero_config.yaml'),
  );
  await configFile.writeAsString('''
version: "1.0.0"
template_name: flutter_zero
''');

  final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
  await pubspecFile.writeAsString('''
name: test_app
''');

  final injectionBaseFile = File(
    path.join(projectDir.path, 'lib', 'core', 'di', 'injection_base.dart'),
  );
  await injectionBaseFile.create(recursive: true);
  await injectionBaseFile.writeAsString('''
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
}
