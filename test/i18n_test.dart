// CLI 国际化测试 / CLI internationalization tests.
//
// 覆盖三层保障：
// 1) 区域解析（MessagesProvider）：`--locale` > 环境变量 > 系统区域 > 默认 zh，
//    含 BCP-47 代码、Windows 显示名、大小写、未知值回退、ja 支持。
// 2) 消息访问器与占位符：三种语言能正确取值并注入参数。
// 3) 跨语言键/占位符一致性：en/ja 的 key 必须全部存在于 zh，且占位符名集合一致。
//    这一条能防止「翻译漏写 key / 占位符名不一致」这类静默退化（ja 资源曾因此丢失）。
//
// Covers three layers: locale resolution, message accessors/placeholders, and
// cross-locale key/placeholder consistency.

import 'dart:convert';
import 'dart:io';

import 'package:fluzer/src/i18n/i18n.dart';
import 'package:test/test.dart';

/// 把嵌套 JSON 拍平成 `dot.path -> 叶子字符串` 的映射，便于跨语言比对 key。
Map<String, String> flattenValues(
  Map<String, dynamic> map, [
  String prefix = '',
]) {
  final out = <String, String>{};
  map.forEach((key, value) {
    final full = prefix.isEmpty ? key : '$prefix.$key';
    if (value is Map<String, dynamic>) {
      out.addAll(flattenValues(value, full));
    } else {
      out[full] = value.toString();
    }
  });
  return out;
}

/// 提取字符串中的 `{占位符}` 名集合（忽略 `$var` 这种 slang 写法以外的形式）。
Set<String> placeholders(String value) => RegExp(
  r'\{([a-zA-Z_][a-zA-Z0-9_]*)\}',
).allMatches(value).map((m) => m.group(1)!).toSet();

