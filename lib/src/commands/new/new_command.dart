import 'package:args/args.dart';
import 'package:fluzer/src/commands/adapter_command.dart';
import 'package:fluzer/src/commands/command_adapter.dart';
import 'package:fluzer/src/commands/new/adapters/base_new_adapter.dart';
import 'package:fluzer/src/commands/new/adapters/new_v1v2_adapter.dart';
import 'package:fluzer/src/commands/new/new_context.dart';
import 'package:fluzer/src/process/process_runner.dart';
import 'package:fluzer/src/template/brick_loader.dart';
import 'package:fluzer/src/template/template_version_reader.dart';

/// `new` 命令：在当前 flutter_zero 模板项目中生成功能模块。
///
/// 通过 [AdapterCommand] 统一收参/读版本/选适配器，再把整条流程委托给
/// 版本专属适配器（[NewV1V2Adapter]）；能力边界外的版本由
/// [AdapterCommand] 直接报错退出。
///
/// `new` command: generates a feature module in the current flutter_zero
/// template project.
///
/// [AdapterCommand] unifies arg collecting / version reading / adapter
/// selection; the full flow is delegated to a version-specific adapter.
class NewCommand extends AdapterCommand<NewCommandContext> {
  /// 创建 NewCommand 实例。
  ///
  /// [logger] / [messages] / [processRunner] / [versionCheckService] 由外部
  /// 必填注入（[Fluzer] 统一提供）；[loader] 可选注入 Brick 加载器（测试用本地临时
  /// 目录，生产不传）；[workingDirectory] 指定项目根目录查找起点，省略时回退到
  /// 当前工作目录。
  ///
  /// Creates a NewCommand instance.
  ///
  /// [logger] / [messages] / [processRunner] / [versionCheckService] are
  /// required (injected by [Fluzer]); [loader] optionally injects a [BrickLoader]
  /// (tests use a temp local dir, production omits it); [workingDirectory] pins
  /// the project-root start dir, defaulting to cwd.
  NewCommand({
    required super.logger,
    required super.translations,
    required this.processRunner,
    required super.versionCheckService,
    this._loader,
    super.workingDirectory,
  });

  final BrickLoader? _loader;

  final ProcessRunner processRunner;

  @override
  String get name => 'new';

  @override
  String get description => translations.feature.description;

  @override
  NewCommandContext buildAdapterContext(
    ArgResults args,
    ProjectVersionInfo info,
  ) {
    final featureName = args.rest.firstOrNull;
    return NewCommandContext(
      version: info.version,
      projectRoot: info.projectRoot,
      featureName: featureName,
    );
  }

  @override
  List<CommandAdapter<NewCommandContext>> get adapters => [
    NewV1V2Adapter(deps: _newDeps),
  ];

  NewAdapterDeps get _newDeps => NewAdapterDeps(
    logger: logger,
    translations: translations,
    loader: _loader,
    processRunner: processRunner,
    workingDirectory: workingDirectory,
    versionCheckService: versionCheckService
  );
}
