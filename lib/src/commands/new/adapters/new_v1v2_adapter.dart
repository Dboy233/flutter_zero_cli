// `new` 命令 1.0.x ~ 2.x 版本适配器（独立文件）。
//
// 1.0.x ~ 2.x adapter for the `new` command (standalone file).

import 'dart:io';

import 'package:fluzer/src/commands/new/adapters/base_new_adapter.dart';
import 'package:fluzer/src/commands/new/new_context.dart';
import 'package:fluzer/src/commands/version/version_spec.dart';
import 'package:fluzer/src/config/project_config.dart';
import 'package:fluzer/src/util/step_runner.dart';
import 'package:fluzer/src/template/brick_loader.dart';
import 'package:fluzer/src/template/brick_renderer.dart';
import 'package:fluzer/src/template/feature_generator.dart';
import 'package:fluzer/src/template/template_source.dart';
import 'package:fluzer/src/util/semantic_version.dart';
import 'package:mason/mason.dart';

/// 1.0.x ~ 2.x 适配器：DI 注册目标为 `injection_base.dart`。
///
/// 1.0.x ~ 2.x adapter: DI target is `injection_base.dart`.
class NewV1V2Adapter extends BaseNewAdapter {
  /// 创建 1.0.x 适配器。
  ///
  /// Creates the 1.0.x adapter.
  NewV1V2Adapter({required super.deps})
    : super(spec: const RangeSpec(SemanticVersion(1, 0, 0)));

  @override
  Future<int> run(NewCommandContext ctx) async {
    final featureName = ctx.featureName;
    if (featureName == null) {
      deps.logger.err(deps.translations.feature.nameRequired);
      return 1;
    }

    final logger = deps.logger;
    final translations = deps.translations;

    late ProjectConfig config;
    late BrickLoader brickLoader;

    final steps = StepRunner(logger: logger, translations: translations);

    // 1. 加载项目配置
    steps.add(translations.feature.step1Load, () async {
      config = await ProjectConfig.load(
        start: Directory(ctx.projectRoot),
        messages: translations,
      );
    });

    // 2. 解析模板加载器（本地或远程下载）
    steps.add(translations.feature.step2Template, () async {
      brickLoader =
          deps.loader ??
          await TemplateSourceResolver(
            logger: logger,
            messages: translations,
          ).resolve(pinnedVersion: config.version);
    });

    // 3. 生成功能模块；完成后打印 DI 注册确认（步骤间总结日志用 onDone）
    steps.add(
      translations.feature.step3Generate(feature: featureName),
      () async {
        final generator = FeatureGenerator(
          config: config,
          renderer: BrickRenderer(brickLoader),
          messages: translations,
          diTargetPath: diTargetPath,
        );
        await generator.generate(featureName);
      },
      onDone: () {
        logger.success(
          translations.feature.successCreated(feature: featureName),
        );
      },
    );

    // 4. 运行 build_runner（条件步骤：仅 --build-runner 时启用；
    //    子命令非零退出码时抛异常中断，由下方 catch 统一返回 1）
    steps.add(
      translations.feature.step4BuildRunner,
      () async {
        final code = await _runBuildRunner(
          config.projectRoot,
          buildFilter: 'lib/features/$featureName/**.dart',
        );
        if (code != 0) {
          throw CliException(translations.feature.buildRunnerFailed);
        }
      },
      onDone: () {
        logger.success(translations.feature.buildRunnerCompleted);
      },
    );

    try {
      await steps.runAll();
      return 0;
    } on CliException catch (e) {
      logger.err(e.message);
      return 1;
    } on Object catch (e) {
      logger.err(translations.feature.generationFailed(error: e));
      return 1;
    }
  }

  Future<int> _runBuildRunner(String projectRoot, {String? buildFilter}) {
    final args = ['run', 'build_runner', 'build'];
    if (buildFilter != null) args.addAll(['--build-filter', buildFilter]);
    return deps.processRunner.run(
      'dart',
      args,
      workingDirectory: projectRoot,
      showLive: deps.logger.level == Level.verbose,
    );
  }
}
