import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fluzer/src/i18n/gen/strings.g.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

import '../codemod/code_mod.dart';
import '../config/project_config.dart';
import '../config/template_config.dart';
import '../gen_l10n/l10n_code_generator.dart';
import '../gen_l10n/l10n_config.dart';
import '../gen_l10n/l10n_parser.dart';
import '../gen_l10n/toast_handle_patcher.dart';
import '../logging/spinner.dart';
import '../process/process_runner.dart';
import '../version/version_check.dart';
import '../version/version_check_mixin.dart';

/// `flutter gen-l10n` 执行器签名。
typedef FlutterGenL10nRunner = Future<int> Function(String projectRoot);

/// `gen-l10n` 命令：执行 Flutter 国际化代码生成，并自动生成
/// `L10nCode` 值对象、Toast 类型扩展与集中式 Toast 分发器。
///
/// `gen-l10n` command: runs Flutter localization code generation and
/// auto-generates the L10nCode value object, toast-type extension and
/// the centralized toast dispatcher.
class GenL10nCommand extends Command<int> with VersionCheckMixin {
  /// 创建 GenL10nCommand 实例。
  ///
  /// [flutterGenL10nFn] 用于注入 flutter gen-l10n 执行器（测试用 stub）；
  /// [workingDirectory] 指定项目根目录（向上查找 `flutter_zero_config.yaml`
  /// 的起点），省略时回退到当前工作目录；测试可注入临时目录以避免依赖全局 cwd。
  /// 省略时使用默认实现。
  GenL10nCommand({
    Logger? logger,
    FlutterGenL10nRunner? flutterGenL10nFn,
    this.workingDirectory,
    VersionCheckService? versionCheckService,
    ProcessRunner? processRunner,
    ToastHandlePatcher? patcher,
    Translations? messages,
  }) : _logger = logger ?? Logger(),
       _messages = messages ?? AppLocale.zh.buildSync(),
       _versionCheckService =
           versionCheckService ??
           VersionCheckService(
             logger: logger ?? Logger(),
             messages: messages ?? AppLocale.zh.buildSync(),
           ),
       _processRunner = processRunner ?? ProcessRunner(),
       _patcher = patcher ?? const ToastHandlePatcher() {
    _flutterGenL10n = flutterGenL10nFn ?? _defaultFlutterGenL10n;
    argParser
      ..addFlag(
        'skip-handle-patch',
        negatable: false,
        help: _messages.genL10n.skipHandlePatchHelp,
      )
      ..addFlag(
        'force-handle-patch',
        negatable: false,
        help: _messages.genL10n.forceHandlePatchHelp,
      )
      ..addFlag(
        'skip-version-check',
        negatable: false,
        help: _messages.genL10n.skipVersionCheckHelp,
      );
  }

  final Logger _logger;

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

  final ToastHandlePatcher _patcher;

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
  late final FlutterGenL10nRunner _flutterGenL10n;

  /// 标记 defaultToastHandle 文件是否不存在（用于区分「文件缺失」与「锚点缺失」）。
  bool _patchFileNotFound = false;

  @override
  String get name => 'gen-l10n';

  @override
  String get description => _messages.genL10n.description;

