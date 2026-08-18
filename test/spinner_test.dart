// SpinnerRunner 单元测试 / Unit tests for [SpinnerRunner].
//
// 验证：可见性完全由 [Logger.level] 驱动（不再依赖独立的策略对象）：
// - verbose（--log）：直接执行 work 并打印步骤日志，不渲染 spinner；
// - 非交互终端（测试环境无 TTY）：同样直接执行 work，安全降级；
// - work 抛异常时向上传播，不吞掉错误。

import 'package:fluzer/src/i18n/gen/strings.g.dart';
import 'package:fluzer/src/util/spinner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';

void main() {
  group('SpinnerRunner.run', () {
    test('verbose（--log）时直接执行 work 并返回结果，不依赖 spinner', () async {
      var called = false;
      final result = await SpinnerRunner(
        logger: Logger(level: Level.verbose),
        translations: AppLocale.zh.buildSync(),
      ).run(
        message: '步骤 X ...',
        work: () async {
          called = true;
          return 42;
        },
      );
      expect(called, isTrue);
      expect(result, 42);
    });

    test('非交互终端（测试环境无 TTY）下仍直接执行 work，安全降级', () async {
      // 验证 SpinnerRunner 在 stdout.hasTerminal 为 false 时不依赖终端、
      // 直接执行 work 并返回其结果（CI / 重定向场景的回归保护）。
      var called = false;
      final result = await SpinnerRunner(
        logger: Logger(level: Level.info),
        translations: AppLocale.zh.buildSync(),
      ).run(
        message: '步骤 X ...',
        work: () async {
          called = true;
          return 'ok';
        },
      );
      expect(called, isTrue);
      expect(result, 'ok');
    });

    test('work 抛异常时向上传播（不吞掉错误）', () async {
      expect(
        () => SpinnerRunner(
          logger: Logger(level: Level.verbose),
          translations: AppLocale.zh.buildSync(),
        ).run(
          message: '步骤 X ...',
          work: () async => throw const FormatException('boom'),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
