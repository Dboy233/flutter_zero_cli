/// l10n 参数的类型处理器。
///
/// 生成器（[generateL10nCode] / [generateL10nToastEffectHelper]）不再按
/// 字符串类型名做 `switch`，而是把"如何序列化 / 反序列化 / 给示例值"这个
/// 行为交给每种类型自己封装，通过 [L10nParamType.fromName] 注册表按原始
/// 类型名解析。
///
/// 新增一种支持的类型只需要：
///   1. 新增一个 [L10nParamType] 子类，override 三个表达式方法；
///   2. 在 [_registry] 中登记原始类型名。
/// 生成器代码无需任何改动（满足开闭原则）。
///
/// 未知类型回退为 [unknown]（行为与 `Object` 一致）。
library;

/// 一个 l10n 参数类型的表达式处理策略。
///
/// 封装"把参数值序列化为字符串 / 从字符串反序列化 / 给出示例值"三类
/// 行为，取代原先分散在生成器中的多处 `switch (type)`。
abstract class L10nParamType {
  const L10nParamType(this.dartType);

  /// 对应的 Dart 类型名（用于调试与日志）。
  final String dartType;

  /// 将参数值存入 [L10nCode.parameters] 时的序列化表达式（不编码）。
  ///
  /// [paramName] 为形参名，例如 `count`。
  /// 返回形如 `count.toString()` 或 `date.toIso8601String()` 的表达式。
  String serializeExpr(String paramName);

  /// 从 [L10nCode.parameters] 还原参数时的反序列化表达式。
  ///
  /// [rawAccess] 为对原始字符串值的访问表达式，
  /// 例如 `l10nCode.parameters['count']`。
  String deserializeExpr(String rawAccess);

  /// 文档示例中使用的参数示例值表达式（如 `5`、`'flutter'`）。
  String exampleValue();

  /// 根据原始类型名解析为对应的类型处理器。
  /// 未知类型回退为 [unknown]（行为与 `Object` 一致）。
  static L10nParamType fromName(String name) => _registry[name] ?? unknown;

  // --- 预置类型（const 复用）---
  static const string = _StringType();
  static const integer = _IntType();
  static const doubleType = _DoubleType();
  static const numType = _NumType();
  static const boolType = _BoolType();
  static const dateTime = _DateTimeType();
  static const unknown = _FallbackType();

  static final Map<String, L10nParamType> _registry = {
    'String': string,
    'int': integer,
    'double': doubleType,
    'num': numType,
    'bool': boolType,
    'DateTime': dateTime,
  };
}

class _StringType extends L10nParamType {
  const _StringType() : super('String');
  @override
  String serializeExpr(String paramName) => '$paramName.toString()';
  @override
  String deserializeExpr(String rawAccess) => "$rawAccess ?? ''";
  @override
  String exampleValue() => "'flutter'";
}

class _IntType extends L10nParamType {
  const _IntType() : super('int');
  @override
  String serializeExpr(String paramName) => '$paramName.toString()';
  @override
  String deserializeExpr(String rawAccess) =>
      "int.tryParse($rawAccess ?? '') ?? 0";
  @override
  String exampleValue() => '5';
}

class _DoubleType extends L10nParamType {
  const _DoubleType() : super('double');
  @override
  String serializeExpr(String paramName) => '$paramName.toString()';
  @override
  String deserializeExpr(String rawAccess) =>
      "double.tryParse($rawAccess ?? '') ?? 0.0";
  @override
  String exampleValue() => '1.5';
}

class _NumType extends L10nParamType {
  const _NumType() : super('num');
  @override
  String serializeExpr(String paramName) => '$paramName.toString()';
  @override
  String deserializeExpr(String rawAccess) =>
      "num.tryParse($rawAccess ?? '') ?? 0";
  @override
  String exampleValue() => '5';
}

class _BoolType extends L10nParamType {
  const _BoolType() : super('bool');
  @override
  String serializeExpr(String paramName) => '$paramName.toString()';
  @override
  String deserializeExpr(String rawAccess) => "$rawAccess == 'true'";
  @override
  String exampleValue() => 'true';
}

class _DateTimeType extends L10nParamType {
  const _DateTimeType() : super('DateTime');
  @override
  String serializeExpr(String paramName) => '$paramName.toIso8601String()';
  @override
  String deserializeExpr(String rawAccess) =>
      "DateTime.tryParse($rawAccess ?? '') ?? "
      'DateTime.fromMillisecondsSinceEpoch(0)';
  @override
  String exampleValue() => 'DateTime.now()';
}

class _FallbackType extends L10nParamType {
  const _FallbackType() : super('Object');
  @override
  String serializeExpr(String paramName) => '$paramName.toString()';
  @override
  String deserializeExpr(String rawAccess) => "$rawAccess ?? ''";
  @override
  String exampleValue() => 'value';
}
