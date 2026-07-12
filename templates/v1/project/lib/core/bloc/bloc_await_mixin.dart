import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// 为任意 [Bloc] 提供基于 Completer 的通用操作等待能力。
///
/// 解决 MVI 中 `add(Event)` 是 fire-and-forget、UI 无法直接 `await` 的问题。
/// 通过 `runAwait()` 在发送事件前注册 Completer，事件处理结束时调用
/// `completeAwait()` 完成等待。
///
/// 用法：
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState>
///     with BlocAwaitMixin<MyEvent, MyState> {
///   Future<void> refresh() => runAwait(
///         event: const MyEvent.refresh(),
///         key: 'refresh',
///       );
///
///   Future<void> _onRefresh(MyRefresh event, Emitter<MyState> emit) async {
///     try {
///       emit(state.copyWith(isRefreshing: true));
///       await _repository.fetchData();
///     } finally {
///       emit(state.copyWith(isRefreshing: false));
///       completeAwait('refresh');
///     }
///   }
/// }
/// ```
///
/// 页面层：
/// ```dart
/// RefreshIndicator(
///   onRefresh: () => context.read<MyBloc>().refresh(),
///   child: ListView.builder(...),
/// )
/// ```
///
///
/// Provides generic Completer-based operation awaiting for any [Bloc].
///
/// Solves the problem that `add(Event)` is fire-and-forget in MVI, so the UI
/// cannot directly `await` it. `runAwait()` registers a Completer before the
/// event is dispatched; the event handler calls `completeAwait()` when done.
///
/// Usage:
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState>
///     with BlocAwaitMixin<MyEvent, MyState> {
///   Future<void> refresh() => runAwait(
///         event: const MyEvent.refresh(),
///         key: 'refresh',
///       );
///
///   Future<void> _onRefresh(MyRefresh event, Emitter<MyState> emit) async {
///     try {
///       emit(state.copyWith(isRefreshing: true));
///       await _repository.fetchData();
///     } finally {
///       emit(state.copyWith(isRefreshing: false));
///       completeAwait('refresh');
///     }
///   }
/// }
/// ```
///
/// In the page:
/// ```dart
/// RefreshIndicator(
///   onRefresh: () => context.read<MyBloc>().refresh(),
///   child: ListView.builder(...),
/// )
/// ```
mixin BlocAwaitMixin<Event, State> on Bloc<Event, State> {
  final Map<String, List<Completer<void>>> _awaitCompleters = {};

  /// 触发 [event] 并返回一个 Future，无论事件处理成功、失败或被跳过都会完成。
  ///
  /// [key] 用于标识同一类操作，便于 [completeAwait] 批量完成等待者。
  /// 默认 30 秒超时，防止事件处理异常或 BLoC 关闭时永久挂起。
  ///
  /// Dispatches [event] and returns a Future that completes regardless of
  /// whether the event handler succeeds, fails, or returns early.
  ///
  /// [key] identifies the operation type so [completeAwait] can complete all
  /// pending waiters. Defaults to a 30 second timeout to prevent hangs if the
  /// event handler throws or the BLoC is closed.
  Future<void> runAwait({
    required Event event,
    required String key,
    Duration timeout = const Duration(seconds: 30),
  }) {
    final completer = Completer<void>();
    _awaitCompleters.putIfAbsent(key, () => []).add(completer);
    add(event);
    return completer.future.timeout(timeout);
  }

  /// 完成所有正在等待 [key] 操作的 Future。
  ///
  /// 应在事件处理的 `finally` 中调用，确保即使被跳过也能结束等待。
  ///
  /// Completes all Futures waiting for the operation identified by [key].
  ///
  /// Should be called in the event handler's `finally` block so that early
  /// returns (e.g. `hasReachedMax`) also unblock waiters.
  void completeAwait(String key) {
    final completers = _awaitCompleters[key];
    if (completers != null) {
      for (final completer in completers) {
        if (!completer.isCompleted) completer.complete();
      }
      completers.clear();
    }
  }

  /// BLoC 关闭时清理未完成的 Completer，避免内存泄漏和永久挂起。
  ///
  /// Cleans up pending completers when the BLoC is closed to prevent memory
  /// leaks and permanent hangs.
  @override
  Future<void> close() {
    for (final entry in _awaitCompleters.entries) {
      for (final completer in entry.value) {
        if (!completer.isCompleted) {
          completer.completeError(
            StateError(
              'BLoC closed before operation ${entry.key} completed',
            ),
          );
        }
      }
    }
    _awaitCompleters.clear();
    return super.close();
  }
}
