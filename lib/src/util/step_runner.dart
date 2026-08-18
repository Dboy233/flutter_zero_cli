import 'package:mason_logger/mason_logger.dart';

import '../i18n/gen/strings.g.dart';
import 'spinner.dart';

/// 一组有序步骤的统一执行器。
///
/// 把原本「每步一个 `await runWithSpinner`」的样板收敛为「先注册、最后只
/// `await` 一次 [runAll]」。每个命令只构造一个实例（持有固定的 [logger] /
/// [translations]），之后只用 [add] 注册步骤，步骤编号自动按「注册的（启用的）
/// 步骤总数」生成本地化的「步骤 i/N」前缀，无需调用方手动维护计数。
///
/// 步骤按注册顺序**串行**执行；任一步骤 [work] 抛异常即中断并向上冒泡，沿用
/// [runWithSpinner] 的失败标记与异常透传语义。编号前缀走 [translations]，
/// 跟随当前语言环境。
class StepRunner {
  /// 创建步骤执行器。
  ///
  /// [logger] / [translations] 为命令级固定注入，所有步骤共用。
  StepRunner({required this.logger, required this.translations});

  final Logger logger;
  final Translations translations;

  final List<_StepEntry> _entries = [];

  /// 注册一个步骤。
  ///
  /// - [message] 步骤描述，[runAll] 时会自动拼上本地化的「步骤 i/N」前缀。
  /// - [work] 步骤逻辑（返回 [Future<void>]）；需要判断子命令退出码时，在
  ///   内部判断后抛异常即可（异常会中断后续步骤并向上冒泡）。
  /// - [onDone] 步骤 [work] 成功完成后回调（用于步骤间总结日志，可依赖 [work]
  ///   计算出的结果）。不计入编号、不影响执行顺序。
  /// - [enabled] 是否启用该步骤（默认 `true`）。用于条件步骤（如 build_runner），
  ///   外部按开关传入；为 `false` 时整个条目（含 [onDone]）被跳过，也不计入 N。
  void add(
    String message,
    Future<void> Function() work, {
    void Function()? onDone,
    bool enabled = true,
  }) {
    if (enabled) {
      _entries.add(_StepEntry(message: message, work: work, onDone: onDone));
    }
  }

  /// 按注册顺序统一执行全部启用的步骤，任一步骤失败即中断并抛异常。
  Future<void> runAll() async {
    final total = _entries.length;
    for (var i = 0; i < _entries.length; i++) {
      final entry = _entries[i];
      await runWithSpinner(
        logger: logger,
        translations: translations,
        message:
            '${translations.spinner.stepLabel(index: i + 1, total: total)} '
            '${entry.message}',
        work: entry.work,
      );
      entry.onDone?.call();
    }
  }
}

class _StepEntry {
  const _StepEntry({
    required this.message,
    required this.work,
    this.onDone,
  });

  final String message;
  final Future<void> Function() work;
  final void Function()? onDone;
}
