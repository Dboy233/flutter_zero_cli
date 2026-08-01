/// l10n 相关代码生成器（纯函数，可单测）。
///
/// 生成三个文件的内容：
/// - `l10n_code.dart`：[L10nCode] 值对象
/// - `l10n_code_ext.dart`：Toast 类型标记扩展
/// - `l10n_toast_effect_helper.dart`：集中式 Toast 分发器
///
/// Code generators for the l10n support files. All functions are pure
/// and unit-testable; generated sources are formatted with dart_style.
library;

import 'package:dart_style/dart_style.dart';

import '../template/template_config.dart';
import 'l10n_parser.dart';

/// 生成 `l10n_code.dart` 内容。
String generateL10nCode(List<L10nMember> members) {
  final buf = StringBuffer()..write(_header());

  final noParam = members.where((m) => !m.hasParams).toList();
  final withParam = members.where((m) => m.hasParams).toList();

  // 文档示例使用真实成员，避免引用项目中不存在的 key。
  final exNoParam = noParam.isEmpty ? 'appTitle' : noParam.first.name;
  buf
    ..writeln('/// L10nCode — AppLocalizations 的类型安全引用（值对象）。')
    ..writeln('///')
    ..writeln('/// 用于 BLoC 中引用国际化 key，配合 `ToastEffect.l10nCode` 传递。')
    ..writeln('/// [parameters] 永远保存**原始（未编码）**值；编码/解码只发生在')
    ..writeln('/// [toString] / [L10nCode.parse] 的序列化边界。')
    ..writeln('///')
    ..writeln('/// 用法：')
    ..writeln('/// ```dart')
    ..writeln('/// // BLoC 中发送 toast（无参）')
    ..writeln(
      '/// emitEffect(ToastEffect(l10nCode: L10nCode.$exNoParam.toString()));',
    );
  if (withParam.isNotEmpty) {
    final m = withParam.first;
    final args = m.params.map(_exampleValue).join(', ');
    buf
      ..writeln('///')
      ..writeln('/// // 有参 + toast 类型标记')
      ..writeln(
        '/// emitEffect(ToastEffect(l10nCode: L10nCode.${m.name}($args).typeS().toString()));',
      );
  }
  buf
    ..writeln('///')
    ..writeln('/// // Handler 中解析')
    ..writeln('/// final l10n = L10nCode.parse(effect.l10nCode!);')
    ..writeln('/// ```')
    ..writeln('class L10nCode {')
    ..writeln('  /// 创建一个 [L10nCode] 实例。')
    ..writeln('  ///')
    ..writeln('  /// [code] 对应 AppLocalizations 的成员名；')
    ..writeln('  /// [parameters] 为参数原始值（**未编码**）。')
    ..writeln(
      '  const L10nCode({required this.code, required this.parameters});',
    );

  // --- 无参常量 ---
  if (noParam.isNotEmpty) {
    buf
      ..writeln('')
      ..writeln('  // --- 无参常量 ---');
    for (final m in noParam) {
      buf.writeln(
        "  static const ${m.name} = L10nCode(code: '${m.name}', parameters: {});",
      );
    }
  }

  // --- 有参构造（保留原始参数类型）---
  if (withParam.isNotEmpty) {
    buf
      ..writeln('')
      ..writeln('  // --- 有参构造 ---');
    for (final m in withParam) {
      buf.writeln('');
      final paramSig = m.params
          .map((p) => '${p.type} ${_safeParamName(p.name)}')
          .join(', ');
      buf
        ..writeln('  factory L10nCode.${m.name}($paramSig) {')
        ..writeln('    return L10nCode(')
        ..writeln("      code: '${m.name}',")
        ..writeln('      parameters: Map.unmodifiable({');
      for (final p in m.params) {
        buf.writeln("        '${p.name}': ${_serializeExpr(p)},");
      }
      buf
        ..writeln('      }),')
        ..writeln('    );')
        ..writeln('  }');
    }
  }

  // --- 字段 ---
  buf
    ..writeln('')
    ..writeln('  /// AppLocalizations 成员名 / key。')
    ..writeln('  final String code;')
    ..writeln('')
    ..writeln('  /// 参数键值对（原始值，未编码）。')
    ..writeln('  final Map<String, String> parameters;')
  // --- toString（序列化边界：统一编码）---
    ..writeln('')
    ..writeln('  /// 将 [code] 和 [parameters] 编码为字符串。')
    ..writeln('  ///')
    ..writeln('  /// 无参: `"appTitle"`；有参: `"counterValue?count=5"`。')
    ..writeln('  /// 配合 `ToastEffect.l10nCode` 使用。')
    ..writeln('  @override')
    ..writeln('  String toString() {')
    ..writeln('    if (parameters.isEmpty) return code;')
    ..writeln('    final query = parameters.entries')
    ..writeln(
      "        .map((e) => '\${Uri.encodeQueryComponent(e.key)}=\${Uri.encodeQueryComponent(e.value)}')",
    )
    ..writeln("        .join('&');")
    ..writeln("    return '\$code?\$query';")
    ..writeln('  }')
  // --- parse（反序列化边界：统一解码）---
    ..writeln('')
    ..writeln('  /// 从编码字符串反序列化 [L10nCode]。')
    ..writeln('  ///')
    ..writeln('  /// [L10nCode.toString] 的逆操作。')
    ..writeln('  ///')
    ..writeln('  /// 对损坏的输入（如不完整的百分号编码）不会抛异常，')
    ..writeln('  /// 退化为仅含 [code] 的实例。')
    ..writeln('  static L10nCode parse(String value) {')
    ..writeln("    final q = value.indexOf('?');")
    ..writeln(
      '    if (q == -1) return L10nCode(code: value, parameters: const {});',
    )
    ..writeln('    try {')
    ..writeln('      return L10nCode(')
    ..writeln('        code: value.substring(0, q),')
    ..writeln('        parameters: Map.unmodifiable(')
    ..writeln('          Uri.splitQueryString(value.substring(q + 1)),')
    ..writeln('        ),')
    ..writeln('      );')
    ..writeln('    } on FormatException {')
    ..writeln('      return L10nCode(code: value, parameters: const {});')
    ..writeln('    }')
    ..writeln('  }')
  // --- 相等性（值对象语义）---
    ..writeln('')
    ..writeln('  @override')
    ..writeln('  bool operator ==(Object other) =>')
    ..writeln('      identical(this, other) ||')
    ..writeln('      (other is L10nCode &&')
    ..writeln('          other.code == code &&')
    ..writeln('          _mapEquals(other.parameters, parameters));')
    ..writeln('')
    ..writeln('  @override')
    ..writeln('  int get hashCode => Object.hash(')
    ..writeln('        code,')
    ..writeln('        Object.hashAll(')
    ..writeln(
    '          parameters.entries.map((e) => Object.hash(e.key, e.value)),',
  )
    ..writeln('        ),')
    ..writeln('      );')
  // --- 元数据 key ---
    ..writeln('')
    ..writeln('  /// Toast 类型标记的 parameter key。')
    ..writeln(
      "  /// 值: `'S'` (Success), `'E'` (Error), `'I'` (Info), `'W'` (Warning)。",
    )
    ..writeln("  static const toastTypeKey = 'fluzer_toast_type';")
    ..writeln('}')
    ..writeln('')
    ..writeln('/// [L10nCode.==] 使用的 Map 逐键值比较。')
    ..writeln('bool _mapEquals(Map<String, String> a, Map<String, String> b) {')
    ..writeln('  if (identical(a, b)) return true;')
    ..writeln('  if (a.length != b.length) return false;')
    ..writeln('  for (final entry in a.entries) {')
    ..writeln('    if (b[entry.key] != entry.value) return false;')
    ..writeln('  }')
    ..writeln('  return true;')
    ..writeln('}')
    ..writeln('');

  return _format(buf.toString());
}

