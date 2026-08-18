// 命令级版本适配机制单测。
//
// 覆盖：
//  - [RangeSpec] 半开区间边界（下界含、上界不含、无上界）
//  - [AnySpec] 全部匹配（Null Object 兜底）
//  - [CommandAdapter.canHandle] 转发到规格
//  - [AdapterCommand.selectAdapter] 责任链算法（首命中认领 / 全不命中返回 null）
//  - [NewCommand] / [GenL10nCommand] 真实适配器链与版本区间接线
//
// Command-level version adaptation unit tests.
//
// Covers the spec boundary semantics, the chain-of-responsibility selection
// algorithm, and the real adapter wiring inside NewCommand / GenL10nCommand.

import 'package:args/args.dart';
import 'package:fluzer/src/commands/adapter_command.dart';
import 'package:fluzer/src/commands/command_adapter.dart';
import 'package:fluzer/src/commands/command_context.dart';
import 'package:fluzer/src/commands/gen_l10n/adapters/gen_l10n_v1v2_adapter.dart';
import 'package:fluzer/src/commands/gen_l10n/gen_l10n_command.dart';
import 'package:fluzer/src/commands/gen_l10n/gen_l10n_context.dart';
import 'package:fluzer/src/commands/new/adapters/new_v1v2_adapter.dart';
import 'package:fluzer/src/commands/new/new_command.dart';
import 'package:fluzer/src/commands/new/new_context.dart';
import 'package:fluzer/src/template/template_version_reader.dart';
import 'package:fluzer/src/commands/version/version_spec.dart';
import 'package:fluzer/src/i18n/gen/strings.g.dart';
import 'package:fluzer/src/process/process_runner.dart';
import 'package:fluzer/src/util/semantic_version.dart';
import 'package:fluzer/src/version/version_check.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';

/// 仅用于算法测试的轻量适配器（不做任何执行）。
///
/// Lightweight adapter used only for algorithm tests (no real execution).
class _FakeAdapter extends CommandAdapter<CommandContext> {
  _FakeAdapter({this.label = '', required super.spec});

  final String label;

  @override
  Future<int> run(CommandContext context) async => 0;
}

/// 仅用于算法测试的 [AdapterCommand] 子类：把适配器链与兜底外部注入。
///
/// Test-only [AdapterCommand] subclass that injects its adapter chain and
/// fallback, so we can exercise [AdapterCommand.selectAdapter] in isolation.
class _FakeCommand extends AdapterCommand<CommandContext> {
  _FakeCommand({
    required super.logger,
    required super.translations,
    required super.versionCheckService,
    required this.adaptersOverride,
  });

  final List<CommandAdapter<CommandContext>> adaptersOverride;

  @override
  CommandContext buildAdapterContext(
    ArgResults args,
    ProjectVersionInfo info,
  ) => CommandContext(version: info.version, projectRoot: info.projectRoot);

  @override
  String get name => 'fake';

  @override
  String get description => 'test-only command';

  @override
  List<CommandAdapter<CommandContext>> get adapters => adaptersOverride;
}

CommandContext _ctx(SemanticVersion v) =>
    CommandContext(version: v, projectRoot: '/tmp');

NewCommandContext _newCtx(SemanticVersion v) => NewCommandContext(
  version: v,
  projectRoot: '/tmp',
  featureName: 'demo',
);

GenL10nCommandContext _genCtx(SemanticVersion v) =>
    GenL10nCommandContext(version: v, projectRoot: '/tmp');

