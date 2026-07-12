import 'ui_effect.dart';

/// 支持一次性 UI 副作用的状态接口。
///
/// 所有需要 [BlocEffectMixin] 的 BLoC 状态都应该实现该接口。
///
///
/// State interface that supports one-time UI effects.
///
/// All BLoC states that need [BlocEffectMixin] should implement this interface.
abstract class EffectState {
  /// 默认构造函数，允许子类使用 const。
  ///
  /// Default constructor allowing subclasses to be const.
  const EffectState();

  /// 当前待消费的 UI 副作用，未消费时为 null。
  ///
  /// The pending UI effect; null if none.
  UIEffect? get effect;

  /// 返回一个 effect 被替换后的新状态。
  ///
  /// Returns a new state with the effect replaced.
  EffectState copyWithEffect({UIEffect? effect});
}