/// 生成 `l10n_code_ext.dart` 内容（Toast 类型标记扩展）。
String generateL10nCodeExt(String packageName) {
  final buf = StringBuffer()
    ..write(_header())
    ..writeln("import 'package:$packageName/core/effect/ui_effect.dart';")
    ..writeln("import 'l10n_code.dart';")
    ..writeln('')
    ..writeln('/// L10nCode 扩展：Toast 类型标记。')
    ..writeln('///')
    ..writeln('/// 在 BLoC 中链式调用标记 toast 类型，')
    ..writeln('/// 由 `L10nToastEffectHelper` 统一分发。')
    ..writeln('///')
    ..writeln('/// 用法：')
    ..writeln('/// ```dart')
    ..writeln('/// emitEffect(L10nCode.xxx.typeS().toToastEffect());')
    ..writeln('/// ```')
    ..writeln('extension L10nToastType on L10nCode {')
    ..writeln('  static const _key = L10nCode.toastTypeKey;')
    ..writeln('')
    ..writeln('  /// 标记为 **成功** (Success) 类型的 toast。')
    ..writeln('  L10nCode typeS() => _withType(\'S\');')
    ..writeln('')
    ..writeln('  /// 标记为 **错误** (Error) 类型的 toast。')
    ..writeln('  L10nCode typeE() => _withType(\'E\');')
    ..writeln('')
    ..writeln('  /// 标记为 **信息** (Info) 类型的 toast。')
    ..writeln('  L10nCode typeI() => _withType(\'I\');')
    ..writeln('')
    ..writeln('  /// 标记为 **警告** (Warning) 类型的 toast。')
    ..writeln('  L10nCode typeW() => _withType(\'W\');')
    ..writeln('')
    ..writeln('  /// 获取 toast 类型标记，无标记返回 null。')
    ..writeln('  String? get toastType => parameters[_key];')
    ..writeln('')
    ..writeln('  /// 直接转换为 [ToastEffect]（`l10nCode` 为序列化字符串）。')
    ..writeln('  ///')
    ..writeln('  /// ```dart')
    ..writeln('  /// emitEffect(L10nCode.appTitle.typeS().toToastEffect());')
    ..writeln('  /// ```')
    ..writeln(
      '  ToastEffect toToastEffect() => ToastEffect(l10nCode: toString());',
    )
    ..writeln('')
    ..writeln('  L10nCode _withType(String type) => L10nCode(')
    ..writeln('        code: code,')
    ..writeln(
      '        parameters: Map.unmodifiable({...parameters, _key: type}),',
    )
    ..writeln('      );')
    ..writeln('}')
    ..writeln('');

  return _format(buf.toString());
}