void main() {
  group('RangeSpec 半开区间边界', () {
    const lower = SemanticVersion(1, 0, 0);
    const upper = SemanticVersion(2, 0, 0);
    const spec = RangeSpec(lower, upper);

    test('低于下界 → false', () {
      expect(spec.isSatisfiedBy(SemanticVersion(0, 9, 9)), isFalse);
    });
    test('等于下界 → true（含）', () {
      expect(spec.isSatisfiedBy(SemanticVersion(1, 0, 0)), isTrue);
    });
    test('区间内部 → true', () {
      expect(spec.isSatisfiedBy(SemanticVersion(1, 5, 3)), isTrue);
    });
    test('等于上界 → false（不含）', () {
      expect(spec.isSatisfiedBy(SemanticVersion(2, 0, 0)), isFalse);
    });
    test('高于上界 → false', () {
      expect(spec.isSatisfiedBy(SemanticVersion(2, 0, 1)), isFalse);
    });
  });

  group('RangeSpec 无上界', () {
    const spec = RangeSpec(SemanticVersion(2, 0, 0));

    test('等于下界 → true', () {
      expect(spec.isSatisfiedBy(SemanticVersion(2, 0, 0)), isTrue);
    });
    test('远高于下界 → true', () {
      expect(spec.isSatisfiedBy(SemanticVersion(99, 0, 0)), isTrue);
    });
    test('低于下界 → false', () {
      expect(spec.isSatisfiedBy(SemanticVersion(1, 9, 9)), isFalse);
    });
  });

  group('AnySpec 全部匹配（Null Object 兜底）', () {
    const spec = AnySpec();

    test('任意版本 → true', () {
      expect(spec.isSatisfiedBy(SemanticVersion(0, 0, 0)), isTrue);
      expect(spec.isSatisfiedBy(SemanticVersion(1, 2, 3)), isTrue);
      expect(spec.isSatisfiedBy(SemanticVersion(9, 9, 9)), isTrue);
    });
  });

  group('CommandAdapter.canHandle 转发到规格', () {
    test('命中区间 → true，越界 → false', () {
      final adapter = _FakeAdapter(
        spec: const RangeSpec(
          SemanticVersion(1, 0, 0),
          SemanticVersion(2, 0, 0),
        ),
      );
      expect(adapter.canHandle(SemanticVersion(1, 5, 0)), isTrue);
      expect(adapter.canHandle(SemanticVersion(2, 0, 0)), isFalse);
    });
    test('AnySpec 适配器任意版本认领', () {
      final adapter = _FakeAdapter(spec: const AnySpec());
      expect(adapter.canHandle(SemanticVersion(3, 1, 4)), isTrue);
    });
  });

  group('BaseCommand.selectAdapter 责任链算法', () {
    late _FakeCommand cmd;
    late _FakeAdapter a;
    late _FakeAdapter b;

    setUp(() {
      a = _FakeAdapter(
        spec: const RangeSpec(
          SemanticVersion(1, 0, 0),
          SemanticVersion(2, 0, 0),
        ),
        label: 'a',
      );
      b = _FakeAdapter(
        spec: const RangeSpec(
          SemanticVersion(2, 0, 0),
          SemanticVersion(3, 0, 0),
        ),
        label: 'b',
      );
      cmd = _FakeCommand(
        logger: Logger(),
        translations: AppLocale.zh.buildSync(),
        versionCheckService: VersionCheckService(
          logger: Logger(),
          messages: AppLocale.zh.buildSync(),
        ),
        adaptersOverride: [a, b],
      );
    });

    test('命中第一个匹配的适配器（按链顺序）', () {
      expect(cmd.selectAdapter(_ctx(SemanticVersion(1, 5, 0))), same(a));
      expect(cmd.selectAdapter(_ctx(SemanticVersion(2, 5, 0))), same(b));
    });

    test('区间重叠时认领链首', () {
      final overlapping = _FakeAdapter(spec: const AnySpec(), label: 'ov');
      final overlapped = _FakeCommand(
        logger: Logger(),
        translations: AppLocale.zh.buildSync(),
        versionCheckService: VersionCheckService(
          logger: Logger(),
          messages: AppLocale.zh.buildSync(),
        ),
        adaptersOverride: [overlapping, a, b],
      );
      expect(
        overlapped.selectAdapter(_ctx(SemanticVersion(1, 5, 0))),
        same(overlapping),
      );
    });

    test('全不命中 → selectAdapter 返回 null', () {
      expect(cmd.selectAdapter(_ctx(SemanticVersion(9, 9, 9))), isNull);
    });

    test('全不命中 → execute 返回 1（报错退出）', () async {
      expect(await cmd.execute(_ctx(SemanticVersion(9, 9, 9))), 1);
    });
  });

  group('NewCommand 版本路由（真实适配器链）', () {
    final cmd = NewCommand(
      logger: Logger(),
      translations: AppLocale.zh.buildSync(),
      processRunner: RealProcessRunner(),
      versionCheckService: VersionCheckService(
        logger: Logger(),
        messages: AppLocale.zh.buildSync(),
      ),
    );

    test('1.0.0 → NewV1V2Adapter', () {
      expect(
        cmd.selectAdapter(_newCtx(SemanticVersion(1, 0, 0))),
        isA<NewV1V2Adapter>(),
      );
    });
    test('1.5.0 → NewV1V2Adapter', () {
      expect(
        cmd.selectAdapter(_newCtx(SemanticVersion(1, 5, 0))),
        isA<NewV1V2Adapter>(),
      );
    });
    test('1.99.0 → NewV1V2Adapter', () {
      expect(
        cmd.selectAdapter(_newCtx(SemanticVersion(1, 99, 0))),
        isA<NewV1V2Adapter>(),
      );
    });
    test('2.0.0 → NewV1V2Adapter（合并适配器跨版本覆盖）', () {
      expect(
        cmd.selectAdapter(_newCtx(SemanticVersion(2, 0, 0))),
        isA<NewV1V2Adapter>(),
      );
    });
    test('3.0.0（无上界）→ 仍命中 NewV1V2Adapter', () {
      expect(
        cmd.selectAdapter(_newCtx(SemanticVersion(3, 0, 0))),
        isA<NewV1V2Adapter>(),
      );
    });
    test('0.9.0（低于区间）→ selectAdapter 返回 null', () {
      expect(cmd.selectAdapter(_newCtx(SemanticVersion(0, 9, 0))), isNull);
    });
    test('maxSupportedVersion 无界适配器返回 (0,0,0)', () {
      expect(cmd.maxSupportedVersion, SemanticVersion(0, 0, 0));
    });
  });

  group('GenL10nCommand 版本路由（真实适配器链）', () {
    final cmd = GenL10nCommand(
      logger: Logger(),
      translations: AppLocale.zh.buildSync(),
      processRunner: RealProcessRunner(),
      versionCheckService: VersionCheckService(
        logger: Logger(),
        messages: AppLocale.zh.buildSync(),
      ),
    );

    test('1.0.0 → GenL10nV1V2Adapter', () {
      expect(
        cmd.selectAdapter(_genCtx(SemanticVersion(1, 0, 0))),
        isA<GenL10nV1V2Adapter>(),
      );
    });
    test('1.1.0 → GenL10nV1V2Adapter', () {
      expect(
        cmd.selectAdapter(_genCtx(SemanticVersion(1, 1, 0))),
        isA<GenL10nV1V2Adapter>(),
      );
    });
    test('2.0.0 → GenL10nV1V2Adapter（跨版本单适配器）', () {
      expect(
        cmd.selectAdapter(_genCtx(SemanticVersion(2, 0, 0))),
        isA<GenL10nV1V2Adapter>(),
      );
    });
    test('2.99.0 → GenL10nV1V2Adapter', () {
      expect(
        cmd.selectAdapter(_genCtx(SemanticVersion(2, 99, 0))),
        isA<GenL10nV1V2Adapter>(),
      );
    });
    test('3.0.0（无上界）→ 仍命中 GenL10nV1V2Adapter', () {
      expect(
        cmd.selectAdapter(_genCtx(SemanticVersion(3, 0, 0))),
        isA<GenL10nV1V2Adapter>(),
      );
    });
    test('99.0.0（无上界）→ 仍命中 GenL10nV1V2Adapter（适配所有未来版本）', () {
      expect(
        cmd.selectAdapter(_genCtx(SemanticVersion(99, 0, 0))),
        isA<GenL10nV1V2Adapter>(),
      );
    });
    test('0.5.0（低于下界）→ selectAdapter 返回 null', () {
      expect(cmd.selectAdapter(_genCtx(SemanticVersion(0, 5, 0))), isNull);
    });
    test('maxSupportedVersion 无界适配器返回 (0,0,0)', () {
      expect(cmd.maxSupportedVersion, SemanticVersion(0, 0, 0));
    });
  });
}
