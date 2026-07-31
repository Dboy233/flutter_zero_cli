import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

import '../config/project_config.dart';
import '../process/process_runner.dart';

/// `flutter gen-l10n` 执行器签名。
typedef FlutterGenL10nRunner = Future<int> Function(String projectRoot);

/// `gen-l10n` 命令：执行 Flutter 国际化代码生成，并自动生成 [L10nCode] 类。
///
/// `gen-l10n` command: runs Flutter localization code generation and
/// auto-generates the [L10nCode] class.
class GenL10nCommand extends Command<int> {
  /// 创建 GenL10nCommand 实例。
  ///
  /// [flutterGenL10nFn] 用于注入 flutter gen-l10n 执行器（测试用 stub）；
  /// 省略时使用默认实现。
  GenL10nCommand({
    Logger? logger,
    FlutterGenL10nRunner? flutterGenL10nFn,
  })  : _logger = logger ?? Logger(),
        _flutterGenL10n = flutterGenL10nFn ?? _defaultFlutterGenL10n;

  final Logger _logger;
  final FlutterGenL10nRunner _flutterGenL10n;

  @override
  String get name => 'gen-l10n';

  @override
  String get description =>
      '生成国际化代码并自动创建 L10nCode 类 / '
      'Generate localization code and create L10nCode class';

  @override
  Future<int> run() async {
    try {
      // 1. 校验当前目录为合法 flutter_zero 项目
      final config = await ProjectConfig.load();
      final projectRoot = config.projectRoot;
      final packageName = config.packageName;

      // 2. 校验 lib/l10n 目录存在
      final l10nDir = Directory(path.join(projectRoot, 'lib', 'l10n'));
      if (!await l10nDir.exists()) {
        _logger.err(
          '未找到 lib/l10n 目录，请确保项目已配置国际化。\n'
          'Could not find lib/l10n directory. '
          'Make sure l10n is configured in this project.',
        );
        return 1;
      }

      // 3. 检查是否有 .arb 文件
      final arbFiles = await l10nDir
          .list()
          .where((e) => e is File && e.path.endsWith('.arb'))
          .toList();
      if (arbFiles.isEmpty) {
        _logger.err(
          'lib/l10n 目录中没有找到 .arb 文件。\n'
          'No .arb files found in lib/l10n directory.',
        );
        return 1;
      }
      _logger.info(
        '找到 ${arbFiles.length} 个 .arb 文件 / '
        'Found ${arbFiles.length} .arb file(s)',
      );

      // 4. 执行 flutter gen-l10n
      _logger.info('正在运行 flutter gen-l10n...');
      final exitCode = await _flutterGenL10n(projectRoot);
      if (exitCode != 0) {
        _logger.err(
          'flutter gen-l10n 执行失败（退出码: $exitCode）。\n'
          'flutter gen-l10n failed (exit code: $exitCode).',
        );
        return exitCode;
      }
      _logger.success('flutter gen-l10n 执行完成。');

      // 5. 读取生成的 app_localizations.dart
      final appLocalizationsFile = File(
        path.join(projectRoot, 'lib', 'l10n', 'gen', 'app_localizations.dart'),
      );
      if (!await appLocalizationsFile.exists()) {
        _logger.err(
          '未找到生成的 app_localizations.dart，请检查 l10n.yaml 中 output-dir 配置。\n'
          'Generated app_localizations.dart not found. '
          'Check output-dir in l10n.yaml.',
        );
        return 1;
      }

      final source = await appLocalizationsFile.readAsString();
      final l10nMembers = _parseAppLocalizations(source);
      _logger.info(
        '解析到 ${l10nMembers.length} 个本地化成员 '
        '(${l10nMembers.where((m) => m.params.isEmpty).length} 无参, '
        '${l10nMembers.where((m) => m.params.isNotEmpty).length} 有参)',
      );

      // 6. 生成 l10n_code.dart
      final genDir = path.join(projectRoot, 'lib', 'l10n', 'gen');
      final code = _generateL10nCode(l10nMembers);
      final outputFile = File(path.join(genDir, 'l10n_code.dart'));
      await outputFile.writeAsString(code);
      _logger.success('L10nCode 类已生成: ${outputFile.path}');

      // 7. 生成 l10n_code_ext.dart（Toast 类型扩展）
      final extCode = _generateL10nCodeExt();
      final extFile = File(path.join(genDir, 'l10n_code_ext.dart'));
      await extFile.writeAsString(extCode);
      _logger.success('L10nToastType 扩展已生成: ${extFile.path}');

      // 8. 生成 l10n_toast_effect_helper.dart（集中式 Toast 分发器）
      final helperCode = _generateL10nToastEffectHelper(l10nMembers, packageName);
      final helperFile = File(path.join(genDir, 'l10n_toast_effect_helper.dart'));
      await helperFile.writeAsString(helperCode);
      _logger.success('L10nToastEffectHelper 已生成: ${helperFile.path}');

      return 0;
    } on CliException catch (e) {
      _logger.err(e.message);
      return 1;
    } on Object catch (e) {
      _logger.err('gen-l10n 执行失败 / gen-l10n failed: $e');
      return 1;
    }
  }