/// 生成 `l10n_toast_effect_helper.dart` 内容（集中式 Toast 分发器）。
String generateL10nToastEffectHelper(
  List<L10nMember> members,
  String packageName,
) {
  final buf = StringBuffer()
    ..write(_header())
    ..writeln("import 'package:flutter/widgets.dart';")
    ..writeln("import 'package:$packageName/core/di/get_it_instance.dart';")
    ..writeln(
      "import 'package:$packageName/core/localization/context_l10n.dart';",
    )
    ..writeln("import 'package:$packageName/core/notifiers/toast_service.dart';")
    ..writeln("import 'package:$packageName/core/utils/log.dart';")
    ..writeln("import 'l10n_code.dart';")
    ..writeln("import 'l10n_code_ext.dart';")
    ..writeln('')
    ..writeln('/// L10nToastEffectHelper — 集中式 l10n Toast 分发器。')
    ..writeln('///')
    ..writeln('/// 由 fluzer gen-l10n 自动生成，包含所有 ARB key 的 switch case。')
    ..writeln('/// 在 `defaultToastHandle` 中调用，开发者无需逐个 feature 编写')
    ..writeln('/// ToastEffect 处理器。')
    ..writeln('///')
    ..writeln('/// Toast 类型由 `L10nCode.parameters` 中的 `L10nCode.toastTypeKey`')
    ..writeln(
      "/// 决定：`'S'` → Success, `'E'` → Error, `'I'` → Info, `'W'` → Warning。",
    )
    ..writeln('/// 未标记时默认使用 Info。')
    ..writeln('///')
    ..writeln('/// 返回 `true` 表示已处理，`false` 表示 key 未匹配。')
    ..writeln('class L10nToastEffectHelper {')
    ..writeln('  L10nToastEffectHelper._();')
    ..writeln('')
    ..writeln(
      '  static bool showToastFromL10nCode(BuildContext context, L10nCode l10nCode) {',
    )
    ..writeln('    final l = context.l;')
    ..writeln('    final toastService = getIt<ToastService>();')
    ..writeln('    final code = l10nCode.code;')
    ..writeln('    final toastType = l10nCode.toastType;')
    ..writeln('    switch (code) {');

  for (final m in members) {
    buf
      ..writeln("      case '${m.name}':")
      ..writeln('        _showToast(')
      ..writeln('          toastService,')
      ..writeln('          toastType,');
    if (m.hasParams) {
      final args = m.params.map(_deserializeExpr).join(', ');
      buf.writeln('          l.${m.name}($args),');
    } else {
      buf.writeln('          l.${m.name},');
    }
    buf
      ..writeln('        );')
      ..writeln('        return true;');
  }

  buf
    ..writeln('      default:')
    ..writeln(
      "        Log.w('L10nToastEffectHelper: 未匹配的 l10nCode: \$code');",
    )
    ..writeln('        return false;')
    ..writeln('    }')
    ..writeln('  }')
    ..writeln('')
    ..writeln('  static void _showToast(')
    ..writeln('    ToastService toastService,')
    ..writeln('    String? toastType,')
    ..writeln('    String msg,')
    ..writeln('  ) {')
    ..writeln('    switch (toastType) {')
    ..writeln("      case 'S':")
    ..writeln('        toastService.showSuccess(msg);')
    ..writeln("      case 'E':")
    ..writeln('        toastService.showError(msg);')
    ..writeln("      case 'W':")
    ..writeln('        toastService.showWarning(msg);')
    ..writeln('      default:')
    ..writeln('        toastService.showInfo(msg);')
    ..writeln('    }')
    ..writeln('  }')
    ..writeln('}')
    ..writeln('');

  return _format(buf.toString());
}

