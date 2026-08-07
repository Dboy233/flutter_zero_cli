// CLI 国际化引导：区域解析与消息实例构建。
//
// i18n bootstrap: locale resolution and message instance construction.

import 'dart:io';

import 'gen/strings.g.dart';
export 'gen/strings.g.dart';

/// CLI 国际化入口。
///
/// 目录约定（本文件位于 `lib/src/i18n/` 根）：
/// - `resources/`：slang 源文件 `<locale>.i18n.json`（人工维护的翻译）；
/// - `gen/`：slang 生成的类型安全访问器 `strings*.g.dart`（由 `dart run slang` 产出）；
/// - `i18n.dart`：本文件，作为唯一入口——导出生成的访问器，并提供区域解析
///   与消息构建（[MessagesProvider]）。
///
/// i18n entry point. Directory layout (`lib/src/i18n/` root):
/// - `resources/`: slang source `<locale>.i18n.json` (hand-maintained);
/// - `gen/`: slang-generated type-safe accessors `strings*.g.dart`;
/// - `i18n.dart`: this file, the single entry — re-exports the generated
///   accessors and provides locale resolution + message construction.
///
/// 解析优先级：命令行 `--locale` 标志 > 环境变量 `LANG`/`LC_ALL`/`LANGUAGE` >
/// [Platform.localeName] > 默认 `zh`。
///
/// Resolution priority: `--locale` flag > `LANG`/`LC_ALL`/`LANGUAGE` env >
/// [Platform.localeName] > default `zh`.
final class MessagesProvider {
  /// 创建解析器。
  ///
  /// [rawLocale] 来自 `--locale` 标志，可为 null（此时回退到环境/系统区域）。
  /// [rawLocale] comes from the `--locale` flag; null falls back to env/system.
  const MessagesProvider({this.rawLocale});

  /// 来自 `--locale` 标志的原始区域值（可能为 null）。
  final String? rawLocale;

  /// 解析出 [AppLocale]；未知值回退到 [AppLocale.zh]。
  /// Resolves the [AppLocale]; unknown values fall back to [AppLocale.zh].
  AppLocale resolveLocale() {
    final code = _resolveLanguageCode() ?? 'zh';
    return switch (code) {
      'en' => AppLocale.en,
      'ja' => AppLocale.ja,
      _ => AppLocale.zh,
    };
  }

  /// 同步构建默认（zh）消息实例，用于测试或无需异步的场景。
  ///
  /// Synchronously builds the default (zh) message instance, used in tests
  /// or wherever async loading is undesirable.
  Translations get defaultMessages => AppLocale.zh.buildSync();

  /// 异步构建当前解析区域对应的消息实例。
  ///
  /// 基础语言 zh 用 [AppLocale.buildSync]（无需加载延迟库）；
  /// 非基础语言（en/ja）走延迟库，必须用 [AppLocale.build] 异步加载。
  /// 统一在此封装，调用方无需关心差异。
  ///
  /// Asynchronously builds the [Translations] for the resolved locale.
  /// The base locale `zh` uses [AppLocale.buildSync]; non-base locales
  /// (en/ja) use the deferred-library [AppLocale.build]. Callers don't need
  /// to care about the distinction.
  Future<Translations> build() async {
    final locale = resolveLocale();
    return locale == AppLocale.zh ? locale.buildSync() : await locale.build();
  }

  String? _resolveLanguageCode() {
    if (rawLocale != null) return _languageCodeFrom(rawLocale!);
    final env = Platform.environment;
    for (final key in const ['LANG', 'LC_ALL', 'LANGUAGE']) {
      final value = env[key];
      if (value != null && value.isNotEmpty) {
        final code = _languageCodeFrom(value);
        if (code != null) return code;
      }
    }
    return _languageCodeFrom(Platform.localeName);
  }

  /// 从区域字符串提取两字母语言代码（zh/en/ja），无法识别返回 null。
  ///
  /// 同时支持 BCP-47 代码形式（`zh_CN`、`en-US`）与 Windows 显示名形式
  /// （`Chinese (Simplified)_China`）。
  ///
  /// Extracts the two-letter language code (zh/en/ja); returns null if
  /// unrecognized. Handles both BCP-47 codes and Windows display names.
  String? _languageCodeFrom(String raw) {
    final lower = raw.toLowerCase();
    // 代码形式：zh_CN / en-US
    final codeMatch = RegExp(r'^([a-z]{2})[_-]').firstMatch(lower)?.group(1);
    if (codeMatch != null && _supported.contains(codeMatch)) return codeMatch;
    // 裸代码前缀
    for (final code in _supported) {
      if (lower.startsWith(code)) return code;
    }
    // Windows 显示名形式：Chinese (Simplified)_China
    if (lower.contains('chinese')) return 'zh';
    if (lower.contains('english')) return 'en';
    if (lower.contains('japanese')) return 'ja';
    return null;
  }

  static const Set<String> _supported = {'zh', 'en', 'ja'};
}
