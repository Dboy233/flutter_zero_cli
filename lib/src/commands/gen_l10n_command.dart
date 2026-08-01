import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

import '../codemod/code_mod.dart';
import '../config/project_config.dart';
import '../gen_l10n/l10n_code_generator.dart';
import '../gen_l10n/l10n_config.dart';
import '../gen_l10n/l10n_parser.dart';
import '../gen_l10n/toast_handle_patcher.dart';
import '../process/process_runner.dart';

/// `flutter gen-l10n` 执行器签名。
typedef FlutterGenL10nRunner = Future<int> Function(String projectRoot);

/// `gen-l10n` 命令：执行 Flutter 国际化代码生成，并自动生成
/// `L10nCode` 值对象、Toast 类型扩展与集中式 Toast 分发器。
///
/// `gen-l10n` command: runs Flutter localization code generation and
/// auto-generates the L10nCode value object, toast-type extension and
/// the centralized toast dispatcher.
class GenL10nCommand extends Command<int> {
  /// 创建 GenL10nCommand 实例。
  ///
  /// [flutterGenL10nFn] 用于注入 flutter gen-l10n 执行器（测试用 stub）；
  /// 省略时使用默认实现。
  GenL10nCommand({Logger? logger, FlutterGenL10nRunner? flutterGenL10nFn})
    : _logger = logger ?? Logger(),
      _flutterGenL10n = flutterGenL10nFn ?? _defaultFlutterGenL10n {
    argParser
      ..addFlag(
        'skip-handle-patch',
        negatable: false,
        help:
            '跳过 defaultToastHandle 自动接线 / '
            'Skip patching defaultToastHandle.',
      )
      ..addFlag(
        'force-handle-patch',
        negatable: false,
        help:
            'l10nCode 分支已被自定义时也强制覆盖 / '
            'Overwrite even if the l10nCode branch was customized.',
      );
  }

  final Logger _logger;
  final FlutterGenL10nRunner _flutterGenL10n;

  @override
  String get name => 'gen-l10n';

  @override
  String get description =>
      '生成国际化代码并自动创建 L10nCode 类 / '
      'Generate localization code and create L10nCode class';

  @override
  Future<int> run() async {
    try {
      // 1. 校验当前目录为合法 flutter_zero 项目
      final config = await ProjectConfig.load();
      final projectRoot = config.projectRoot;

      // 2. 解析 l10n.yaml（字段缺失回退模板默认值）
      final l10nConfig = await L10nConfig.load(projectRoot);

      // 3. 校验 ARB 目录存在且包含 .arb 文件
      final arbDir = Directory(
        path.joinAll([projectRoot, ...l10nConfig.arbDir.split('/')]),
      );
      if (!await arbDir.exists()) {
        _logger.err(
          '未找到 ${l10nConfig.arbDir} 目录，请确保项目已配置国际化。\n'
          'Could not find ${l10nConfig.arbDir} directory. '
          'Make sure l10n is configured in this project.',
        );
        return 1;
      }
      final arbFiles = await arbDir
          .list()
          .where((e) => e is File && e.path.endsWith('.arb'))
          .toList();
      if (arbFiles.isEmpty) {
        _logger.err(
          '${l10nConfig.arbDir} 目录中没有找到 .arb 文件。\n'
          'No .arb files found in ${l10nConfig.arbDir} directory.',
        );
        return 1;
      }
      _logger.info(
        '找到 ${arbFiles.length} 个 .arb 文件 / '
        'Found ${arbFiles.length} .arb file(s)',
      );

      // 4. 执行 flutter gen-l10n
      _logger.info('正在运行 flutter gen-l10n...');
      final exitCode = await _flutterGenL10n(projectRoot);
      if (exitCode != 0) {
        _logger.err(
          'flutter gen-l10n 执行失败（退出码: $exitCode）。\n'
          'flutter gen-l10n failed (exit code: $exitCode).',
        );
        return exitCode;
      }
      _logger.success('flutter gen-l10n 执行完成。');

      // 5. 定位生成的本地化文件（配置目录优先，回退 flutter 默认目录）
      final appLocalizationsFile = await _findGeneratedFile(
        projectRoot,
        l10nConfig,
      );
      if (appLocalizationsFile == null) {
        _logger.err(
          '未找到生成的 ${l10nConfig.outputLocalizationFile}，'
          '请检查 l10n.yaml 中 output-dir 配置。\n'
          'Generated ${l10nConfig.outputLocalizationFile} not found. '
          'Check output-dir in l10n.yaml.',
        );
        return 1;
      }

      final source = await appLocalizationsFile.readAsString();
      final members = parseAppLocalizations(
        source,
        className: l10nConfig.outputClass,
      );

      final noParamCount = members.where((m) => !m.hasParams).length;
      final withParamCount = members.length - noParamCount;
      _logger.info(
        '解析到 ${members.length} 个本地化成员 '
        '($noParamCount 无参, $withParamCount 有参)',
      );
      if (members.isEmpty) {
        _logger.warn(
          '未解析到任何本地化成员，请检查 arb 文件是否包含翻译 key。\n'
          'No localization members found. '
          'Check whether your arb files contain translation keys.',
        );
      }

      // 6. 内存中生成全部内容，最后统一写入（避免部分写入的不一致状态）
      final genDir = path.joinAll([
        projectRoot,
        ...l10nConfig.outputDir.split('/'),
      ]);
      final outputs = <File, String>{
        File(path.join(genDir, 'l10n_code.dart')): generateL10nCode(members),
        File(path.join(genDir, 'l10n_code_ext.dart')): generateL10nCodeExt(
          config.packageName,
        ),
        File(path.join(genDir, 'l10n_toast_effect_helper.dart')):
            generateL10nToastEffectHelper(members, config.packageName),
      };

      for (final entry in outputs.entries) {
        await entry.key.writeAsString(entry.value);
        _logger.success('已生成 / Generated: ${entry.key.path}');
      }

      // 7. 自动接线 defaultToastHandle（幂等，可用 --skip-handle-patch 跳过）
      if (argResults!['skip-handle-patch'] as bool) {
        _logger.info(
          '已跳过 defaultToastHandle 接线（--skip-handle-patch）/ '
          'Skipped handle patch.',
        );
      } else {
        await _patchDefaultToastHandle(
          projectRoot: projectRoot,
          packageName: config.packageName,
          force: argResults!['force-handle-patch'] as bool,
        );
      }

      return 0;
    } on CliException catch (e) {
      _logger.err(e.message);
      return 1;
    } on FormatException catch (e) {
      _logger.err(e.message);
      return 1;
    } on Object catch (e) {
      _logger.err('gen-l10n 执行失败 / gen-l10n failed: $e');
      return 1;
    }
  }