// ---------------------------------------------------------------------------
// 内部工具
// ---------------------------------------------------------------------------

/// 参数值存入 `parameters` 时的序列化表达式（原始字符串值，不编码）。
String _serializeExpr(L10nParam p) {
  final name = _safeParamName(p.name);
  return p.type == 'DateTime'
      ? '$name.toIso8601String()'
      : '$name.toString()';
}

/// factory 形参名：与类成员冲突的名字加 `Param` 后缀。
///
/// 仅影响形参名；`parameters` 的 map key 契约保持原名不变。
String _safeParamName(String name) =>
    (name == 'code' || name == 'parameters') ? '${name}Param' : name;

/// helper 中从 `parameters` 还原参数时的反序列化表达式（按声明类型）。
String _deserializeExpr(L10nParam p) {
  final raw = "l10nCode.parameters['${p.name}']";
  return switch (p.type) {
    'int' => "int.tryParse($raw ?? '') ?? 0",
    'double' => "double.tryParse($raw ?? '') ?? 0.0",
    'num' => "num.tryParse($raw ?? '') ?? 0",
    'bool' => "$raw == 'true'",
    'DateTime' =>
      "DateTime.tryParse($raw ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0)",
    // String / Object 及其他类型直接使用字符串值
    _ => "$raw ?? ''",
  };
}

/// 文档示例中使用的参数示例值。
String _exampleValue(L10nParam p) => switch (p.type) {
      'int' => '5',
      'double' => '1.5',
      'num' => '5',
      'bool' => 'true',
      'String' => "'flutter'",
      'DateTime' => 'DateTime.now()',
      _ => 'value',
    };

/// 生成文件头部（含 CLI 版本号，便于追溯）。
String _header() => '''
// GENERATED CODE - DO NOT MODIFY BY HAND
//
// 由 fluzer v$cliVersion gen-l10n 自动生成。
// 每次执行 fluzer gen-l10n 会重新生成此文件。
//
// Generated by fluzer v$cliVersion gen-l10n.
// This file is regenerated each time you run fluzer gen-l10n.

// ignore_for_file: type=lint

''';

/// 使用 dart_style 格式化生成内容；格式化失败时回退原始内容。
///
/// Formats generated source with dart_style. Falls back to the raw
/// source if formatting fails (should not happen for valid output).
String _format(String source) {
  try {
    return DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format(source);
  } on Object {
    return source;
  }
}
