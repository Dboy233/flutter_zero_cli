import 'dart:io';

import 'package:fluzer/src/i18n/gen/strings.g.dart';
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
  FeatureGenerator({
    required this.config,
    required this.renderer,
    this.diTargetPath = 'lib/core/di/injection_base.dart',
    Translations? messages,
  }) : _messages = messages ?? AppLocale.zh.buildSync();

  /// 项目配置。
  ///
  /// Project configuration.
  final ProjectConfig config;

  /// DI 注册目标路径（相对 projectRoot）。
  ///
  /// 由调用方按模板版本传入：1.0.x 指向 `injection_base.dart`，
  /// 未来大版本若移动注册位，传入对应路径即可，无需改动生成管线。
  ///
  /// DI registration target (relative to projectRoot).
  ///
  /// Passed per template version: 1.0.x points at `injection_base.dart`;
  /// future major versions that relocate registration just pass the new path
  /// without touching the generation pipeline.
  final String diTargetPath;

  /// Brick 渲染器。
  ///
  /// Brick renderer.
  final BrickRenderer renderer;

  /// 本地化消息（类型安全访问器）。
  ///
  /// Localized messages (type-safe accessors).
  final Translations _messages;

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
      throw CliException(_messages.feature.featureExists(feature: featureName));
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
      throw CliException(_messages.feature.featureNameEmpty);
    }
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
      throw CliException(_messages.feature.featureNameInvalid);
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
      p.join(config.projectRoot, diTargetPath),
    );
    await FeatureRegistration(featureName, messages: _messages).applyTo(injectionBase);
  }
}
