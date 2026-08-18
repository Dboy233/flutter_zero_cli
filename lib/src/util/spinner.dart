import 'dart:io';

import 'package:fluzer/src/i18n/gen/strings.g.dart';
import 'package:mason_logger/mason_logger.dart';

/// 在执行某一步骤期间显示一个旋转 spinner（表示「正在执行」），完成后将
/// spinner 替换为 ✓ 完成标记；异常时替换为 ✗ 失败标记并向上抛出。
///
/// 可见性完全由 [logger.level] 决定，无需再传入独立的策略对象：
/// - [Level.verbose]（`--log` 调试模式）：不显示 spinner，子进程输出已实时
///   透传、过程靠日志展示，故这里仅打印一行步骤日志后直接执行 [work]；
/// - 非交互终端（`stdout.hasTerminal` 为 false，如 CI / 重定向）：同样不显示
///   spinner，直接执行 [work]，避免噪声与任何光标操作；
/// - 其余（默认 info 级别 + 交互终端）：渲染 mason_logger 的 [Progress]
///   （单行 `\r` 重写，终端自行计算列宽与折行，CJK 全角 / ANSI 颜色码均不影响），
///   不依赖手算行数，故不会残留旧输出。
///
/// 注意：[work] 内部只能使用 [Logger.detail]（非 verbose 下被抑制）或
/// [Logger.err] / [Logger.warn]（走 stderr）；不要在 spinner 动画期间调用
/// [Logger.info] / [Logger.success]（走 stdout 且换行），否则会破坏 spinner
/// 所在行。需要向用户展示的总结性 [Logger.info] / [Logger.success] 应放到
/// [runWithSpinner] 调用结束之后。
///
/// Shows a spinning [Progress] while [work] runs; replaces it with a
/// completion / failure marker. Falls back to running [work] directly when
/// no spinner should be shown (debug mode or non-terminal).
Future<T> runWithSpinner<T>({
  required Logger logger,
  required Translations translations,
  required String message,
  required Future<T> Function() work,
}) async {
  // 调试模式（已有实时子进程输出）或非交互终端：直接执行，不渲染 spinner。
  if (logger.level == Level.verbose || !stdout.hasTerminal) {
    logger.info('\n$message');
    return work();
  }

  final progress = logger.progress(message);
  try {
    final result = await work();
    final label = message.trim().replaceFirst(RegExp(r'\.\.\.$'), '');
    progress.complete(translations.spinner.stepCompleted(label: label));
    return result;
  } on Object {
    final label = message.trim().replaceFirst(RegExp(r'\.\.\.$'), '');
    progress.fail(translations.spinner.stepFailed(label: label));
    rethrow;
  }
}
