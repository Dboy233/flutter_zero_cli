import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fluzer/src/i18n/gen/strings.g.dart';
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
typedef BuildRunnerRunner =
    Future<int> Function(String projectRoot, {String? buildFilter});

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
    ProcessRunner? processRunner,
    Translations? messages,
  }) : _logger = logger ?? Logger(),
       // ignore: prefer_initializing_formals
       _loader = loader,
       _messages = messages ?? AppLocale.zh.buildSync(),
       _versionCheckService =
           versionCheckService ??
           VersionCheckService(logger: logger ?? Logger()),
       _processRunner = processRunner ?? ProcessRunner() {
    _buildRunner = buildRunner ?? _defaultBuildRunner;
    argParser
      ..addFlag(
        'build-runner',
        help: _messages.feature.buildRunnerHelp,
        defaultsTo: true,
        negatable: true,
      )
      ..addFlag(
        'skip-version-check',
        negatable: false,
        help: _messages.feature.skipVersionCheckHelp,
      );
  }

  final Logger _logger;
  final BrickLoader? _loader;

  /// 本地化消息（类型安全访问器）。
  ///
  /// Localized messages (type-safe accessors).
  final Translations _messages;

  /// 注入的版本检查服务（测试用）；省略时创建默认实例。
  ///
  /// Injected version-check service (for tests); creates a default instance
  /// when omitted.
  final VersionCheckService _versionCheckService;

  final ProcessRunner _processRunner;

  @override
  Logger get logger => _logger;

  @override
  Translations get messages => _messages;

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
  String get description => _messages.feature.description;

  @override
  Future<int> run() async {
    // 启动版本检查提示（缓存命中瞬时提示，缓存未命中以 spinner 包裹网络等待）；
    // 无更新 / 网络异常静默降级，不阻断主流程。
    await ensureUpdateNotified();

    final featureName = argResults?.rest.firstOrNull;
    if (featureName == null) {
      _logger.err(_messages.feature.nameRequired);
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
        messages: _messages,
        message: _messages.feature.step1Load,
        work: () async {
          config = await ProjectConfig.load(start: workingDirectory);
          _logger.detail(
            _messages.feature.detailProjectRoot(path: config.projectRoot),
          );
          _logger.detail(
            _messages.feature.versionGateDetail(
              version: config.version,
              minCliVersion: config.minCliVersion,
            ),
          );

          // 版本门禁：校验当前 CLI 是否支持该项目的模板版本。
          // 环境变量覆盖只影响下载来源，门禁始终执行；可用 --skip-version-check 绕过。
          if (!(argResults!['skip-version-check'] as bool) &&
              !config.isCliCompatible(cliVersion)) {
            throw CliException(
              _messages.version.gateTooLow(
                cliVersion: cliVersion,
                version: config.version,
                minCliVersion: config.minCliVersion,
              ),
            );
          }
        },
      );

      await runWithSpinner(
        logger: _logger,
        messages: _messages,
        message: _messages.feature.step2Template,
        work: () async {
          _logger.detail(
            _messages.feature.detailPinnedVersion(version: config.version),
          );
          brickLoader =
              _loader ??
              await TemplateSourceResolver(
                logger: _logger,
                messages: _messages,
              ).resolve(pinnedVersion: config.version);
        },
      );

      await runWithSpinner(
        logger: _logger,
        messages: _messages,
        message: _messages.feature.step3Generate(feature: featureName),
        work: () async {
          final generator = FeatureGenerator(
            config: config,
            renderer: BrickRenderer(brickLoader),
            messages: _messages,
          );
          await generator.generate(featureName);
          _logger.detail(
            _messages.feature.detailGenerated(feature: featureName),
          );
        },
      );

      _logger.success(
        _messages.feature.successCreated(feature: featureName),
      );

      final runBuildRunner = argResults!['build-runner'] as bool;
      if (runBuildRunner) {
        final exitCode = await runWithSpinner(
          logger: _logger,
          messages: _messages,
          message: _messages.feature.step4BuildRunner,
          work: () => _buildRunner(
            config.projectRoot,
            buildFilter: 'lib/features/$featureName/**.dart',
          ),
        );
        if (exitCode != 0) {
          _logger.err(_messages.feature.buildRunnerFailed);
          return exitCode;
        }
        _logger.success(_messages.feature.buildRunnerCompleted);
      } else {
        _logger.info(_messages.feature.skipBuildRunner);
      }

      return 0;
    } on CliException catch (e) {
      _logger.err(e.message);
      return 1;
    } on Object catch (e) {
      _logger.err(_messages.feature.generationFailed(error: e));
      return 1;
    }
  }

  Future<int> _defaultBuildRunner(
    String projectRoot, {
    String? buildFilter,
  }) async {
    final args = ['run', 'build_runner', 'build'];
    if (buildFilter != null) {
      args.addAll(['--build-filter', buildFilter]);
    }
    return _processRunner.run(
      'dart',
      args,
      workingDirectory: projectRoot,
      showLive: _logger.level == Level.verbose,
    );
  }
}