  static Future<int> _defaultFlutterGenL10n(String projectRoot) {
    return ProcessRunner.run(
      'flutter',
      ['gen-l10n'],
      workingDirectory: projectRoot,
    );
  }
}

// ---------------------------------------------------------------------------
// 解析
// ---------------------------------------------------------------------------

/// 表示 AppLocalizations 中的一个本地化成员。
class _L10nMember {
  const _L10nMember(this.name, this.params);
  final String name;
  final List<String> params;
}

/// 从生成的 app_localizations.dart 源码中解析出所有本地化成员。
List<_L10nMember> _parseAppLocalizations(String source) {
  final members = <_L10nMember>[];

  // 匹配 String get xxx; （无参 getter）
  final getterRegex = RegExp(r'^\s*String\s+get\s+(\w+)\s*;\s*$', multiLine: true);
  for (final match in getterRegex.allMatches(source)) {
    members.add(_L10nMember(match.group(1)!, []));
  }

  // 匹配 String xxx(Object p1, Object p2); （有参方法）
  final methodRegex = RegExp(r'^\s*String\s+(\w+)\(([^)]*)\)\s*;\s*$', multiLine: true);
  for (final match in methodRegex.allMatches(source)) {
    final name = match.group(1)!;
    final paramsStr = match.group(2)!;
    final params = <String>[];
    if (paramsStr.trim().isNotEmpty) {
      final paramRegex = RegExp(r'Object\s+(\w+)');
      for (final pm in paramRegex.allMatches(paramsStr)) {
        params.add(pm.group(1)!);
      }
    }
    members.add(_L10nMember(name, params));
  }

  return members;
}

// ---------------------------------------------------------------------------
// 代码生成
// ---------------------------------------------------------------------------

