import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 为任意 [BlocBase] 提供自动 [CancelToken] 生命周期管理的混入。
///
/// [State] 类型参数由被混入的类绑定，无需显式指定：
///
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState>
///     with BlocCancelTokenMixin { ... }
/// ```
///
/// ## 动机
///
///   **自动绑定 BLoC 生命周期**——页面销毁时 `close()` 自动取消所有 token。
///
///   **按 key 去重**——连续调用 `token('items')` 会先取消前一个进行中请求。
///
///   **用户主动取消**——`cancel('items')` 或 `cancelAll()` 让取消按钮
/// 能中断进行中的操作。
///
///   **操作间隔离**——不同的 key（如 'items'、'users'、'upload'）
/// 拥有独立的 token，互不干扰。
///
/// ## 用法
///
/// ```dart
/// class ItemBloc extends Bloc<ItemEvent, ItemState>
///     with BlocCancelTokenMixin {
///
///   Future<void> _loadItems(Emitter emit) async {
///     try {
///       final items = await _repository.fetchItems(
///         cancelToken: token('items'), // one line, fully managed
///       );
///       emit(...);
///     } on DioException catch (e) {
///       if (e.type == DioExceptionType.cancel) return; // silent
///       _toastService.showError('...');
///     }
///   }
///
///   // Handle cancel button from UI
///   void onCancelTapped() => cancelAll();
/// }
/// ```
///
/// ## 注意事项
///
///   Token 以 [String] key 存储。选择描述性的操作级 key
/// (e.g. 'fetchItems', 'uploadImage')。
///
///   仅当 key 对应的前一个请求已取消时，调用 [token(key)] 才会创建新 token。
///   如需并发同类型请求，请使用不同的 key。
///
///   默认 key 为 `'default'`——适用于单一操作类型的简单 BLoC。
///
///
/// A mixin that provides automatic [CancelToken] lifecycle management
/// for any [BlocBase].
///
/// The [State] type parameter is bound by the class it's mixed into
/// and does not need to be specified explicitly:
///
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState>
///     with BlocCancelTokenMixin { ... }
/// ```
///
/// ## Motivation
///
/// - **Auto-bind to BLoC lifecycle** — `close()` cancels all tokens
///   automatically when the page is disposed.
///
/// - **Deduplicate by key** — calling `token('items')` twice cancels
///   the first in-flight request before creating a new one.
///
/// - **User-initiated cancel** — `cancel('items')` or `cancelAll()`
///   allows cancel buttons to interrupt ongoing operations.
///
/// - **Isolated per operation** — different keys ('items', 'users',
///   'upload') have independent tokens and do not interfere.
///
/// ## Usage
///
/// ```dart
/// class ItemBloc extends Bloc<ItemEvent, ItemState>
///     with BlocCancelTokenMixin {
///
///   Future<void> _loadItems(Emitter emit) async {
///     try {
///       final items = await _repository.fetchItems(
///         cancelToken: token('items'), // one line, fully managed
///       );
///       emit(...);
///     } on DioException catch (e) {
///       if (e.type == DioExceptionType.cancel) return; // silent
///       _toastService.showError('...');
///     }
///   }
///
///   // Handle cancel button from UI
///   void onCancelTapped() => cancelAll();
/// }
/// ```
///
/// ## Notes
///
/// - Tokens are stored by [String] key. Pick descriptive,
///   operation-level keys (e.g. 'fetchItems', 'uploadImage').
///
/// - Calling [token(key)] creates a new token only if the key's
///   previous request has been cancelled. If you need concurrent
///   requests of the same type, use different keys.
///
/// - The default key is `'default'` — fine for simple BLoCs with
///   a single operation type.
mixin BlocCancelTokenMixin<State> on BlocBase<State> {
  /// 按操作标识符索引的命名取消令牌。
  ///
  /// Named cancel tokens, keyed by operation identifier.
  final Map<String, CancelToken> _tokens = <String, CancelToken>{};

  /// 返回给定操作 [key] 的 [CancelToken]。
  ///
  /// 如果 [key] 已存在 token，会**先取消**旧的（中止进行中的请求），
  /// 然后创建并存储新 token。
  ///
  /// 因此可以在每次请求处理中安全调用 [token]，无需担心旧请求泄漏。
  ///
  /// Returns a [CancelToken] for the given operation [key].
  ///
  /// If a token already exists for [key], it is **cancelled first**
  /// (the old in-flight request is aborted), then a fresh token is
  /// created and stored.
  ///
  /// This makes it safe to call [token] inside every request handler
  /// without worrying about leaking previous requests.
  CancelToken token([String key = 'default']) {
    _tokens[key]?.cancel();
    return _tokens[key] = CancelToken();
  }

  /// 取消 [key] 对应的进行中请求（如果有），然后从池中移除。
  ///
  /// 用于用户主动取消特定操作。
  ///
  /// Cancels the in-flight request for [key] (if any), then removes
  /// it from the pool.
  ///
  /// Use this for user-initiated cancellation of a specific operation.
  void cancel([String key = 'default']) {
    _tokens.remove(key)?.cancel();
  }

  /// 取消**所有**进行中的请求并清空 token 池。
  ///
  /// 在 [close] 中自动调用以绑定 BLoC 生命周期。
  /// 也可直接调用于"取消全部"按钮。
  ///
  /// Cancels **all** in-flight requests and clears the token pool.
  ///
  /// Called automatically in [close] to bind tokens to the BLoC
  /// lifecycle. Also callable directly for a "cancel all" button.
  void cancelAll() {
    for (final t in _tokens.values) {
      t.cancel();
    }
    _tokens.clear();
  }

  /// 覆写 [BlocBase.close]，在 BLoC 销毁前取消所有未完成的 token。
  ///
  /// 确保页面从导航栈弹出后不会收到陈旧的网络响应。
  ///
  /// Overrides [BlocBase.close] to cancel all pending tokens before
  /// the BLoC is destroyed.
  ///
  /// This ensures that pages never deal with stale network responses
  /// after being popped from the navigation stack.
  @override
  Future<void> close() {
    cancelAll();
    return super.close();
  }
}
