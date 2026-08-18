// `gen-l10n` 命令 1.0.0~2.x 通用适配器（独立文件）。
//
// 1.0.0~2.x shared adapter for the `gen-l10n` command (standalone file).

import 'dart:io';

import 'package:fluzer/src/codemod/code_mod.dart';
import 'package:fluzer/src/commands/gen_l10n/adapters/base_gen_l10n_adapter.dart';
import 'package:fluzer/src/commands/gen_l10n/gen_l10n_context.dart';
import 'package:fluzer/src/commands/version/version_spec.dart';
import 'package:fluzer/src/config/project_config.dart';
import 'package:fluzer/src/gen_l10n/l10n_code_generator.dart';
import 'package:fluzer/src/gen_l10n/l10n_config.dart';
import 'package:fluzer/src/gen_l10n/l10n_parser.dart';
import 'package:fluzer/src/gen_l10n/toast_handle_patcher.dart';
import 'package:fluzer/src/util/semantic_version.dart';
import 'package:fluzer/src/util/step_runner.dart';
import 'package:fluzer/src/version/version_update_notifier.dart';
import 'package:path/path.dart' as path;

/// 1.0.0 起通用适配器（无上界）：gen-l10n 集成步骤跨版本一致，
/// 单个适配器即可覆盖所有已知与未来模板版本（CLI 力求适配所有模板版本）。
///
/// 1.0.0+ shared adapter (unbounded): gen-l10n integration is version-stable,
/// so a single adapter covers all known and future template versions.
class GenL10nV1V2Adapter extends BaseGenL10nAdapter {
  /// 创建跨版本适配器。
  ///
  /// Creates the cross-version adapter.
  GenL10nV1V2Adapter({required super.deps})
    : super(spec: const RangeSpec(SemanticVersion(1, 0, 0)));

  @override
  Future<int> run(GenL10nCommandContext context) => _run(context);

  Future<int> _run(GenL10nCommandContext ctx) async {
    final logger = deps.logger;
    final translations = deps.translations;

    late String projectRoot;
    late ProjectConfig config;
    late L10nConfig l10nConfig;
    late File appLocalizationsFile;
    late List<L10nMember> members;

    final steps = StepRunner(logger: logger, translations: translations);

    // 启动版本检查提示（仅在项目内执行的 gen-l10n 命令显式 opt-in；缓存命中瞬时
    // 提示，缓存未命中以 spinner 包裹网络等待；无更新 / 网络异常静默降级）。
    await VersionUpdateNotifier(
      logger: logger,
      translations: translations,
      versionCheckService: deps.versionCheckService,
    ).notify(steps);

    // 1. 校验项目与版本门禁
    steps.add(translations.genL10n.step1Validate, () async {
      config = await ProjectConfig.load(
        start: Directory(ctx.projectRoot),
        messages: translations,
      );
      projectRoot = config.projectRoot;
    });

    // 2. 解析 l10n.yaml 与 ARB 目录；完成后打印找到的 arb 文件数（步骤间总结）
    steps.add(
      translations.genL10n.step2Parse,
      () async {
        l10nConfig = await L10nConfig.load(projectRoot);
        logger.detail(
          '  l10n.yaml: arbDir=${l10nConfig.arbDir}, '
          'outputDir=${l10nConfig.outputDir}, '
          'outputClass=${l10nConfig.outputClass}',
        );

        final arbDir = Directory(
          path.joinAll([projectRoot, ...l10nConfig.arbDir.split('/')]),
        );
        if (!await arbDir.exists()) {
          throw CliException(
            translations.genL10n.arbDirNotFound(dir: l10nConfig.arbDir),
          );
        }
        final arbFiles = await arbDir
            .list()
            .where((e) => e is File && e.path.endsWith('.arb'))
            .toList();
        if (arbFiles.isEmpty) {
          throw CliException(
            translations.genL10n.noArbFiles(dir: l10nConfig.arbDir),
          );
        }
        logger.detail(
          '  arb 文件: ${arbFiles.map((f) => path.basename(f.path)).join(', ')}',
        );
        return arbFiles;
      },
      onDone: (arbFiles) {
        logger.success(
          translations.genL10n.foundArbFiles(count: arbFiles.length),
        );
      },
    );

    // 3. 执行 flutter gen-l10n（子命令非零退出码时抛异常中断）
    steps.add(translations.genL10n.step3GenL10n, () async {
      final code = await deps.flutterGenL10nFn(projectRoot);
      if (code != 0) {
        throw CliException(translations.genL10n.flutterFailed(code: code));
      }
    });

    // 4. 解析本地化成员；完成后打印解析统计（步骤间总结，可依赖 members）
    steps.add(
      translations.genL10n.step4Members,
      () async {
        final found = await _findGeneratedFile(projectRoot, l10nConfig);
        if (found == null) {
          throw CliException(
            translations.genL10n.generatedFileNotFound(
              file: l10nConfig.outputLocalizationFile,
            ),
          );
        }
        appLocalizationsFile = found;
        final source = await appLocalizationsFile.readAsString();
        members = L10nParser.parseAppLocalizations(
          source,
          className: l10nConfig.outputClass,
          messages: translations,
        );
        logger.detail(
          translations.genL10n.detailMembers(
            names: members.map((m) => m.name).join(', '),
          ),
        );
      },
      onDone: (_) {
        final noParamCount = members.where((m) => !m.hasParams).length;
        final withParamCount = members.length - noParamCount;
        logger.info(
          translations.genL10n.parsedMembers(
            total: members.length,
            noParam: noParamCount,
            withParam: withParamCount,
          ),
        );
        if (members.isEmpty) {
          logger.warn(translations.genL10n.noMembers);
        }
      },
    );

    // 5. 生成 L10nCode 等文件；完成后逐个打印已生成路径（步骤间总结）
    steps.add(
      translations.genL10n.step5Generate,
      () async {
        final genDir = path.joinAll([
          projectRoot,
          ...l10nConfig.outputDir.split('/'),
        ]);
        final outputs = <File, String>{
          File(path.join(genDir, 'l10n_code.dart')):
              L10nCodeGenerator.generateL10nCode(members),
          File(path.join(genDir, 'l10n_code_ext.dart')):
              L10nCodeGenerator.generateL10nCodeExt(config.packageName),
          File(
            path.join(genDir, 'l10n_toast_effect_helper.dart'),
          ): L10nCodeGenerator.generateL10nToastEffectHelper(
            members,
            config.packageName,
          ),
        };
        final generatedPaths = <String>[];
        for (final entry in outputs.entries) {
          await entry.key.writeAsString(entry.value);
          generatedPaths.add(entry.key.path);
        }
        return generatedPaths;
      },
      onDone: (generatedPaths) {
        for (final p in generatedPaths) {
          logger.success(translations.genL10n.generated(path: p));
        }
      },
    );

    // 6. 接线 defaultToastHandle（条件步骤：仅未 --skip-handle-patch 时启用）
    steps.add(
      translations.genL10n.step6Wire,
      () async => _patchDefaultToastHandle(
        projectRoot: projectRoot,
        packageName: config.packageName,
        force: ctx.forceHandlePatch,
      ),
      enabled: !ctx.skipHandlePatch,
      onDone: (patchResult) {
        _reportPatchResult(patchResult.outcome, patchResult.fileNotFound);
      },
    );

    try {
      await steps.runAll();
      if (ctx.skipHandlePatch) {
        logger.info(translations.genL10n.skippedHandlePatch);
      }
      return 0;
    } on CliException catch (e) {
      logger.err(e.message);
      return 1;
    } on FormatException catch (e) {
      logger.err(e.message);
      return 1;
    } on Object catch (e) {
      logger.err(translations.genL10n.failed(error: e));
      return 1;
    }
  }

