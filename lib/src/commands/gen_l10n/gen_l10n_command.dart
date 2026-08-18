import 'package:args/args.dart';
import 'package:fluzer/src/commands/adapter_command.dart';
import 'package:fluzer/src/commands/command_adapter.dart';
import 'package:fluzer/src/commands/gen_l10n/adapters/base_gen_l10n_adapter.dart';
import 'package:fluzer/src/commands/gen_l10n/adapters/gen_l10n_v1v2_adapter.dart';
import 'package:fluzer/src/commands/gen_l10n/gen_l10n_context.dart';
import 'package:fluzer/src/gen_l10n/toast_handle_patcher.dart';
import 'package:fluzer/src/process/process_runner.dart';
import 'package:fluzer/src/template/template_version_reader.dart';
import 'package:mason_logger/mason_logger.dart';

/// `gen-l10n` 命令：执行 Flutter 国际化代码生成，并自动生成
/// `L10nCode` 值对象、Toast 类型扩展与集中式 Toast 分发器。
///
/// 通过 [AdapterCommand] 统一收参/读版本/选适配器，再把整条流程委托给
/// 版本专属适配器（[GenL10nV1V2Adapter]）；能力边界外的版本由 [AdapterCommand]
/// 直接报错退出。
///
/// `gen-l10n` command: runs Flutter localization code generation and
/// auto-generates the L10nCode value object, toast-type extension and the
/// centralized toast dispatcher.
///
/// [AdapterCommand] unifies arg collecting / version reading / adapter
/// selection; the full flow is delegated to a version-specific adapter.
class GenL10nCommand extends AdapterCommand<GenL10nCommandContext> {
  /// 创建 GenL10nCommand 实例。
  ///
  /// [logger] / [translations] / [processRunner] / [versionCheckService] 由外部
  /// 必填注入（[Fluzer] 统一提供）；[flutterGenL10nFn] / [patcher] 可选注入
  /// （测试 stub / 非默认补丁策略）；[workingDirectory] 省略时回退到当前工作目录。
  ///
  /// Creates a GenL10nCommand instance.
  ///
  /// [logger] / [translations] / [processRunner] / [versionCheckService] are
  /// required (injected by [Fluzer]); [flutterGenL10nFn] / [patcher] are optional
  /// (test stub / non-default patch policy); [workingDirectory] defaults to cwd.
  GenL10nCommand({
    required super.logger,
    required super.translations,
    required this.processRunner,
    required super.versionCheckService,
    FlutterGenL10nRunner? flutterGenL10nFn,
    ToastHandlePatcher? patcher,
    super.workingDirectory,
  }) : _flutterGenL10n = flutterGenL10nFn,
       _patcher = patcher ?? const ToastHandlePatcher() {
    argParser
      ..addFlag(
        'skip-handle-patch',
        negatable: false,
        help: translations.genL10n.skipHandlePatchHelp,
      )
      ..addFlag(
        'force-handle-patch',
        negatable: false,
        help: translations.genL10n.forceHandlePatchHelp,
      );
  }

  final FlutterGenL10nRunner? _flutterGenL10n;

  /// 注入的进程执行器；省略时使用默认实现。
  ///
  /// Injected process runner; uses the default implementation when omitted.
  final ProcessRunner processRunner;

  final ToastHandlePatcher _patcher;

  @override
  String get name => 'gen-l10n';

  @override
  String get description => translations.genL10n.description;

  @override
  GenL10nCommandContext buildAdapterContext(
    ArgResults args,
    ProjectVersionInfo info,
  ) {
    final skipHandlePatch = args['skip-handle-patch'] as bool? ?? false;
    final forceHandlePatch = args['force-handle-patch'] as bool? ?? false;
    return GenL10nCommandContext(
      version: info.version,
      projectRoot: info.projectRoot,
      skipHandlePatch: skipHandlePatch,
      forceHandlePatch: forceHandlePatch,
    );
  }

  @override
  List<CommandAdapter<GenL10nCommandContext>> get adapters => [
    GenL10nV1V2Adapter(deps: _genL10nDeps),
  ];

  GenL10nAdapterDeps get _genL10nDeps => GenL10nAdapterDeps(
    logger: logger,
    translations: translations,
    processRunner: processRunner,
    patcher: _patcher,
    flutterGenL10nFn: _flutterGenL10n ?? _defaultFlutterGenL10n,
    workingDirectory: workingDirectory,
    versionCheckService: versionCheckService,
  );

  Future<int> _defaultFlutterGenL10n(String projectRoot) {
    return processRunner.run(
      'flutter',
      ['gen-l10n'],
      workingDirectory: projectRoot,
      showLive: logger.level == Level.verbose,
      runInShell: true,
    );
  }
}