  @override
  Future<int> run() async {
    // 启动版本检查提示（缓存命中瞬时提示，缓存未命中以 spinner 包裹网络等待）；
    // 无更新 / 网络异常静默降级，不阻断主流程。
    await ensureUpdateNotified();

    late String projectRoot;
    late ProjectConfig config;
    late L10nConfig l10nConfig;
    late List<FileSystemEntity> arbFiles;
    late File appLocalizationsFile;
    late List<L10nMember> members;

    try {
      // 每一步骤都用 runWithSpinner 给出「正在执行」的旋转反馈；
      // --log（verbose）模式下由 logger.level 控制不显示 spinner，过程靠日志展示。
      // work 内部只用 detail（非 verbose 下被抑制），info/success 摘要移到
      // spinner 结束后，避免破坏 spinner 动画所在的行。
      await runWithSpinner(
        logger: _logger,
        messages: _messages,
        message: _messages.genL10n.step1Validate,
        work: () async {
          config = await ProjectConfig.load(
            start: workingDirectory,
            messages: _messages,
          );
          projectRoot = config.projectRoot;
          // 版本门禁：gen-l10n 不下载模板，门禁通过即继续执行。
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

      // 2. 解析 l10n.yaml（字段缺失回退模板默认值）
      await runWithSpinner(
        logger: _logger,
        messages: _messages,
        message: _messages.genL10n.step2Parse,
        work: () async {
          l10nConfig = await L10nConfig.load(projectRoot);
          _logger.detail(
            '  l10n.yaml: arbDir=${l10nConfig.arbDir}, '
            'outputDir=${l10nConfig.outputDir}, '
            'outputClass=${l10nConfig.outputClass}',
          );

          final arbDir = Directory(
            path.joinAll([projectRoot, ...l10nConfig.arbDir.split('/')]),
          );
          if (!await arbDir.exists()) {
            throw CliException(
              _messages.genL10n.arbDirNotFound(dir: l10nConfig.arbDir),
            );
          }
          arbFiles = await arbDir
              .list()
              .where((e) => e is File && e.path.endsWith('.arb'))
              .toList();
          if (arbFiles.isEmpty) {
            throw CliException(
              _messages.genL10n.noArbFiles(dir: l10nConfig.arbDir),
            );
          }
          _logger.detail(
            '  arb 文件: ${arbFiles.map((f) => path.basename(f.path)).join(', ')}',
          );
        },
      );
      _logger.success(_messages.genL10n.foundArbFiles(count: arbFiles.length));

      // 3. 执行 flutter gen-l10n
      final exitCode = await runWithSpinner(
        logger: _logger,
        messages: _messages,
        message: _messages.genL10n.step3GenL10n,
        work: () => _flutterGenL10n(projectRoot),
      );
      if (exitCode != 0) {
        _logger.err(_messages.genL10n.flutterFailed(code: exitCode));
        return exitCode;
      }

      // 4. 解析本地化成员
      await runWithSpinner(
        logger: _logger,
        messages: _messages,
        message: _messages.genL10n.step4Members,
        work: () async {
          final found = await _findGeneratedFile(projectRoot, l10nConfig);
          if (found == null) {
            throw CliException(
              _messages.genL10n.generatedFileNotFound(
                file: l10nConfig.outputLocalizationFile,
              ),
            );
          }
          appLocalizationsFile = found;
          final source = await appLocalizationsFile.readAsString();
          members = parseAppLocalizations(
            source,
            className: l10nConfig.outputClass,
            messages: _messages,
          );
          _logger.detail(
            _messages.genL10n.detailMembers(
              names: members.map((m) => m.name).join(', '),
            ),
          );
        },
      );
      final noParamCount = members.where((m) => !m.hasParams).length;
      final withParamCount = members.length - noParamCount;
      _logger.info(
        _messages.genL10n.parsedMembers(
          total: members.length,
          noParam: noParamCount,
          withParam: withParamCount,
        ),
      );
      if (members.isEmpty) {
        _logger.warn(_messages.genL10n.noMembers);
      }

      // 5. 生成 L10nCode 等文件
      final generatedPaths = <String>[];
      await runWithSpinner(
        logger: _logger,
        messages: _messages,
        message: _messages.genL10n.step5Generate,
        work: () async {
          final genDir = path.joinAll([
            projectRoot,
            ...l10nConfig.outputDir.split('/'),
          ]);
          final outputs = <File, String>{
            File(path.join(genDir, 'l10n_code.dart')): generateL10nCode(
              members,
            ),
            File(path.join(genDir, 'l10n_code_ext.dart')): generateL10nCodeExt(
              config.packageName,
            ),
            File(path.join(genDir, 'l10n_toast_effect_helper.dart')):
                generateL10nToastEffectHelper(members, config.packageName),
          };
          for (final entry in outputs.entries) {
            await entry.key.writeAsString(entry.value);
            generatedPaths.add(entry.key.path);
          }
        },
      );
      for (final p in generatedPaths) {
        _logger.success(_messages.genL10n.generated(path: p));
      }

      // 6. 自动接线 defaultToastHandle（幂等，可用 --skip-handle-patch 跳过）
      if (argResults!['skip-handle-patch'] as bool) {
        _logger.info(_messages.genL10n.skippedHandlePatch);
      } else {
        final outcome = await runWithSpinner(
          logger: _logger,
          messages: _messages,
          message: _messages.genL10n.step6Wire,
          work: () => _patchDefaultToastHandle(
            projectRoot: projectRoot,
            packageName: config.packageName,
            force: argResults!['force-handle-patch'] as bool,
          ),
        );
        _reportPatchResult(outcome);
      }

      return 0;
    } on CliException catch (e) {
      _logger.err(e.message);
      return 1;
    } on FormatException catch (e) {
      _logger.err(e.message);
      return 1;
    } on Object catch (e) {
      _logger.err(_messages.genL10n.failed(error: e));
      return 1;
    }
  }

  /// 将 `default_toast_effect_handle.dart` 的 l10nCode 分支接线到
  /// `L10nToastEffectHelper`；patched 时补齐 import 并统一格式化。
  ///
  /// 不在此处打印状态（会破坏外层 runWithSpinner 的动画行），改为返回
  /// [ToastHandlePatchOutcome]，由调用方在 spinner 结束后通过
  /// [_reportPatchResult] 打印。三态：模板态替换 / 已接线幂等跳过 /
  /// 自定义态保守跳过（--force 覆盖）。文件不存在时返回 anchorNotFound 占位
  /// outcome（由 [_patchFileNotFound] 区分其消息）。
  Future<ToastHandlePatchOutcome> _patchDefaultToastHandle({
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
      _patchFileNotFound = true;
      return const (
        result: ToastHandlePatchResult.anchorNotFound,
        replacedSource: null,
      );
    }

    final outcome = await _patcher.patch(handleFile, force: force);
    if (outcome.result == ToastHandlePatchResult.patched) {
      // 补齐 import（幂等），随后 dart_style 库内统一格式化
      final mod = CodeMod(handleFile, format: false, messages: _messages);
      await mod.addImport('package:$packageName/l10n/gen/l10n_code.dart');
      await mod.addImport(
        'package:$packageName/l10n/gen/l10n_toast_effect_helper.dart',
      );
      await _patcher.format(handleFile);
    }
    return outcome;
  }

  /// 在 spinner 结束后打印接线结果（避免在 runWithSpinner 内部打印破坏动画行）。
  void _reportPatchResult(ToastHandlePatchOutcome outcome) {
    switch (outcome.result) {
      case ToastHandlePatchResult.patched:
        _logger.success(
          _messages.genL10n.patched(
            replaced: outcome.replacedSource?.trim() ?? '',
          ),
        );
      case ToastHandlePatchResult.alreadyWired:
        _logger.info(_messages.genL10n.alreadyWired);
      case ToastHandlePatchResult.customSkipped:
        _logger.warn(_messages.genL10n.customSkipped);
      case ToastHandlePatchResult.anchorNotFound:
        if (_patchFileNotFound) {
          _logger.warn(_messages.genL10n.handleFileNotFound);
        } else {
          _logger.warn(_messages.genL10n.branchAnchorNotFound);
        }
    }
  }

  /// 按 l10n.yaml 配置定位生成的本地化文件；
  /// 配置目录不存在时回退探测 flutter 默认目录。
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

  Future<int> _defaultFlutterGenL10n(String projectRoot) {
    return _processRunner.run(
      'flutter',
      ['gen-l10n'],
      workingDirectory: projectRoot,
      showLive: _logger.level == Level.verbose,
      runInShell: true,
    );
  }
}