Map<String, dynamic> loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  group('MessagesProvider.resolveLocale', () {
    test('显式 --locale 映射：en/ja/zh', () {
      expect(
        const MessagesProvider(rawLocale: 'en').resolveLocale(),
        AppLocale.en,
      );
      expect(
        const MessagesProvider(rawLocale: 'ja').resolveLocale(),
        AppLocale.ja,
      );
      expect(
        const MessagesProvider(rawLocale: 'zh').resolveLocale(),
        AppLocale.zh,
      );
    });

    test('未知语言回退到 zh', () {
      expect(
        const MessagesProvider(rawLocale: 'fr').resolveLocale(),
        AppLocale.zh,
      );
      expect(
        const MessagesProvider(rawLocale: 'xx').resolveLocale(),
        AppLocale.zh,
      );
    });

    test('大小写不敏感', () {
      expect(
        const MessagesProvider(rawLocale: 'JA').resolveLocale(),
        AppLocale.ja,
      );
      expect(
        const MessagesProvider(rawLocale: 'En').resolveLocale(),
        AppLocale.en,
      );
    });

    test('BCP-47 代码形式（zh_CN / en-US / ja-JP）', () {
      expect(
        const MessagesProvider(rawLocale: 'zh_CN').resolveLocale(),
        AppLocale.zh,
      );
      expect(
        const MessagesProvider(rawLocale: 'en-US').resolveLocale(),
        AppLocale.en,
      );
      expect(
        const MessagesProvider(rawLocale: 'ja-JP').resolveLocale(),
        AppLocale.ja,
      );
    });

    test('Windows 显示名形式（Chinese / English / Japanese）', () {
      expect(
        const MessagesProvider(
          rawLocale: 'Chinese (Simplified)_China',
        ).resolveLocale(),
        AppLocale.zh,
      );
      expect(
        const MessagesProvider(
          rawLocale: 'English_United States',
        ).resolveLocale(),
        AppLocale.en,
      );
      expect(
        const MessagesProvider(rawLocale: 'Japanese_Japan').resolveLocale(),
        AppLocale.ja,
      );
    });

    test('defaultMessages 返回基础语言 zh', () {
      expect(
        const MessagesProvider().defaultMessages.app.description,
        contains('脚手架'),
      );
    });
  });

  group('环境变量驱动的区域（通过真实 CLI 子进程验证优先级）', () {
    // Platform.environment 在测试内不可变，故启动子进程并注入环境来验证
    // `--locale` 缺失时 env > 系统区域 的回退路径。
    Future<String> runHelpWithEnv(Map<String, String> env) async {
      final result = await Process.run(
        'dart',
        ['run', 'bin/fluzer.dart', '--help'],
        environment: {'LANG': 'C', 'LC_ALL': 'C', 'LANGUAGE': 'C', ...env},
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      return result.stdout as String;
    }

    test('LANG=en_US 时输出英文', () async {
      final out = await runHelpWithEnv({
        'LANG': 'en_US.UTF-8',
        'LC_ALL': 'en_US.UTF-8',
        'LANGUAGE': 'en_US',
      });
      expect(out, contains('scaffolding'));
    }, timeout: const Timeout(Duration(seconds: 120)));

    test('LANG=ja_JP 时输出日文', () async {
      final out = await runHelpWithEnv({
        'LANG': 'ja_JP.UTF-8',
        'LC_ALL': 'ja_JP.UTF-8',
        'LANGUAGE': 'ja_JP',
      });
      expect(out, contains('スキャフォールド'));
    }, timeout: const Timeout(Duration(seconds: 120)));
  });

  group('Translations 访问器与占位符', () {
    // 非基础语言（en/ja）用延迟库，必须用异步 build() 加载；
    // 基础语言 zh 可用 buildSync()。生产代码（fluzer.dart）同样走异步 build()。
    Future<Translations> messagesFor(AppLocale locale) async =>
        locale == AppLocale.zh ? locale.buildSync() : await locale.build();

    test('三种语言的 app.description 各不相同且非空', () async {
      final zh = (await messagesFor(AppLocale.zh)).app.description;
      final en = (await messagesFor(AppLocale.en)).app.description;
      final ja = (await messagesFor(AppLocale.ja)).app.description;
      expect(zh, contains('脚手架'));
      expect(en, contains('scaffolding'));
      expect(ja, contains('スキャフォールド'));
      expect({zh, en, ja}.length, 3, reason: '三种语言描述不应完全相同');
    });

    test('占位符正确注入（feature.successCreated）', () async {
      const feature = 'user_profile';
      expect(
        (await messagesFor(
          AppLocale.zh,
        )).feature.successCreated(feature: feature),
        contains(feature),
      );
      expect(
        (await messagesFor(
          AppLocale.en,
        )).feature.successCreated(feature: feature),
        contains(feature),
      );
      expect(
        (await messagesFor(
          AppLocale.ja,
        )).feature.successCreated(feature: feature),
        contains(feature),
      );
    });

    test('spinner 完成/失败后缀随语言变化', () async {
      expect(
        (await messagesFor(AppLocale.zh)).spinner.stepCompleted(label: 'X'),
        'X 完成',
      );
      expect(
        (await messagesFor(AppLocale.ja)).spinner.stepFailed(label: 'Y'),
        'Y 失敗',
      );
      expect(
        (await messagesFor(AppLocale.en)).spinner.stepCompleted(label: 'X'),
        'X completed',
      );
    });
  });

  group('跨语言键与占位符一致性', () {
    final zhVals = flattenValues(loadJson('lib/src/i18n/resources/zh.i18n.json'));
    final enVals = flattenValues(loadJson('lib/src/i18n/resources/en.i18n.json'));
    final jaVals = flattenValues(loadJson('lib/src/i18n/resources/ja.i18n.json'));

    test('en 的所有 key 必须存在于 zh', () {
      final missing = enVals.keys.toSet().difference(zhVals.keys.toSet());
      expect(missing, isEmpty, reason: 'en 缺失 zh 中的 key：$missing');
    });

    test('ja 的所有 key 必须存在于 zh', () {
      final missing = jaVals.keys.toSet().difference(zhVals.keys.toSet());
      expect(missing, isEmpty, reason: 'ja 缺失 zh 中的 key：$missing');
    });

    test('en/ja 每个 key 的占位符名集合必须与 zh 一致', () {
      for (final entry in zhVals.entries) {
        final key = entry.key;
        final zhPh = placeholders(entry.value);
        if (enVals.containsKey(key)) {
          expect(
            placeholders(enVals[key]!),
            zhPh,
            reason: 'en 占位符与 zh 不一致：$key',
          );
        }
        if (jaVals.containsKey(key)) {
          expect(
            placeholders(jaVals[key]!),
            zhPh,
            reason: 'ja 占位符与 zh 不一致：$key',
          );
        }
      }
    });

    test('三种语言 key 总数应一致', () {
      expect(enVals.length, zhVals.length, reason: 'en 与 zh 的 key 数量不同');
      expect(jaVals.length, zhVals.length, reason: 'ja 与 zh 的 key 数量不同');
    });
  });
}
