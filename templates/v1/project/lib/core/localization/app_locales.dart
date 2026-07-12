import 'package:flutter/material.dart';

/// 应用支持的语言列表。
///
/// 按语言标签标识：[AppLocales.zh]（简体中文）和 [AppLocales.en]（英语）。
///
/// List of supported locales for the app.
///
/// Identified by language tag: [AppLocales.zh] (Simplified Chinese)
/// and [AppLocales.en] (English).
abstract final class AppLocales {
  /// 简体中文。
  ///
  ///
  /// Simplified Chinese.
  static const zh = Locale('zh');

  /// 英语。
  ///
  ///
  /// English.
  static const en = Locale('en');

  /// 所有支持的语言列表。
  ///
  ///
  /// All supported locales.
  static const List<Locale> supported = [zh, en];

  /// 从语言代码字符串获取 [Locale]。
  ///
  /// [languageCode] 必须是 `'zh'` 或 `'en'`，否则返回 `null`。
  ///
  /// Resolves a [Locale] from a language code string.
  ///
  /// [languageCode] must be `'zh'` or `'en'`; returns `null` otherwise.
  static Locale? fromCode(String languageCode) {
    switch (languageCode) {
      case 'zh':
        return zh;
      case 'en':
        return en;
      default:
        return null;
    }
  }
}
