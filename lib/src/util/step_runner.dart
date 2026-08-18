import 'package:mason_logger/mason_logger.dart';

import '../i18n/gen/strings.g.dart';
import 'spinner.dart';

/// 一组有序步骤的统一执行器。
///
/// 把原本「每步一个 `await` 包裹的 spinner」的样板收敛为「先注册、最后只
/// `await` 一次 [runAll]」。每个命令只构造一个实例（持有固定的 [logger] /
/// [translations]），之后只用 [add] 注册步骤，步骤编号自动按「注册的（启用的）
/// 步骤总数」生成本地化的「步骤 i/N」前缀，无需调用方手动维护计数。
///
/// 步骤按注册顺序**串行**执行；任一步骤 [work] 抛异常即中断并向上冒泡，沿用
/// [SpinnerRunner] 的失败标记与异常透传语义。编号前缀走 [translations]，
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
  /// - [work] 步骤逻辑，返回 [Future<T>]；其产出值会在成功后交给 [onDone]，
  ///   从而省去在命令级声明「仅为本步总结日志而存在」的局部变量。需要判断
  ///   子命令退出码时，在内部判断后抛异常即可（异常会中断后续步骤并向上冒泡）。
  /// - [onDone] 步骤 [work] 成功完成后回调，入参为 [work] 的返回值（用于步骤间
  ///   总结日志；在 spinner 收尾后执行，不会破坏动画行）。不计入编号、不影响
  ///   执行顺序；[work] 抛异常时不会被调用。
  /// - [enabled] 是否启用该步骤（默认 `true`）。用于条件步骤（如 build_runner），
  ///   外部按开关传入；为 `false` 时整个条目（含 [onDone]）被跳过，也不计入 N。
  void add<T>(
    String message,
    Future<T> Function() work, {
    void Function(T result)? onDone,
    bool enabled = true,
  }) {
    if (!enabled) return;
    _entries.add(
      _StepEntry(
        message: message,
        // 闭包内消费 [work] 的返回值并交给 [onDone]，无需类型擦除，
        // [void] 步骤（T = void）天然兼容。
        run: () async {
          final result = await work();
          onDone?.call(result);
        },
      ),
    );
  }

  /// 按注册顺序统一执行全部启用的步骤，任一步骤失败即中断并抛异常。
  Future<void> runAll() async {
    final total = _entries.length;
    for (var i = 0; i < _entries.length; i++) {
      final entry = _entries[i];
      await SpinnerRunner(logger: logger, translations: translations).run(
        message:
            '${translations.spinner.stepLabel(index: i + 1, total: total)} '
            '${entry.message}',
        work: entry.run,
      );
    }
  }
}

class _StepEntry {
  const _StepEntry({required this.message, required this.run});

  final String message;
  final Future<void> Function() run;
}
