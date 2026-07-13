import 'dart:io';

import '../util/string_case.dart';
import 'code_mod.dart';

/// 在模板项目的 `lib/core/di/injection_base.dart` 中注册一个 Feature Module。
///
/// 底层复用 [CodeMod] 的两个一键操作：添加 import 与在
/// `InjectionBase.registerFeatureModules()` 末尾插入注册语句。
///
/// Registers a feature module in `lib/core/di/injection_base.dart`.
/// Uses [CodeMod]'s two one-call operations: add import and insert a
/// registration statement at the end of `InjectionBase.registerFeatureModules()`.
class FeatureRegistration {
  /// 创建注册器。
  ///
  /// [featureName] 为 snake_case 功能名。
  ///
  /// Creates the registration.
  ///
  /// [featureName] is the snake_case feature name.
  FeatureRegistration(this.featureName);

  /// 功能名。
  ///
  /// Feature name.
  final String featureName;

  String get _pascal => toPascalCase(featureName);
  String get _moduleClass => '${_pascal}Module';
  String get _importUri =>
      '../../features/$featureName/${featureName}_module.dart';

  /// 对 [injectionBaseFile] 执行注册。
  ///
  /// Applies the registration to [injectionBaseFile].
  Future<void> applyTo(File injectionBaseFile) async {
    final mod = CodeMod(injectionBaseFile);
    await mod.addImport(_importUri);
    await mod.insertAtMethodEnd(
      className: 'InjectionBase',
      methodName: 'registerFeatureModules',
      code:
          '    $_moduleClass.register(getIt); // Generated for $featureName\n',
      skipIfContains: '$_moduleClass.register(getIt)',
    );
  }
}
