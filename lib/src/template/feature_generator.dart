import 'dart:io';

import 'package:path/path.dart' as p;

import '../codemod/feature_registration.dart';
import '../config/project_config.dart';
import 'brick_renderer.dart';

/// 功能模块代码生成器。
///
/// 通过 Mason 渲染 `feature` brick（变量由 brick 自身声明：
/// `name` + `package_name`），并自动注册到 DI 基类。
///
/// Feature module code generator.
///
/// Renders the `feature` brick via Mason (vars declared by the brick itself:
/// `name` + `package_name`) and auto-registers it in the DI base class.
class FeatureGenerator {
  /// 创建生成器。
  ///
  /// Creates the generator.
  FeatureGenerator({required this.config, required this.renderer});

  /// 项目配置。
  ///
  /// Project configuration.
  final ProjectConfig config;

  /// Brick 渲染器。
  ///
  /// Brick renderer.
  final BrickRenderer renderer;

  /// 生成功能模块。
  ///
  /// [featureName] 应为 snake_case。
  ///
  /// Generates a feature module.
  ///
  /// [featureName] should be in snake_case.
  Future<void> generate(String featureName) async {
    _validateFeatureName(featureName);

    final featureDir = Directory(
      p.join(config.projectRoot, 'lib', 'features', featureName),
    );
    if (await featureDir.exists()) {
      throw CliException(
        '功能模块 $featureName 已存在。\n'
        'Feature module $featureName already exists.',
      );
    }

    // Mason 直接把文件生成到项目根的 lib/features/<name>/ 下，
    // 变量仅传 brick 声明的 name + package_name（pascalCase 等由 brick
    // 内的 mustache 过滤器处理，无需 CLI 预计算）。
    // Mason generates files directly under lib/features/<name>/ in the
    // project root. Only the brick-declared vars (name + package_name) are
    // passed; pascalCase etc. are handled by Mustache filters inside the brick.
    await renderer.generate(
      brickName: 'feature',
      outputDir: Directory(config.projectRoot),
      vars: {
        'name': featureName,
        'package_name': config.packageName,
      },
    );

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

  /// 在 injection_base.dart 中注册模块。
  ///
  /// 复用 [FeatureRegistration]（底层为 [CodeMod]）。直接使用 brick 声明的
  /// name + package_name 这一最小变量集，无需手动拼装类名。
  ///
  /// Registers the module in injection_base.dart.
  /// Uses [FeatureRegistration] (backed by [CodeMod]). Relies only on the
  /// minimal brick-declared vars (name + package_name); class names are
  /// derived, not precomputed.
  Future<void> _registerInInjectionBase(String featureName) async {
    final injectionBase = File(
      p.join(config.projectRoot, 'lib', 'core', 'di', 'injection_base.dart'),
    );
    await FeatureRegistration(featureName).applyTo(injectionBase);
  }
}
