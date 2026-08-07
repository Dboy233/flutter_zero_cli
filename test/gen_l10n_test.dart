import 'package:fluzer/src/gen_l10n/l10n_code_generator.dart';
import 'package:fluzer/src/gen_l10n/l10n_parser.dart';
import 'package:fluzer/src/i18n/gen/strings.g.dart';
import 'package:test/test.dart';

void main() {
  group('parseAppLocalizations', () {
    test('解析无参 getter', () {
      const source = '''
abstract class AppLocalizations {
  String get appTitle;
  String get homeRefreshSuccess;
}
''';
      final members = parseAppLocalizations(source, messages: AppLocale.zh.buildSync());
      expect(members, hasLength(2));
      expect(members[0].name, 'appTitle');
      expect(members[0].hasParams, isFalse);
      expect(members[1].name, 'homeRefreshSuccess');
    });

    test('解析 Object 参数方法', () {
      const source = '''
abstract class AppLocalizations {
  String counterValue(Object count);
}
''';
      final members = parseAppLocalizations(source, messages: AppLocale.zh.buildSync());
      expect(members, hasLength(1));
      expect(members[0].name, 'counterValue');
      expect(members[0].params, hasLength(1));
      expect(members[0].params[0].name, 'count');
      expect(members[0].params[0].type, 'Object');
    });

    test('解析带具体类型的参数（P0 回归）', () {
      const source = '''
abstract class AppLocalizations {
  String counterValue(int count);
  String itemPrice(double price);
  String greeting(String nickname);
  String eventDate(DateTime date);
  String multi(int count, String unit);
}
''';
      final members = parseAppLocalizations(source, messages: AppLocale.zh.buildSync());
      expect(members, hasLength(5));

      expect(members[0].params[0].type, 'int');
      expect(members[1].params[0].type, 'double');
      expect(members[2].params[0].type, 'String');
      expect(members[3].params[0].type, 'DateTime');

      expect(members[4].params, hasLength(2));
      expect(members[4].params[0].name, 'count');
      expect(members[4].params[0].type, 'int');
      expect(members[4].params[1].name, 'unit');
      expect(members[4].params[1].type, 'String');
    });

    test('排除 locale 实现类的干扰（P1-2 回归）', () {
      const source = '''
abstract class AppLocalizations {
  /// No description provided for @appTitle.
  String get appTitle;

  /// No description provided for @counterValue.
  String counterValue(int count);
}

class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'App Title';

  @override
  String counterValue(int count) => 'Count: \$count';
}

class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '应用标题';

  @override
  String counterValue(int count) => '计数：\$count';
}
''';
      final members = parseAppLocalizations(source, messages: AppLocale.zh.buildSync());
      // 只能解析出抽象类中的 2 个成员，不能重复计算实现类
      expect(members, hasLength(2));
      expect(members[0].name, 'appTitle');
      expect(members[1].name, 'counterValue');
      expect(members[1].params[0].type, 'int');
    });

    test('文档注释中的花括号不干扰类体边界', () {
      const source = '''
abstract class AppLocalizations {
  /// 用法示例："{count, plural, =0{none} other{{count}}}"
  String counterValue(int count);
}
''';
      final members = parseAppLocalizations(source, messages: AppLocale.zh.buildSync());
      expect(members, hasLength(1));
      expect(members[0].name, 'counterValue');
    });

    test('自定义 output-class 类名', () {
      const source = '''
abstract class MyL10n {
  String get appTitle;
}
''';
      final members = parseAppLocalizations(source, className: 'MyL10n', messages: AppLocale.zh.buildSync());
      expect(members, hasLength(1));
    });

    test('找不到抽象类时抛出 FormatException', () {
      const source = 'class NotAbstract {}';
      expect(
        () => parseAppLocalizations(source, messages: AppLocale.zh.buildSync()),
        throwsA(isA<FormatException>()),
      );
    });

    test('无法识别的参数声明抛出 FormatException（不静默跳过）', () {
      const source = '''
abstract class AppLocalizations {
  String weird(covariant int count);
}
''';
      expect(
        () => parseAppLocalizations(source, messages: AppLocale.zh.buildSync()),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('generateL10nCode', () {
    test('无参成员生成 static const 常量', () {
      final code = generateL10nCode([
        const L10nMember('appTitle', []),
      ]);
      expect(
        code,
        contains(
          "static const appTitle = L10nCode(code: 'appTitle', parameters: {});",
        ),
      );
    });

    test('有参成员 factory 保留原始类型（P0）', () {
      final code = generateL10nCode([
        const L10nMember('counterValue', [L10nParam('count', 'int')]),
      ]);
      expect(code, contains('factory L10nCode.counterValue(int count)'));
      expect(code, contains("'count': count.toString()"));
    });

    test('DateTime 参数使用 toIso8601String 序列化', () {
      final code = generateL10nCode([
        const L10nMember('eventDate', [L10nParam('date', 'DateTime')]),
      ]);
      expect(code, contains("'date': date.toIso8601String()"));
    });

    test('parameters 为 Map<String, String>（P1-5）', () {
      final code = generateL10nCode([const L10nMember('appTitle', [])]);
      expect(code, contains('final Map<String, String> parameters;'));
    });

    test('toString 在序列化边界统一编码，factory 内不手动编码（P1-1）', () {
      final code = generateL10nCode([
        const L10nMember('counterValue', [L10nParam('count', 'int')]),
      ]);
      expect(code, contains('Uri.encodeQueryComponent(e.key)'));
      expect(code, contains('Uri.encodeQueryComponent(e.value)'));
      // factory 内存原始值，不做手动编码
      expect(code, contains("'count': count.toString()"));
      expect(code, isNot(contains('encodeQueryComponent(count')));
    });

    test('parse 使用 Uri.splitQueryString 统一解码', () {
      final code = generateL10nCode([const L10nMember('appTitle', [])]);
      expect(code, contains('Uri.splitQueryString(value.substring(q + 1))'));
    });

    test('文档示例使用真实成员名', () {
      final code = generateL10nCode([
        const L10nMember('realKey', []),
        const L10nMember('realMethod', [L10nParam('x', 'int')]),
      ]);
      expect(code, contains('L10nCode.realKey.toString()'));
      expect(code, contains('L10nCode.realMethod(5)'));
    });

    test('header 包含 CLI 版本号', () {
      final code = generateL10nCode([const L10nMember('appTitle', [])]);
      expect(code, contains('fluzer v'));
    });

    test('生成 ==/hashCode 与 _mapEquals（值对象语义）', () {
      final code = generateL10nCode([const L10nMember('appTitle', [])]);
      expect(code, contains('bool operator ==(Object other)'));
      expect(code, contains('int get hashCode'));
      expect(code, contains('_mapEquals(other.parameters, parameters)'));
      expect(
        code,
        contains('bool _mapEquals(Map<String, String> a, Map<String, String> b)'),
      );
    });

    test('parse 对损坏输入兜底不抛异常', () {
      final code = generateL10nCode([const L10nMember('appTitle', [])]);
      expect(code, contains('try {'));
      expect(code, contains('on FormatException'));
    });

    test('factory 与 parse 产出不可变 parameters', () {
      final code = generateL10nCode([
        const L10nMember('counterValue', [L10nParam('count', 'int')]),
      ]);
      expect(code, contains('parameters: Map.unmodifiable({'));
      expect(
        code,
        contains('parameters: Map.unmodifiable(\n'
            '          Uri.splitQueryString(value.substring(q + 1)),\n'
            '        )'),
      );
    });

    test('与类成员冲突的形参名加 Param 后缀（map key 不变）', () {
      final code = generateL10nCode([
        const L10nMember('requestFailed', [L10nParam('code', 'String')]),
      ]);
      expect(code, contains('factory L10nCode.requestFailed(String codeParam)'));
      expect(code, contains("'code': codeParam.toString()"));
    });

    test('生成内容经 DartFormatter 格式化（无残留多余空行）', () {
      final code = generateL10nCode([
        const L10nMember('appTitle', []),
        const L10nMember('counterValue', [L10nParam('count', 'int')]),
      ]);
      // dart_style 输出不存在连续三个换行
      expect(code, isNot(contains('\n\n\n')));
      expect(code, endsWith('\n'));
    });
  });

  group('generateL10nCodeExt', () {
    test('生成四种类型标记与 toastType getter', () {
      final code = generateL10nCodeExt('my_app');
      expect(code, contains('L10nCode typeS()'));
      expect(code, contains('L10nCode typeE()'));
      expect(code, contains('L10nCode typeI()'));
      expect(code, contains('L10nCode typeW()'));
      expect(code, contains('String? get toastType'));
    });

    test('生成 toToastEffect 直达方法（ergonomics）', () {
      final code = generateL10nCodeExt('my_app');
      expect(
        code,
        contains('ToastEffect toToastEffect() => '
            'ToastEffect(l10nCode: toString())'),
      );
      expect(
        code,
        contains("import 'package:my_app/core/effect/ui_effect.dart';"),
      );
    });

    test('_withType 返回不可变 parameters', () {
      final code = generateL10nCodeExt('my_app');
      expect(code, contains('Map.unmodifiable({...parameters, _key: type})'));
    });
  });

  group('generateL10nToastEffectHelper', () {
    test('无参成员直接引用 getter', () {
      final code = generateL10nToastEffectHelper([
        const L10nMember('appTitle', []),
      ], 'my_app');
      expect(code, contains("case 'appTitle':"));
      expect(code, contains('l.appTitle'));
    });

    test('int 参数生成 int.tryParse 反序列化（P0）', () {
      final code = generateL10nToastEffectHelper([
        const L10nMember('counterValue', [L10nParam('count', 'int')]),
      ], 'my_app');
      expect(
        code,
        contains(
          "l.counterValue(int.tryParse(l10nCode.parameters['count'] ?? '') ?? 0)",
        ),
      );
    });

    test('DateTime 参数生成 DateTime.tryParse 反序列化', () {
      final code = generateL10nToastEffectHelper([
        const L10nMember('eventDate', [L10nParam('date', 'DateTime')]),
      ], 'my_app');
      expect(code, contains('DateTime.tryParse('));
    });

    test('Object/String 参数直接取字符串值', () {
      final code = generateL10nToastEffectHelper([
        const L10nMember('greeting', [L10nParam('name', 'String')]),
      ], 'my_app');
      expect(code, contains("l.greeting(l10nCode.parameters['name'] ?? '')"));
    });

    test('多参数按声明顺序展开', () {
      final code = generateL10nToastEffectHelper([
        const L10nMember('multi', [
          L10nParam('count', 'int'),
          L10nParam('unit', 'String'),
        ]),
      ], 'my_app');
      final countExpr =
          "int.tryParse(l10nCode.parameters['count'] ?? '') ?? 0";
      final unitExpr = "l10nCode.parameters['unit'] ?? ''";
      expect(code, contains(countExpr));
      expect(code, contains(unitExpr));
      // 参数顺序与声明一致
      expect(code.indexOf(countExpr), lessThan(code.indexOf(unitExpr)));
    });

    test('import 使用 widgets 而非 cupertino，包名可配置', () {
      final code = generateL10nToastEffectHelper([
        const L10nMember('appTitle', []),
      ], 'my_app');
      expect(code, contains("import 'package:flutter/widgets.dart';"));
      expect(code, contains('package:my_app/core/notifiers/toast_service.dart'));
      expect(code, isNot(contains('cupertino')));
    });

    test('复用 ext 的 toastType getter（magic key 单点化）', () {
      final code = generateL10nToastEffectHelper([
        const L10nMember('appTitle', []),
      ], 'my_app');
      expect(code, contains('final toastType = l10nCode.toastType;'));
      expect(code, contains("import 'l10n_code_ext.dart';"));
      expect(code, isNot(contains('parameters[L10nCode.toastTypeKey]')));
    });

    test('未匹配 key 输出警告日志', () {
      final code = generateL10nToastEffectHelper([
        const L10nMember('appTitle', []),
      ], 'my_app');
      expect(code, contains("import 'package:my_app/core/utils/log.dart';"));
      expect(code, contains('Log.w('));
    });
  });
}
