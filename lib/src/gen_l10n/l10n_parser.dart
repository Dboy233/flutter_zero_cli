/// `app_localizations.dart` 源码解析。
///
/// 仅解析 `abstract class <className>` 类体内的抽象声明，
/// 不受各 locale 实现类（`=>` 表达式体）的干扰。
///
/// Parser for the generated `app_localizations.dart`. Extracts the
/// abstract member declarations from the `AppLocalizations` class body.
library;

/// 本地化方法参数（名称 + Dart 类型）。
///
/// A method parameter of a localization member: [name] and its
/// declared Dart [type] (e.g. `Object`, `int`, `String`, `DateTime`).
class L10nParam {
  /// 创建参数。
  const L10nParam(this.name, this.type);

  /// 参数名。
  final String name;

  /// 参数声明类型。
  final String type;

  @override
  String toString() => 'L10nParam($type $name)';
}

/// `AppLocalizations` 抽象类中的一个本地化成员。
///
/// One localization member: a no-arg getter ([params] empty) or a
/// parameterized method.
class L10nMember {
  /// 创建成员。
  const L10nMember(this.name, this.params);

  /// 成员名（即 ARB key）。
  final String name;

  /// 方法参数列表；无参 getter 为空列表。
  final List<L10nParam> params;

  /// 是否带参数。
  bool get hasParams => params.isNotEmpty;

  @override
  String toString() => 'L10nMember($name, $params)';
}

/// 从生成的 app_localizations.dart 源码中解析出所有本地化成员。
///
/// [className] 对应 l10n.yaml 的 `output-class`，默认 `AppLocalizations`。
///
/// 无法识别的成员/参数声明会抛出 [FormatException]——宁可失败也不
/// 静默生成错误的代码。
List<L10nMember> parseAppLocalizations(
  String source, {
  String className = 'AppLocalizations',
}) {
  final body = extractClassBody(source, className);
  final members = <L10nMember>[];

  // String get xxx;（无参 getter）
  final getterRegex = RegExp(r'^\s*String\s+get\s+(\w+)\s*;', multiLine: true);
  for (final m in getterRegex.allMatches(body)) {
    members.add(L10nMember(m.group(1)!, const []));
  }

  // String xxx(Type p1, Type p2);（有参方法）
  final methodRegex =
      RegExp(r'^\s*String\s+(\w+)\(([^)]*)\)\s*;', multiLine: true);
  for (final m in methodRegex.allMatches(body)) {
    members.add(L10nMember(m.group(1)!, _parseParams(m.group(2)!, m.group(1)!)));
  }

  return members;
}

/// 解析方法参数串 `"Object count, int index"` → [L10nParam] 列表。
List<L10nParam> _parseParams(String paramsStr, String memberName) {
  final params = <L10nParam>[];
  for (final raw in paramsStr.split(',')) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) continue;
    final m = RegExp(r'^(\w+)\s+(\w+)$').firstMatch(trimmed);
    if (m == null) {
      throw FormatException(
        '无法解析成员 $memberName 的参数声明: "$trimmed"。\n'
        'Unable to parse parameter "$trimmed" of member "$memberName".',
      );
    }
    params.add(L10nParam(m.group(2)!, m.group(1)!));
  }
  return params;
}

/// 提取 `abstract class <className>` 的类体内容（不含外层花括号）。
///
/// 使用括号计数扫描，跳过行注释、块注释与字符串字面量中的花括号，
/// 避免文档注释里的 `{...}` 干扰匹配。
///
/// Extracts the body of `abstract class <className>` using a
/// brace-counting scanner that skips comments and string literals.
String extractClassBody(String source, String className) {
  final decl =
      RegExp('abstract\\s+class\\s+$className\\b').firstMatch(source);
  if (decl == null) {
    throw FormatException(
      '未找到 abstract class $className 声明，请检查 l10n.yaml 的 output-class 配置。\n'
      'Declaration "abstract class $className" not found. '
      'Check "output-class" in l10n.yaml.',
    );
  }
  final start = source.indexOf('{', decl.end);
  if (start == -1) {
    throw FormatException('$className 声明后未找到类体 / class body not found.');
  }

  var depth = 0;
  var i = start;
  while (i < source.length) {
    final c = source[i];

    // 行注释
    if (c == '/' && i + 1 < source.length && source[i + 1] == '/') {
      final nl = source.indexOf('\n', i);
      i = nl == -1 ? source.length : nl + 1;
      continue;
    }
    // 块注释
    if (c == '/' && i + 1 < source.length && source[i + 1] == '*') {
      final end = source.indexOf('*/', i + 2);
      i = end == -1 ? source.length : end + 2;
      continue;
    }
    // 字符串字面量（单/双引号，含三引号与转义）
    if (c == "'" || c == '"') {
      i = _skipString(source, i);
      continue;
    }

    if (c == '{') depth++;
    if (c == '}') {
      depth--;
      if (depth == 0) return source.substring(start + 1, i);
    }
    i++;
  }

  throw FormatException(
    '$className 类体未闭合 / class body of $className is not closed.',
  );
}

/// 跳过从 [i]（引号位置）开始的字符串字面量，返回字面量后的下标。
int _skipString(String source, int i) {
  final quote = source[i];
  // 三引号字符串
  if (i + 2 < source.length && source[i + 1] == quote && source[i + 2] == quote) {
    final end = source.indexOf(quote * 3, i + 3);
    return end == -1 ? source.length : end + 3;
  }
  var j = i + 1;
  while (j < source.length) {
    if (source[j] == r'\') {
      j += 2;
      continue;
    }
    if (source[j] == quote) return j + 1;
    j++;
  }
  return source.length;
}