  /// 将 `default_toast_effect_handle.dart` 的 l10nCode 分支接线到
  /// `L10nToastEffectHelper`；patched 时补齐 import 并统一格式化。
  ///
  /// 不在此处打印状态（会破坏外层 SpinnerRunner 的动画行），改为返回
  /// [ToastHandlePatchOutcome] 与文件是否缺失标记，由调用方在 spinner 结束后
  /// 通过 [_reportPatchResult] 打印。
  Future<({ToastHandlePatchOutcome outcome, bool fileNotFound})>
  _patchDefaultToastHandle({
    required String projectRoot,
    required String packageName,
    required bool force,
  }) async {
    final handleFile = File(
      path.joinAll([
        projectRoot,
        'lib',
        'core',
        'effect',
        'effect_handle',
        'default_toast_effect_handle.dart',
      ]),
    );
    if (!await handleFile.exists()) {
      return (
        outcome: const (
          result: ToastHandlePatchResult.anchorNotFound,
          replacedSource: null,
        ),
        fileNotFound: true,
      );
    }

    final outcome = await deps.patcher.patch(handleFile, force: force);
    if (outcome.result == ToastHandlePatchResult.patched) {
      final mod = CodeMod(
        handleFile,
        format: false,
        messages: deps.translations,
      );
      await mod.addImport('package:$packageName/l10n/gen/l10n_code.dart');
      await mod.addImport(
        'package:$packageName/l10n/gen/l10n_toast_effect_helper.dart',
      );
      await deps.patcher.format(handleFile);
    }
    return (outcome: outcome, fileNotFound: false);
  }

  /// 在 spinner 结束后打印接线结果（避免在 SpinnerRunner 内部打印破坏动画行）。
  ///
  /// Prints the patch result after the spinner ends (printing inside
  /// SpinnerRunner would break the animation row).
  void _reportPatchResult(ToastHandlePatchOutcome outcome, bool fileNotFound) {
    switch (outcome.result) {
      case ToastHandlePatchResult.patched:
        deps.logger.success(
          deps.translations.genL10n.patched(
            replaced: outcome.replacedSource?.trim() ?? '',
          ),
        );
      case ToastHandlePatchResult.alreadyWired:
        deps.logger.info(deps.translations.genL10n.alreadyWired);
      case ToastHandlePatchResult.customSkipped:
        deps.logger.warn(deps.translations.genL10n.customSkipped);
      case ToastHandlePatchResult.anchorNotFound:
        if (fileNotFound) {
          deps.logger.warn(deps.translations.genL10n.handleFileNotFound);
        } else {
          deps.logger.warn(deps.translations.genL10n.branchAnchorNotFound);
        }
    }
  }

  /// 按 l10n.yaml 配置定位生成的本地化文件；
  /// 配置目录不存在时回退探测 flutter 默认目录。
  ///
  /// Locates the generated localization file by l10n.yaml; falls back to the
  /// flutter default dir when the configured dir is missing.
  Future<File?> _findGeneratedFile(
    String projectRoot,
    L10nConfig l10nConfig,
  ) async {
    final candidates = [
      path.joinAll([
        projectRoot,
        ...l10nConfig.outputDir.split('/'),
        l10nConfig.outputLocalizationFile,
      ]),
      path.joinAll([
        projectRoot,
        ...L10nConfig.flutterGenFallbackDir.split('/'),
        l10nConfig.outputLocalizationFile,
      ]),
    ];
    for (final candidate in candidates) {
      final file = File(candidate);
      if (await file.exists()) return file;
    }
    return null;
  }
}
