import 'dart:io';

import 'package:path/path.dart' as path;

import '../codemod/feature_registration.dart';
import '../config/project_config.dart';
import 'template_engine.dart';

/// 单个生成文件的模板与输出规格。
///
/// Template and output specification for a single generated file.
class _FileSpec {
  /// 创建规格。
  ///
  /// Creates the spec.
  const _FileSpec({required this.template, required this.output});

  /// 模板相对路径（相对于 `templates/<version>/feature/`）。
  ///
  /// Template path relative to `templates/<version>/feature/`.
  final String template;

  /// 输出相对路径（相对于 `lib/features/<feature_name>/`）。
  ///
  /// Output path relative to `lib/features/<feature_name>/`.
  final String output;
}

/// 功能模块代码生成器。
///
/// 根据功能名从 `.tmpl` 模板文件生成功能模块骨架，并自动注册到 DI。
///
///
/// Feature module code generator.
///
/// Generates a feature module skeleton from `.tmpl` template files and
/// auto-registers it in the DI base class.
class FeatureGenerator {
  /// 创建生成器。
  ///
  /// Creates the generator.
  FeatureGenerator({required this.config, required this.engine});

  /// 项目配置。
  ///
  /// Project configuration.
  final ProjectConfig config;

  /// 模板引擎。
  ///
  /// Template engine.
  final TemplateEngine engine;

  /// 模块文件清单。
  ///
  /// 模板路径与输出路径的目录结构保持一致，便于后续维护。
  ///
  ///
  /// Module file manifest.
  ///
  /// Template paths mirror output paths for easier maintenance.
  static const List<_FileSpec> _fileSpecs = [
    _FileSpec(template: 'module.tmpl', output: '{{feature_name}}_module.dart'),
    _FileSpec(
      template: 'data/models/model.tmpl',
      output: 'data/models/{{feature_name}}_model.dart',
    ),
    _FileSpec(
      template: 'data/repositories/repository.tmpl',
      output: 'data/repositories/{{feature_name}}_repository.dart',
    ),
    _FileSpec(
      template: 'presentation/bloc/bloc.tmpl',
      output: 'presentation/bloc/{{feature_name}}_bloc.dart',
    ),
    _FileSpec(
      template: 'presentation/bloc/event.tmpl',
      output: 'presentation/bloc/{{feature_name}}_event.dart',
    ),
    _FileSpec(
      template: 'presentation/bloc/state.tmpl',
      output: 'presentation/bloc/{{feature_name}}_state.dart',
    ),
    _FileSpec(
      template: 'presentation/effect_handle.tmpl',
      output: 'presentation/{{feature_name}}_effect_handle.dart',
    ),
    _FileSpec(
      template: 'presentation/pages/page.tmpl',
      output: 'presentation/pages/{{feature_name}}_page.dart',
    ),
    _FileSpec(
      template: 'presentation/pages/body.tmpl',
      output: 'presentation/pages/{{feature_name}}_body.dart',
    ),
  ];

  /// 生成功能模块。
  ///
  /// [featureName] 应为 snake_case。
  ///
  /// Generates a feature module.
  ///
  /// [featureName] should be in snake_case.
  Future<void> generate(String featureName) async {
    _validateFeatureName(featureName);

    final vars = _buildVariables(featureName);
    final featureDir = Directory(
      path.join(config.projectRoot, 'lib', 'features', featureName),
    );

    if (await featureDir.exists()) {
      throw CliException(
        '功能模块 $featureName 已存在。\n'
        'Feature module $featureName already exists.',
      );
    }

    await _createDirectories(featureDir);
    await _writeFiles(featureDir, vars);
    await _registerInInjectionBase(featureName);
  }

  /// 校验功能名格式。
  ///
  /// Validates the feature name format.
  void _validateFeatureName(String name) {
    if (name.isEmpty) {
      throw CliException('功能名不能为空。\nFeature name cannot be empty.');
    }
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
      throw CliException(
        '功能名必须是 snake_case 且以小写字母开头，例如 user_profile。\n'
        'Feature name must be snake_case and start with a lowercase letter, '
        'e.g. user_profile.',
      );
    }
  }

  /// 构建模板变量。
  ///
  /// Builds template variables.
  Map<String, String> _buildVariables(String featureName) {
    final pascal = engine.toPascalCase(featureName);
    final camel = engine.toCamelCase(featureName);

    return {
      'feature_name': featureName,
      'package_name': config.packageName,
      'FeatureName': pascal,
      'featureName': camel,
    };
  }

  /// 创建模块目录结构。
  ///
  /// 根据 [_fileSpecs] 的输出路径自动推导所需目录。
  ///
  /// Creates the module directory structure.
  /// Derives directories from the output paths in [_fileSpecs].
  Future<void> _createDirectories(Directory featureDir) async {
    final dirs = _fileSpecs
        .map((spec) => path.join(featureDir.path, path.dirname(spec.output)))
        .toSet();
    for (final dir in dirs) {
      await Directory(dir).create(recursive: true);
    }
  }

  /// 写入所有模块文件。
  ///
  /// Writes all module files.
  Future<void> _writeFiles(
    Directory featureDir,
    Map<String, String> vars,
  ) async {
    for (final spec in _fileSpecs) {
      final renderedOutputPath = engine.render(
        path.join(featureDir.path, spec.output),
        vars,
      );
      final template = await engine.load(path.join('feature', spec.template));
      final renderedContent = engine.render(template, vars);
      await File(renderedOutputPath).writeAsString(renderedContent);
    }
  }

  /// 在 injection_base.dart 中注册模块。
  ///
  /// 使用 codemod_recipe 基于 AST 插入 import 与注册语句。
  ///
  /// Registers the module in injection_base.dart.
  /// Uses codemod_recipe with AST-based insertion for import and
  /// registration statement.
  Future<void> _registerInInjectionBase(String featureName) async {
    final injectionBase = File(
      path.join(config.projectRoot, 'lib', 'core', 'di', 'injection_base.dart'),
    );
    await FeatureRegistration(featureName).applyTo(injectionBase);
  }
}
