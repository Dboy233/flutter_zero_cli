import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../config/project_config.dart';
import '../process/process_runner.dart';
import '../template/brick_loader.dart';
import '../template/brick_renderer.dart';
import '../template/feature_generator.dart';
import '../template/template_config.dart';
import '../template/template_source.dart';

/// build_runner 执行器签名。
///
/// Signature for the build_runner executor.
typedef BuildRunnerRunner = Future<int> Function(String projectRoot);

/// `new` 命令：在当前 flutter_zero 模板项目中生成功能模块。
///
/// `new` command: generates a feature module in the current flutter_zero
/// template project.
class NewCommand extends Command<int> {
  /// 创建 NewCommand 实例。
  ///
  /// [loader] 用于注入 Brick 加载器（测试可用本地临时目录）；
  /// [buildRunner] 用于注入 build_runner 执行器；
  /// 二者均省略时按环境变量自动解析 / 使用默认实现。
  ///
  /// Creates a NewCommand instance.
  ///
  /// [loader] injects a [BrickLoader] (tests use a temp local dir);
  /// [buildRunner] injects the build_runner executor;
  /// when omitted they resolve from env / use defaults.
  NewCommand({
    Logger? logger,
    BrickLoader? loader,
    BuildRunnerRunner? buildRunner,
  }) :        _logger = logger ?? Logger(),
       // ignore: prefer_initializing_formals
       _loader = loader,
       _buildRunner = buildRunner ?? _defaultBuildRunner {
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
  final BuildRunnerRunner _buildRunner;

  @override
  String get name => 'new';

  @override
  String get description => '新增功能模块 / Add a new feature module';

  @override
  Future<int> run() async {
    final featureName = argResults?.rest.firstOrNull;
    if (featureName == null) {
      _logger.err('错误：请指定功能名 / Error: please specify a feature name');
      printUsage();
      return 1;
    }

    try {
      final config = await ProjectConfig.load();

      // 版本门禁：校验当前 CLI 是否支持该项目的模板版本。
      // 环境变量覆盖（FLUZER_BRICKS_DIR / FLUZER_TEMPLATE_ZIP_URL）只影响下载
      // 来源，门禁始终执行；可用 --skip-version-check 绕过。
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

      final brickLoader = _loader ??
          await resolveBrickLoader(
            logger: _logger,
            pinnedVersion: config.version,
          );
      final generator = FeatureGenerator(
        config: config,
        renderer: BrickRenderer(brickLoader),
      );

      await generator.generate(featureName);

      _logger.success(
        '功能模块 $featureName 已创建并注册到 DI。\n'
        'Feature module $featureName has been created and registered in DI.',
      );

      final runBuildRunner = argResults!['build-runner'] as bool;
      if (runBuildRunner) {
        _logger.info('正在运行 build_runner... / Running build_runner...');
        final exitCode = await _buildRunner(config.projectRoot);
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

  static Future<int> _defaultBuildRunner(String projectRoot) {
    return ProcessRunner.run(
      'dart',
      ['run', 'build_runner', 'build'],
      workingDirectory: projectRoot,
    );
  }
}
