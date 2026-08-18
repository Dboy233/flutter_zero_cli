// FeatureRegistration 单元测试 / Unit tests for FeatureRegistration.
//
// 复用真实 CodeMod 流水线（addImport + insertAtMethodEnd），用最小合法的
// injection_base.dart fixture 验证：
//   1. applyTo 注入 import 并在 InjectionBase.registerFeatureModules 末尾插入注册；
//   2. 重复 applyTo 幂等（skipIfContains 不重复插入）；
//   3. 不同功能名生成不同 module class 与 import uri。
//
// Uses the real CodeMod pipeline (addImport + insertAtMethodEnd) with a
// minimal valid injection_base.dart fixture to verify registration, idempotent
// re-application, and per-feature class/import derivation.

import 'dart:io';

import 'package:fluzer/src/codemod/feature_registration.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const String _fixture = '''
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
''';

void main() {
  late Directory tempDir;
  late File injectionBase;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('feature_reg_');
    injectionBase = File(p.join(tempDir.path, 'injection_base.dart'));
    await injectionBase.writeAsString(_fixture);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('applyTo 注入 import 并在 registerFeatureModules 末尾注册', () async {
    await FeatureRegistration('user_profile').applyTo(injectionBase);
    final content = await injectionBase.readAsString();
    expect(
      content,
      contains(
        "import '../../features/user_profile/user_profile_module.dart';",
      ),
    );
    // 注册语句（含 Generated 注释）→ 方法体内、skipIfContains 子串均就位
    expect(content, contains('UserProfileModule.register(getIt)'));
    expect(content, contains('// Generated for user_profile'));
    // 注册语句位于 registerFeatureModules 方法体内
    final methodStart = content.indexOf('registerFeatureModules() async {');
    final methodEnd = content.indexOf('}', methodStart);
    final body = content.substring(methodStart, methodEnd);
    expect(body, contains('UserProfileModule.register(getIt)'));
  });

  test('重复 applyTo 幂等（skipIfContains 不重复插入）', () async {
    await FeatureRegistration('user_profile').applyTo(injectionBase);
    await FeatureRegistration('user_profile').applyTo(injectionBase);
    final content = await injectionBase.readAsString();
    // 注册子串全局仅出现一次（import 行只含 user_profile_module，不含 register(getIt)）
    final matches = RegExp(r'UserProfileModule\.register\(getIt\)')
        .allMatches(content)
        .length;
    expect(matches, 1);
    // import 也仅一次
    final importMatches = RegExp(
      r"import '../../features/user_profile/user_profile_module.dart';",
    ).allMatches(content).length;
    expect(importMatches, 1);
  });

  test('不同功能名生成不同 module class 与 import uri', () async {
    await FeatureRegistration('order').applyTo(injectionBase);
    final content = await injectionBase.readAsString();
    expect(
      content,
      contains("import '../../features/order/order_module.dart';"),
    );
    expect(content, contains('OrderModule.register(getIt)'));
    expect(content, contains('// Generated for order'));
  });
}