String _generateL10nCode(List<_L10nMember> members) {
  final buf = StringBuffer();

  _writeHeader(buf);

  buf.writeln('/// L10nCode — AppLocalizations 的类型安全引用（值对象）。');
  buf.writeln('///');
  buf.writeln('/// 用于 BLoC 中引用国际化 key，配合 [ToastEffect.l10nCode] 传递。');
  buf.writeln('/// 通过 [toString] 将 [code] 和 [parameters] 序列化为字符串，');
  buf.writeln('/// 通过 [L10nCode.parse] 反序列化。');
  buf.writeln('///');
  buf.writeln('/// 用法：');
  buf.writeln('/// ```dart');
  buf.writeln('/// // BLoC 中发送 toast');
  buf.writeln("/// emitEffect(ToastEffect(l10nCode: L10nCode.appTitle.toString()));");
  buf.writeln('///');
  buf.writeln('/// // 有参 + toast 类型标记');
  buf.writeln(
    "/// emitEffect(ToastEffect(l10nCode: L10nCode.counterValue(5).typeS().toString()));",
  );
  buf.writeln('///');
  buf.writeln('/// // Handler 中解析');
  buf.writeln("/// final l10n = L10nCode.parse(effect.l10nCode!);");
  buf.writeln('/// switch (l10n.code) {');
  buf.writeln("///   case 'appTitle': toast.showSuccess(context.l.appTitle);");
  buf.writeln(
    "///   case 'counterValue': toast.showInfo(context.l.counterValue(l10n.parameters['count']));",
  );
  buf.writeln('/// }');
  buf.writeln('/// ```');
  buf.writeln('class L10nCode {');
  buf.writeln('  /// 创建一个 [L10nCode] 实例。');
  buf.writeln('  ///');
  buf.writeln('  /// [code] 对应 AppLocalizations 的方法名。');
  buf.writeln('  /// [parameters] 参数键值对（值已 URL 编码）。');
  buf.writeln(
    '  const L10nCode({required this.code, required this.parameters});',
  );

  // 无参 → static const 实例
  final noParam = members.where((m) => m.params.isEmpty).toList();
  if (noParam.isNotEmpty) {
    buf.writeln('');
    buf.writeln('  // --- 无参常量 ---');
    for (final m in noParam) {
      buf.writeln(
        "  static const ${m.name} = L10nCode(code: '${m.name}', parameters: {});",
      );
    }
  }

  // 有参 → factory constructor
  final withParam = members.where((m) => m.params.isNotEmpty).toList();
  if (withParam.isNotEmpty) {
    buf.writeln('');
    buf.writeln('  // --- 有参构造 ---');
    for (final m in withParam) {
      buf.writeln('');
      final paramSig = m.params.map((p) => 'Object $p').join(', ');
      buf.writeln('  factory L10nCode.${m.name}($paramSig) {');
      buf.writeln('    return L10nCode(');
      buf.writeln("      code: '${m.name}',");
      buf.writeln('      parameters: {');
      for (final p in m.params) {
        buf.writeln(
          "        '$p': Uri.encodeQueryComponent($p.toString()),",
        );
      }
      buf.writeln('      },');
      buf.writeln('    );');
      buf.writeln('  }');
    }
  }

  // 字段
  buf.writeln('');
  buf.writeln('  /// AppLocalizations 方法名 / key。');
  buf.writeln('  final String code;');
  buf.writeln('');
  buf.writeln('  /// 参数键值对（值已 URL 编码）。');
  buf.writeln('  final Map<String, dynamic> parameters;');

  // toString
  buf.writeln('');
  buf.writeln('  /// 将 [code] 和 [parameters] 编码为字符串。');
  buf.writeln('  ///');
  buf.writeln("  /// 无参: `\"appTitle\"`");
  buf.writeln("  /// 有参: `\"counterValue?count=5\"`");
  buf.writeln('  ///');
  buf.writeln('  /// 配合 [ToastEffect.l10nCode] 使用。');
  buf.writeln('  @override');
  buf.writeln('  String toString() {');
  buf.writeln('    if (parameters.isEmpty) return code;');
  buf.writeln(
    "    final parts = parameters.entries.map((e) => '\${e.key}=\${e.value}').join('&');",
  );
  buf.writeln("    return '\$code?\$parts';");
  buf.writeln('  }');

  // parse
  buf.writeln('');
  buf.writeln('  /// 从编码字符串反序列化 [L10nCode]。');
  buf.writeln('  ///');
  buf.writeln("  /// [L10nCode.toString] 的逆操作。");
  buf.writeln('  static L10nCode parse(String value) {');
  buf.writeln("    final q = value.indexOf('?');");
  buf.writeln(
    '    if (q == -1) return L10nCode(code: value, parameters: const {});',
  );
  buf.writeln('    final code = value.substring(0, q);');
  buf.writeln('    final params = <String, dynamic>{};');
  buf.writeln('    final queryStr = value.substring(q + 1);');
  buf.writeln("    for (final pair in queryStr.split('&')) {");
  buf.writeln("      final eq = pair.indexOf('=');");
  buf.writeln('      if (eq == -1) continue;');
  buf.writeln('      final k = pair.substring(0, eq);');
  buf.writeln('      params[k] = Uri.decodeQueryComponent(pair.substring(eq + 1));');
  buf.writeln('    }');
  buf.writeln('    return L10nCode(code: code, parameters: params);');
  buf.writeln('  }');

  // 元数据 key 常量
  buf.writeln('');
  buf.writeln('  /// Toast 类型标记的 parameter key。');
  buf.writeln(
    "  /// 值: `'S'` (Success), `'E'` (Error), `'I'` (Info), `'W'` (Warning)。",
  );
  buf.writeln("  static const toastTypeKey = 'fluzer_toast_type';");

  buf.writeln('}');
  buf.writeln('');

  return buf.toString();
}