  /// 将 `default_toast_effect_handle.dart` 的 l10nCode 分支接线到
  /// `L10nToastEffectHelper`；patched 时补齐 import 并统一格式化。
  ///
  /// 三态：模板态替换 / 已接线幂等跳过 / 自定义态保守跳过（--force 覆盖）。
  Future<void> _patchDefaultToastHandle({
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
      _logger.warn(
        '未找到 default_toast_effect_handle.dart，跳过自动接线。\n'
        '请手动将 L10nToastEffectHelper 接入 defaultToastHandle。\n'
        'Handle file not found; wire L10nToastEffectHelper manually.',
      );
      return;
    }

    final outcome = await patchDefaultToastHandle(handleFile, force: force);
    switch (outcome.result) {
      case ToastHandlePatchResult.patched:
        // 补齐 import（幂等），随后 dart_style 库内统一格式化
        final mod = CodeMod(handleFile, format: false);
        await mod.addImport('package:$packageName/l10n/gen/l10n_code.dart');
        await mod.addImport(
          'package:$packageName/l10n/gen/l10n_toast_effect_helper.dart',
        );
        await formatDartFile(handleFile);
        _logger.success(
          'defaultToastHandle 已接线 L10nToastEffectHelper。\n'
          'Wired L10nToastEffectHelper into defaultToastHandle.\n'
          '被替换的分支原文 / Replaced branch:\n'
          '${outcome.replacedSource?.trim()}',
        );
      case ToastHandlePatchResult.alreadyWired:
        _logger.info('defaultToastHandle 已接线，跳过（幂等）/ Already wired, skipped.');
      case ToastHandlePatchResult.customSkipped:
        _logger.warn(
          '检测到 l10nCode 分支已被自定义，跳过接线。\n'
          '如需强制覆盖请使用 --force-handle-patch。\n'
          'Customized l10nCode branch detected; skipped. '
          'Use --force-handle-patch to overwrite.',
        );
      case ToastHandlePatchResult.anchorNotFound:
        _logger.warn(
          '未找到 defaultToastHandle 的 l10nCode 分支锚点，跳过接线。\n'
          '请手动接入 L10nToastEffectHelper。\n'
          'Branch anchor not found; wire L10nToastEffectHelper manually.',
        );
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

  static Future<int> _defaultFlutterGenL10n(String projectRoot) {
    return ProcessRunner.run('flutter', [
      'gen-l10n',
    ], workingDirectory: projectRoot);
  }
}
