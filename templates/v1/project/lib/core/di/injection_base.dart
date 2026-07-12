import 'package:meta/meta.dart';

import 'get_it_instance.dart';

/// DI 抽象基类。
///
/// 父类定义注册顺序：基础设施 → Feature Modules → 用户自定义。
/// 新增 Feature Module 时，在 `registerFeatureModules()` 中手动添加
/// `XxxModule.register(getIt)` 调用。
///
/// Abstract base class for dependency injection.
///
/// The base class defines the registration order:
/// infrastructure → Feature Modules → user-defined dependencies.
/// When adding a new Feature Module, manually add the
/// `XxxModule.register(getIt)` call in `registerFeatureModules()`.
abstract class InjectionBase {
  /// 对外入口，在 `main.dart` 中调用。
  ///
  /// Entry point called in `main.dart`.
  Future<void> registerAll() async {
    await registerBaseDependencies();
    await registerFeatureModules();
    await registerUserDependencies();
    await getIt.allReady();
  }

  /// 子类实现：注册所有基础设施依赖。
  ///
  /// 包括 storage / auth / network / notifiers / localization 等
  /// 用户可能会替换实现的层。
  ///
  /// Subclass implementation: register all infrastructure dependencies.
  ///
  /// Includes layers the user may want to swap, such as storage, auth,
  /// network, notifiers, and localization.
  @protected
  Future<void> registerBaseDependencies();

  /// 子类实现：注册用户自定义依赖。
  ///
  /// Subclass implementation: register user-defined dependencies.
  @protected
  Future<void> registerUserDependencies();

  /// 父类默认实现：注册所有 Feature Modules。
  ///
  /// 新增模块时在此处手动添加 `XxxModule.register(getIt)` 调用。
  ///
  /// Base-class default: register all Feature Modules.
  ///
  /// Manually add `XxxModule.register(getIt)` calls here
  /// when adding a new module.
  @protected
  Future<void> registerFeatureModules() async {
    // 在此注册 Feature Modules，例如：
    // Register Feature Modules here, e.g.:
    // XxxModule.register(getIt);
  }
}