// ---------------------------------------------------------------------------
// l10n_code_ext.dart 生成
// ---------------------------------------------------------------------------

String _generateL10nCodeExt() {
  final buf = StringBuffer();

  _writeHeader(buf);

  buf.writeln("import 'l10n_code.dart';");
  buf.writeln('');
  buf.writeln('/// L10nCode 扩展：Toast 类型标记。');
  buf.writeln('///');
  buf.writeln('/// 用于在 BLoC 中链式调用来标记 toast 类型，');
  buf.writeln('/// 以便 [L10nToastEffectHelper] 统一分发。');
  buf.writeln('///');
  buf.writeln('/// 用法：');
  buf.writeln('/// ```dart');
  buf.writeln(
    "/// // 成功 toast → emitEffect(ToastEffect(l10nCode: L10nCode.appTitle.typeS().toString()));",
  );
  buf.writeln(
    "/// // 错误 toast → emitEffect(ToastEffect(l10nCode: L10nCode.networkError.typeE().toString()));",
  );
  buf.writeln(
    "/// // 信息 toast → emitEffect(ToastEffect(l10nCode: L10nCode.dataLoaded.typeI().toString()));",
  );
  buf.writeln(
    "/// // 警告 toast → emitEffect(ToastEffect(l10nCode: L10nCode.warning.typeW().toString()));",
  );
  buf.writeln('/// ```');
  buf.writeln('extension L10nToastType on L10nCode {');
  buf.writeln(
    '  static const _key = L10nCode.toastTypeKey; // fluzer_toast_type',
  );
  buf.writeln('');
  buf.writeln('  /// 标记为 **成功** (Success) 类型的 toast。');
  buf.writeln('  L10nCode typeS() => L10nCode(');
  buf.writeln('        code: code,');
  buf.writeln("        parameters: {...parameters, _key: 'S'},");
  buf.writeln('      );');
  buf.writeln('');
  buf.writeln('  /// 标记为 **错误** (Error) 类型的 toast。');
  buf.writeln('  L10nCode typeE() => L10nCode(');
  buf.writeln('        code: code,');
  buf.writeln("        parameters: {...parameters, _key: 'E'},");
  buf.writeln('      );');
  buf.writeln('');
  buf.writeln('  /// 标记为 **信息** (Info) 类型的 toast。');
  buf.writeln('  L10nCode typeI() => L10nCode(');
  buf.writeln('        code: code,');
  buf.writeln("        parameters: {...parameters, _key: 'I'},");
  buf.writeln('      );');
  buf.writeln('');
  buf.writeln('  /// 标记为 **警告** (Warning) 类型的 toast。');
  buf.writeln('  L10nCode typeW() => L10nCode(');
  buf.writeln('        code: code,');
  buf.writeln("        parameters: {...parameters, _key: 'W'},");
  buf.writeln('      );');
  buf.writeln('');
  buf.writeln(
    '  /// 获取 toast 类型标记，无标记返回 null。',
  );
  buf.writeln("  String? get toastType => parameters[_key] as String?;");
  buf.writeln('}');
  buf.writeln('');

  return buf.toString();
}

// ---------------------------------------------------------------------------
// l10n_toast_effect_helper.dart 生成
// ---------------------------------------------------------------------------

