import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../config/project_config.dart';
import '../config/template_config.dart';
import '../logging/spinner.dart';
import '../process/process_runner.dart';
import '../template/brick_loader.dart';
import '../template/brick_renderer.dart';
import '../template/feature_generator.dart';
import '../template/template_source.dart';
import '../version/version_check.dart';
import '../version/version_check_mixin.dart';

/// build_runner 执行器签名。
///
/// Signature for the build_runner executor.
typedef BuildRunnerRunner = Future<int> Function(String projectRoot);

/// `new` 命令：在当前 flutter_zero 模板项目中生成功能模块。
///
/// `new` command: generates a feature module in the current flutter_zero
/// template project.
class NewCommand extends Command<int> with VersionCheckMixin {
  /// 创建 NewCommand 实例。
  ///
  /// [loader] 用于注入 Brick 加载器（测试可用本地临时目录）；
  /// [buildRunner] 用于注入 build_runner 执行器；
  /// [workingDirectory] 指定项目根目录（向上查找 `flutter_zero_config.yaml` 的起点），
  /// 省略时回退到当前工作目录；测试可传入临时项目目录以避免依赖全局 cwd。
  /// 二者均省略时按环境变量自动解析 / 使用默认实现。
  ///
  /// Creates a NewCommand instance.
  ///
  /// [loader] injects a [BrickLoader] (tests use a temp local dir);
  /// [buildRunner] injects the build_runner executor;
  /// [workingDirectory] pins the project root (start dir for walking up to
  /// `flutter_zero_config.yaml`); defaults to the current directory. Tests pass
  /// a temp project dir so they never mutate the global cwd.
  NewCommand({
    Logger? logger,
    BrickLoader? loader,
    BuildRunnerRunner? buildRunner,
    this.workingDirectory,
    VersionCheckService? versionCheckService,
  }) : _logger = logger ?? Logger(),
       // ignore: prefer_initializing_formals
       _loader = loader,
       _versionCheckService = versionCheckService ?? VersionCheckService(logger: logger ?? Logger()) {
    _buildRunner = buildRunner ?? _defaultBuildRunner;
    argParser
      ..addFlag(
        'build-runner',
        help:
            '生成后是否运行 build_runner / '
            'Whether to run build_runner after generation',
        defaultsTo: true,
        negatable: true,
      )
      ..addFlag(
        'skip-version-check',
        negatable: false,
        help:
            '跳过项目模板版本与 CLI 版本兼容门禁 / '
            'Skip the project-template/CLI version compatibility gate',
      );
  }

  final Logger _logger;
  final BrickLoader? _loader;

  /// 注入的版本检查服务（测试用）；省略时创建默认实例。
  ///
  /// Injected version-check service (for tests); creates a default instance
  /// when omitted.
  final VersionCheckService _versionCheckService;

  @override
  Logger get logger => _logger;

  @override
  VersionCheckService get versionCheckService => _versionCheckService;

  /// 项目根目录（向上查找 `flutter_zero_config.yaml` 的起点）。
  /// 省略时回退到当前工作目录。测试注入临时目录以避免依赖全局 cwd。
  ///
  /// Project root (start dir for walking up to `flutter_zero_config.yaml`).
  /// Defaults to the current directory; tests inject a temp dir to avoid
  /// mutating the global cwd.
  final Directory? workingDirectory;
  late final BuildRunnerRunner _buildRunner;

  @override
  String get name => 'new';

  @override
  String get description => '新增功能模块 / Add a new feature module';

  @override
  Future<int> run() async {
    // 启动版本检查提示（缓存命中瞬时提示，缓存未命中以 spinner 包裹网络等待）；
    // 无更新 / 网络异常静默降级，不阻断主流程。
    await ensureUpdateNotified();

    final featureName = argResults?.rest.firstOrNull;
    if (featureName == null) {
      _logger.err('错误：请指定功能名 / Error: please specify a feature name');
      printUsage();
      return 1;
    }

    late ProjectConfig config;
    late BrickLoader brickLoader;

    try {
      // 每一步骤都用 runWithSpinner 给出「正在执行」的旋转反馈；
      // --log（verbose）模式下由 logger.level 控制不显示 spinner，过程靠日志展示。
      // work 内部只用 detail（非 verbose 下被抑制），避免破坏 spinner 行。
      await runWithSpinner(
        logger: _logger,
        message: '步骤 1/4：加载项目配置与版本门禁 ...',
        work: () async {
          config = await ProjectConfig.load(start: workingDirectory);
          _logger.detail('  项目根目录: ${config.projectRoot}');
          _logger.detail(
            '  项目模板版本: ${config.version}，要求 CLI >= ${config.minCliVersion}',
          );

          // 版本门禁：校验当前 CLI 是否支持该项目的模板版本。
          // 环境变量覆盖只影响下载来源，门禁始终执行；可用 --skip-version-check 绕过。
          if (!(argResults!['skip-version-check'] as bool) &&
              !config.isCliCompatible(cliVersion)) {
            throw CliException(
              '当前 CLI 版本 $cliVersion 过低，项目模板 ${config.version} '
              '需要 CLI >= ${config.minCliVersion}。请升级 fluzer 后重试，'
              '或确认项目配置。\n'
              'Current CLI version $cliVersion is too low; project template '
              '${config.version} requires CLI >= ${config.minCliVersion}. '
              'Please upgrade fluzer or check the project config.',
            );
          }
        },
      );

      await runWithSpinner(
        logger: _logger,
        message: '步骤 2/4：解析模板加载器（本地或远程下载）...',
        work: () async {
          _logger.detail('  按项目模板版本 ${config.version} 钉死下载源');
          brickLoader = _loader ??
              await TemplateSourceResolver(logger: _logger)
                  .resolve(pinnedVersion: config.version);
        },
      );

      await runWithSpinner(
        logger: _logger,
        message: '步骤 3/4：生成功能模块 $featureName ...',
        work: () async {
          final generator = FeatureGenerator(
            config: config,
            renderer: BrickRenderer(brickLoader),
          );
          await generator.generate(featureName);
          _logger.detail('  已生成功能模块 $featureName');
        },
      );

      _logger.success(
        '功能模块 $featureName 已创建并注册到 DI。\n'
        'Feature module $featureName has been created and registered in DI.',
      );

      final runBuildRunner = argResults!['build-runner'] as bool;
      if (runBuildRunner) {
        final exitCode = await runWithSpinner(
          logger: _logger,
          message: '步骤 4/4：运行 build_runner ...',
          work: () => _buildRunner(config.projectRoot),
        );
        if (exitCode != 0) {
          _logger.err('build_runner 执行失败。\nbuild_runner failed.');
          return exitCode;
        }
        _logger.success('build_runner 执行完成。\nbuild_runner completed.');
      } else {
        _logger.info(
          '跳过 build_runner，可手动运行：\n'
          'Skipped build_runner; run it manually with:\n'
          '  dart run build_runner build',
        );
      }

      return 0;
    } on CliException catch (e) {
      _logger.err(e.message);
      return 1;
    } on Object catch (e) {
      _logger.err('生成失败 / Generation failed: $e');
      return 1;
    }
  }

  Future<int> _defaultBuildRunner(String projectRoot) {
    return ProcessRunner.run(
      'dart',
      ['run', 'build_runner', 'build'],
      workingDirectory: projectRoot,
      showLive: _logger.level == Level.verbose,
    );
  }
}
