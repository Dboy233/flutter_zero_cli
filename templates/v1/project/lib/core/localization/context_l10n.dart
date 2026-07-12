/// [BuildContext] 的国际化扩展。
///
/// 提供 `context.l` 简写，替代 `AppLocalizations.of(context)`，
/// 让 UI 层获取翻译文案更简洁：
///
/// ```dart
/// Text(context.l.appTitle);
/// ```
///
///
/// Internationalization extension for [BuildContext].
///
/// Provides `context.l` as a shorthand for `AppLocalizations.of(context)`,
/// making it more concise to access translated strings in the UI layer.
library;

import 'package:flutter/widgets.dart';

import '../../l10n/gen/app_localizations.dart';

/// 获取当前 context 的 [AppLocalizations] 实例。
///
/// 返回非空类型——需确保上层 Widget 树已注册 `localizationsDelegates`。
///
///
/// Returns the [AppLocalizations] for the current [BuildContext].
///
/// Non-nullable — ensure `localizationsDelegates` are registered upstream.
extension ContextL10nExtension on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this);
}
