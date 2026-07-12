/// 一次性 UI 副作用类型。
///
/// BLoC 通过 [emitEffect] 发出副作用，由 UI 层 [EffectListener] 消费并执行。
/// 消费后会被自动清空，避免重复触发。
///
/// 本库不强制依赖任何国际化框架。开发者可以直接传递固定文本，也可以传递
/// 任意国际化方案的消息标识（gen-l10n ARB key、slang path、easy_localization
/// JSON key 等），由 UI 层自行解析。
///
///
/// One-time UI side effect types.
///
/// BLoCs emit effects via [emitEffect]; UI layer consumes them via
/// [EffectListener] and executes them. Effects are automatically cleared
/// after consumption to prevent duplicate triggers.
///
/// This library does not depend on any internationalization framework. Developers
/// can pass fixed text or any i18n key (gen-l10n ARB key, slang path,
/// easy_localization JSON key, etc.) and resolve it in the UI layer.
sealed class UIEffect {
  const UIEffect();
}

/// Toast 提示副作用。
///
/// 本类不强制依赖任何国际化框架。[message] 可直接用于显示固定文本；
/// [messageCode] 可用于 gen-l10n、slang、easy_localization 等任意方案，
/// 由 UI 层自行决定如何解析。也可以同时提供两者，让 UI 层优先使用 [message]。
///
/// Toast message effect.
///
/// This class does not depend on any internationalization framework. Use [message]
/// for fixed text, or [messageCode] for any i18n key (gen-l10n, slang,
/// easy_localization, etc.). The UI layer decides how to resolve it.
final class ToastEffect extends UIEffect {
  const ToastEffect({this.message, this.messageCode, this.extra});

  /// 可直接显示的文本。
  ///
  /// Fixed text to display directly.
  final String? message;

  /// 消息标识，由 UI 层根据项目的国际化方案解析。
  ///
  /// Message code resolved by the UI layer according to the project's i18n setup.
  final String? messageCode;

  /// 额外参数。
  /// Extra arguments.
  final Object? extra;
}

/// 对话框副作用。
///
/// 本类只携带业务类型标识 [type] 和可选的 [extra]。具体的标题、内容、
/// 按钮样式等 UI 细节由 UI 层根据 [type] 自行决定。
///
/// Dialog effect.
///
/// This class only carries a business [type] and optional [extra]. The UI layer
/// decides the title, content, button styles, etc. based on [type].
final class DialogEffect extends UIEffect {
  const DialogEffect({required this.type, this.extra});

  /// 对话框业务类型标识，例如 `retry`、`refresh_success`。
  ///
  /// Business type identifier, e.g. `retry`, `refresh_success`.
  final String type;

  /// 额外参数，可用于传递标题、内容、回调标识等。
  ///
  /// Extra arguments, such as title, content, or callback identifiers.
  final Object? extra;
}

/// 导航副作用。
///
/// Navigation effect.
final class NavigationEffect extends UIEffect {
  const NavigationEffect(this.type, this.route, {this.extra});

  final NavigationEffectType type;

  /// 目标路由路径。
  /// Destination route path.
  final String route;

  /// 额外参数。
  /// Extra arguments.
  final Object? extra;
}


enum NavigationEffectType { go, push, pop, replace }

// 扩展 Effect 类型：
// 1. 在 [UIEffect] 所在文件（即本文件）新增 `final class XxxEffect extends UIEffect { ... }`。
//    由于 [UIEffect] 是 sealed class，新的子类必须定义在同一个库（library）内。
// 2. 在 [EffectListener.onEffect] 的 switch 分支中增加对应的 case。
// 3. 在 BLoC 中通过 `emitEffect(XxxEffect(...))` 发出新的副作用。
// 4. 不需要修改 [BlocEffectMixin] 或 [EffectState]。
//
// To extend the effect type:
// 1. Add `final class XxxEffect extends UIEffect { ... }` in this file
//    (the same library as [UIEffect]). [UIEffect] is sealed, so new subclasses
//    must be declared within the same library.
// 2. Add a corresponding case in [EffectListener.onEffect].
// 3. Emit the new effect in a BLoC via `emitEffect(XxxEffect(...))`.
// 4. [BlocEffectMixin] and [EffectState] do not need to be changed.
