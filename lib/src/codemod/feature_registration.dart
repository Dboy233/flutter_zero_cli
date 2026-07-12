import 'dart:io';

import 'package:codemod_recipe/codemod_recipe.dart';

import 'codemod_file_editor.dart';
import 'insert_at_method_end_transform.dart';
import 'ordered_import_transform.dart';

/// 在模板项目的 `lib/core/di/injection_base.dart` 中注册一个 Feature Module。
///
/// 通过 AST 精准定位 `InjectionBase.registerFeatureModules()`，
/// 插入 import 与 `<FeatureModule>.register(getIt);` 语句。
///
/// Registers a feature module in `lib/core/di/injection_base.dart`.
/// Uses AST to locate `InjectionBase.registerFeatureModules()` and inserts
/// the import and `<FeatureModule>.register(getIt);` statement.
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
    final editor = CodemodFileEditor(injectionBaseFile);
    await editor.apply([
      OrderedImportTransform(_importUri),
      InsertAtMethodEndTransform(
        className: 'InjectionBase',
        methodName: 'registerFeatureModules',
        code:
            '    $_moduleClass.register(getIt); // Generated for $featureName\n',
        skipIfContains: '$_moduleClass.register(getIt)',
      ),
    ]);
  }
}