String _generateL10nToastEffectHelper(
  List<_L10nMember> members,
  String packageName,
) {
  final buf = StringBuffer();

  _writeHeader(buf);

  buf.writeln("import 'package:flutter/cupertino.dart';");
  buf.writeln("import 'package:$packageName/core/di/get_it_instance.dart';");
  buf.writeln(
    "import 'package:$packageName/core/localization/context_l10n.dart';",
  );
  buf.writeln("import 'package:$packageName/core/notifiers/toast_service.dart';");
  buf.writeln("import 'l10n_code.dart';");
  buf.writeln('');
  buf.writeln('/// L10nToastEffectHelper — 集中式 l10n Toast 分发器。');
  buf.writeln('///');
  buf.writeln('/// 由 fluzer gen-l10n 自动生成，包含所有 ARB key 的 switch case。');
  buf.writeln('/// 在 [defaultToastHandle] 中调用，开发者无需逐个 feature 编写');
  buf.writeln('/// ToastEffect 处理器。');
  buf.writeln('///');
  buf.writeln('/// Toast 类型由 [L10nCode.parameters] 中的 [L10nCode.toastTypeKey]');
  buf.writeln("/// 决定：`'S'` → Success, `'E'` → Error, `'I'` → Info, `'W'` → Warning。");
  buf.writeln('/// 未标记时默认使用 Info。');
  buf.writeln('///');
  buf.writeln('/// 返回 `true` 表示已处理，`false` 表示 key 未匹配。');
  buf.writeln('class L10nToastEffectHelper {');
  buf.writeln('  L10nToastEffectHelper._();');
  buf.writeln('');  buf.writeln(
    '  static bool showToastFromL10nCode(BuildContext context, L10nCode l10nCode) {',
  );
  buf.writeln('    final l = context.l;');
  buf.writeln('    final toastService = getIt<ToastService>();');
  buf.writeln('    final String code = l10nCode.code;');
  buf.writeln(
    '    final toastType = l10nCode.parameters[L10nCode.toastTypeKey]?.toString();',
  );
  buf.writeln('    switch (code) {');

  for (final m in members) {
    buf.writeln("      case '${m.name}':");
    buf.writeln('        _showToast(');
    buf.writeln('          toastService,');
    buf.writeln('          toastType,');
    if (m.params.isEmpty) {
      buf.writeln('          l.${m.name},');
    } else {
      final args = m.params.map((p) {
        return "l10nCode.parameters['$p']?.toString() ?? ''";
      }).join(', ');
      buf.writeln('          l.${m.name}($args),');
    }
    buf.writeln('        );');
    buf.writeln('        return true;');
  }

  buf.writeln('      default:');
  buf.writeln('        return false;');
  buf.writeln('    }');
  buf.writeln('  }');
  buf.writeln('');
  buf.writeln('  static void _showToast(');
  buf.writeln('    ToastService toastService,');
  buf.writeln('    String? toastType,');
  buf.writeln('    String msg,');
  buf.writeln('  ) {');
  buf.writeln('    switch (toastType) {');
  buf.writeln("      case 'S':");
  buf.writeln('        toastService.showSuccess(msg);');
  buf.writeln("        break;");
  buf.writeln("      case 'E':");
  buf.writeln('        toastService.showError(msg);');
  buf.writeln("        break;");
  buf.writeln("      case 'W':");
  buf.writeln('        toastService.showWarning(msg);');
  buf.writeln("        break;");
  buf.writeln("      case 'I':");
  buf.writeln('        toastService.showInfo(msg);');
  buf.writeln("        break;");
  buf.writeln('      default:');
  buf.writeln('        toastService.showInfo(msg);');
  buf.writeln('    }');
  buf.writeln('  }');
  buf.writeln('}');
  buf.writeln('');

  return buf.toString();
}

void _writeHeader(StringBuffer buf) {
  buf.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buf.writeln('//');
  buf.writeln('// 由 fluzer gen-l10n 自动生成。');
  buf.writeln('// 每次执行 fluzer gen-l10n 会重新生成此文件。');
  buf.writeln('//');
  buf.writeln('// Generated by fluzer gen-l10n.');
  buf.writeln('// This file is regenerated each time you run fluzer gen-l10n.');
  buf.writeln('');
  buf.writeln('// ignore_for_file: type=lint');
  buf.writeln('');
}
