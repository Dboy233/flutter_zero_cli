// L10nParamType 单元测试 / Unit tests for L10nParamType.
//
// 覆盖 7 种类型处理器的 serializeExpr / deserializeExpr / exampleValue，
// 以及 fromName 注册表解析与未知类型回退、dartType 标签。
//
// Covers the 7 type handlers' serializeExpr / deserializeExpr / exampleValue,
// plus fromName registry resolution, unknown-type fallback, and dartType tags.

import 'package:fluzer/src/gen_l10n/l10n_param_type.dart';
import 'package:test/test.dart';

void main() {
  group('L10nParamType.fromName', () {
    test('已知类型按原始类型名解析为注册表单例', () {
      expect(L10nParamType.fromName('String'), same(L10nParamType.string));
      expect(L10nParamType.fromName('int'), same(L10nParamType.integer));
      expect(
        L10nParamType.fromName('double'),
        same(L10nParamType.doubleType),
      );
      expect(L10nParamType.fromName('num'), same(L10nParamType.numType));
      expect(L10nParamType.fromName('bool'), same(L10nParamType.boolType));
      expect(
        L10nParamType.fromName('DateTime'),
        same(L10nParamType.dateTime),
      );
    });

    test('未知类型回退 unknown 单例', () {
      expect(L10nParamType.fromName('List'), same(L10nParamType.unknown));
      expect(L10nParamType.fromName(''), same(L10nParamType.unknown));
      expect(
        L10nParamType.fromName('CustomType'),
        same(L10nParamType.unknown),
      );
    });
  });

  group('序列化 / 反序列化 / 示例值', () {
    test('String', () {
      final t = L10nParamType.string;
      expect(t.serializeExpr('name'), 'name.toString()');
      expect(t.deserializeExpr("p['name']"), "p['name'] ?? ''");
      expect(t.exampleValue(), "'flutter'");
    });

    test('int', () {
      final t = L10nParamType.integer;
      expect(t.serializeExpr('count'), 'count.toString()');
      expect(
        t.deserializeExpr("p['count']"),
        "int.tryParse(p['count'] ?? '') ?? 0",
      );
      expect(t.exampleValue(), '5');
    });

    test('double', () {
      final t = L10nParamType.doubleType;
      expect(t.serializeExpr('ratio'), 'ratio.toString()');
      expect(
        t.deserializeExpr("p['ratio']"),
        "double.tryParse(p['ratio'] ?? '') ?? 0.0",
      );
      expect(t.exampleValue(), '1.5');
    });

    test('num', () {
      final t = L10nParamType.numType;
      expect(t.serializeExpr('value'), 'value.toString()');
      expect(
        t.deserializeExpr("p['value']"),
        "num.tryParse(p['value'] ?? '') ?? 0",
      );
      expect(t.exampleValue(), '5');
    });

    test('bool', () {
      final t = L10nParamType.boolType;
      expect(t.serializeExpr('flag'), 'flag.toString()');
      expect(t.deserializeExpr("p['flag']"), "p['flag'] == 'true'");
      expect(t.exampleValue(), 'true');
    });

    test('DateTime', () {
      final t = L10nParamType.dateTime;
      expect(t.serializeExpr('date'), 'date.toIso8601String()');
      expect(
        t.deserializeExpr("p['date']"),
        "DateTime.tryParse(p['date'] ?? '') ?? "
        'DateTime.fromMillisecondsSinceEpoch(0)',
      );
      expect(t.exampleValue(), 'DateTime.now()');
    });

    test('unknown (Object 回退)', () {
      final t = L10nParamType.unknown;
      expect(t.dartType, 'Object');
      expect(t.serializeExpr('x'), 'x.toString()');
      expect(t.deserializeExpr("p['x']"), "p['x'] ?? ''");
      expect(t.exampleValue(), 'value');
    });
  });

  group('dartType 标签', () {
    test('各类型 dartType 正确', () {
      expect(L10nParamType.string.dartType, 'String');
      expect(L10nParamType.integer.dartType, 'int');
      expect(L10nParamType.doubleType.dartType, 'double');
      expect(L10nParamType.numType.dartType, 'num');
      expect(L10nParamType.boolType.dartType, 'bool');
      expect(L10nParamType.dateTime.dartType, 'DateTime');
      expect(L10nParamType.unknown.dartType, 'Object');
    });
  });
}
