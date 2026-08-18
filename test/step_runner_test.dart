import 'package:fluzer/src/i18n/gen/strings.g.dart';
import 'package:fluzer/src/util/step_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';

/// 捕获 [Logger.info] 输出，用于断言 [StepRunner] 自动拼上的「步骤 i/N」前缀。
///
/// 测试环境下 [stdout.hasTerminal] 为 false，[runWithSpinner] 走非 spinner 分支
/// 直接调用 [Logger.info]，因此重写 [info] 即可截获步骤文案。
class _RecordingLogger extends Logger {
  final List<String> infos = [];

  @override
  void info(String? message, {LogStyle? style}) => infos.add(message ?? '');
}

void main() {
  group('StepRunner', () {
    late _RecordingLogger logger;
    late Translations translations;
    late StepRunner steps;
    late List<String> order;

    setUp(() {
      logger = _RecordingLogger();
      translations = Translations();
      steps = StepRunner(logger: logger, translations: translations);
      order = [];
    });

    test('按注册顺序串行执行，并自动拼本地化「步骤 i/N」前缀', () async {
      steps.add('A', () async => order.add('workA'));
      steps.add('B', () async => order.add('workB'));
      steps.add('C', () async => order.add('workC'));

      await steps.runAll();

      expect(order, ['workA', 'workB', 'workC']);
      expect(logger.infos, hasLength(3));
      expect(logger.infos[0], contains('步骤 1/3'));
      expect(logger.infos[1], contains('步骤 2/3'));
      expect(logger.infos[2], contains('步骤 3/3'));
    });

    test('work 抛异常即中断后续步骤并向上冒泡', () async {
      steps.add('A', () async => throw StateError('boom'));
      steps.add('B', () async => order.add('workB'));

      expect(() async => steps.runAll(), throwsA(isA<StateError>()));
      expect(order, isEmpty); // B 未执行
    });

    test('onDone 在 work 成功后调用，且位于 work 之后', () async {
      steps.add(
        'A',
        () async => order.add('workA'),
        onDone: () => order.add('doneA'),
      );
      steps.add(
        'B',
        () async => order.add('workB'),
        onDone: () => order.add('doneB'),
      );

      await steps.runAll();

      expect(order, ['workA', 'doneA', 'workB', 'doneB']);
    });

    test('enabled=false 跳过该步骤，且不计入 N（后续步骤编号前移）', () async {
      steps.add('A', () async => order.add('workA'));
      steps.add('B', () async => order.add('workB'), enabled: false);
      steps.add('C', () async => order.add('workC'));

      await steps.runAll();

      expect(order, ['workA', 'workC']); // B 被跳过
      expect(logger.infos, hasLength(2));
      expect(logger.infos[0], contains('步骤 1/2'));
      expect(logger.infos[1], contains('步骤 2/2')); // C 因 B 跳过而变为 2/2
    });
  });
}
