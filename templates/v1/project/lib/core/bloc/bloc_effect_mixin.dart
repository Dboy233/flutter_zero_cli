import 'package:flutter_bloc/flutter_bloc.dart';

import '../effect/effect_state.dart';
import '../effect/ui_effect.dart';

/// 为 BLoC 添加一次性 UI 副作用能力。
///
/// 项目默认提供 [ToastEffect]、[DialogEffect]、[NavigationEffect]。
/// 自定义 Effect 需在 `lib/core/effect/ui_effect.dart` 中新增 `final class`，
/// 本 Mixin 与 [EffectState] 无需修改。
///
/// 用法：
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState>
///     with BlocEffectMixin<MyState> { ... }
/// ```
///
/// 触发副作用：
/// ```dart
/// emitEffect(const ToastEffect(messageCode: 'homeLoadFailed'));
/// ```
///
/// 若不使用国际化，也可以直接传递固定文本：
/// ```dart
/// emitEffect(const ToastEffect(message: '加载失败'));
/// ```
///
///
/// Adds one-time UI effect support to a BLoC.
///
/// The project provides [ToastEffect], [DialogEffect], and [NavigationEffect]
/// out of the box. To add a custom effect, declare a new `final class` in
/// `lib/core/effect/ui_effect.dart`; this mixin and [EffectState] do not need
/// to be changed.
///
/// Usage:
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState>
///     with BlocEffectMixin<MyState> { ... }
/// ```
///
/// Emit an effect:
/// ```dart
/// emitEffect(const ToastEffect(messageCode: 'homeLoadFailed'));
/// ```
///
/// If the project does not use internationalization, fixed text can be passed
/// directly:
/// ```dart
/// emitEffect(const ToastEffect(message: 'Loading failed'));
/// ```
mixin BlocEffectMixin<S extends EffectState> on BlocBase<S> {
  /// 触发一次性 UI 副作用。
  ///
  /// 通过 [EffectState.copyWithEffect] 将 effect 写入状态，由 [EffectListener]
  /// 监听并消费。
  ///
  /// Emits a one-time UI side effect.
  /// Writes the effect into state via [EffectState.copyWithEffect], which is
  /// then observed and consumed by [EffectListener].
  void emitEffect(UIEffect effect) {
    emit(state.copyWithEffect(effect: effect) as S);
  }

  /// 消费当前副作用，重置 effect 为 null。
  ///
  /// 调用 [EffectState.copyWithEffect] 时不传参数，使用默认 null 清除 effect。
  ///
  /// Consumes the current effect and resets it to null.
  void consumeEffect() {
    emit(state.copyWithEffect() as S);
  }
}
