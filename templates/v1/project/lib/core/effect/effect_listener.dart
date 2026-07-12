import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/bloc_effect_mixin.dart';
import 'effect_state.dart';
import 'ui_effect.dart';

/// 自动监听并消费一次性 UI 副作用。
///
/// 项目默认提供 [ToastEffect]、[DialogEffect]、[NavigationEffect]。
/// 如需自定义 Effect，请先在 `lib/core/effect/ui_effect.dart` 中新增 `final class`，
/// 然后在本组件的 [onEffect] switch 中增加对应分支。
///
/// 用法：
/// ```dart
/// BlocProvider(
///   create: (_) {
///     return getIt<MyBloc>();
///   },
///   child: EffectListener<MyBloc, MyState>(
///     onEffect: (context, effect) {
///       switch (effect) {
///         case ToastEffect(:final message, :final messageCode):
///           final text = message ?? _resolveMessage(messageCode, context.l);
///           getIt<ToastService>().showError(text);
///         case NavigationEffect(:final type, :final route, :final extra):
///           switch (type) {
///             case NavigationEffectType.go:
///               context.go(route, extra: extra);
///             case NavigationEffectType.push:
///               unawaited(context.push(route, extra: extra));
///             case NavigationEffectType.pop:
///               context.pop(extra);
///             case NavigationEffectType.replace:
///               context.replace(route, extra: extra);
///           }
///         case _:
///           break;
///       }
///     },
///     child: const MyPageBody(),
///   ),
/// )
/// ```
///
///
/// Automatically listens to and consumes one-time UI effects.
///
/// The project provides [ToastEffect], [DialogEffect], and [NavigationEffect]
/// out of the box. To add a custom effect, declare a new `final class` in
/// `lib/core/effect/ui_effect.dart` first, then add a corresponding branch in the [onEffect]
/// switch of this widget.
///
/// Usage:
/// ```dart
/// BlocProvider(
///   create: (_) {
///     return getIt<MyBloc>();
///   },
///   child: EffectListener<MyBloc, MyState>(
///     onEffect: (context, effect) {
///       switch (effect) {
///         case ToastEffect(:final message, :final messageCode):
///           final text = message ?? _resolveMessage(messageCode, context.l);
///           getIt<ToastService>().showError(text);
///         case NavigationEffect(:final type, :final route, :final extra):
///           switch (type) {
///             case NavigationEffectType.go:
///               context.go(route, extra: extra);
///             case NavigationEffectType.push:
///               unawaited(context.push(route, extra: extra));
///             case NavigationEffectType.pop:
///               context.pop(extra);
///             case NavigationEffectType.replace:
///               context.replace(route, extra: extra);
///           }
///         case _:
///           break;
///       }
///     },
///     child: const MyPageBody(),
///   ),
/// )
/// ```
class EffectListener<B extends BlocBase<S>, S extends EffectState>
    extends StatelessWidget {
  const EffectListener({
    required this.onEffect,
    required this.child,
    super.key,
  });

  /// 副作用处理回调。
  ///
  /// Callback invoked when a new effect is emitted.
  final void Function(BuildContext context, UIEffect effect) onEffect;

  /// 子组件。
  ///
  /// Child widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<B, S>(
      listenWhen: (previous, current) {
        return previous.effect != current.effect && current.effect != null;
      },
      listener: (context, state) {
        final bloc = context.read<B>();
        if (bloc is! BlocEffectMixin<S>) {
          throw StateError(
            '$B must use BlocEffectMixin<$S> to support effects. '
            'Add `with BlocEffectMixin<$S>` to your BLoC class.',
          );
        }
        final effect = state.effect!;
        onEffect(context, effect);
        bloc.consumeEffect();
      },
      child: child,
    );
  }
}
