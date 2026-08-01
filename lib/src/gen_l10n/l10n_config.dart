import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// `l10n.yaml` 配置（`flutter gen-l10n` 的输入配置）。
///
/// Parsed view of the project's `l10n.yaml`. 字段缺失时回退到
/// flutter_zero 模板约定的默认值。
class L10nConfig {
  /// 创建 l10n 配置。
  const L10nConfig({
    required this.arbDir,
    required this.outputDir,
    required this.outputLocalizationFile,
    required this.outputClass,
  });

  /// ARB 文件目录（相对项目根）。
  ///
  /// Directory containing `.arb` files, relative to project root.
  final String arbDir;

  /// 生成文件输出目录（相对项目根）。
  ///
  /// Output directory for generated files, relative to project root.
  final String outputDir;

  /// 生成的本地化主文件名。
  ///
  /// Name of the generated main localization file.
  final String outputLocalizationFile;

  /// 生成的本地化类名。
  ///
  /// Name of the generated localization class.
  final String outputClass;

  static const String _defaultArbDir = 'lib/l10n';
  static const String _defaultOutputDir = 'lib/l10n/gen';
  static const String _defaultOutputFile = 'app_localizations.dart';
  static const String _defaultOutputClass = 'AppLocalizations';

  /// Flutter 默认（无 output-dir 时）的生成目录。
  ///
  /// Fallback output directory used by `flutter gen-l10n` when
  /// `output-dir` is not configured.
  static const String flutterGenFallbackDir = '.dart_tool/flutter_gen/gen_l10n';

  /// 模板默认值。
  ///
  /// Defaults matching the flutter_zero template convention.
  static const L10nConfig defaults = L10nConfig(
    arbDir: _defaultArbDir,
    outputDir: _defaultOutputDir,
    outputLocalizationFile: _defaultOutputFile,
    outputClass: _defaultOutputClass,
  );

  /// 从项目根加载 `l10n.yaml`；文件不存在或字段缺失时使用默认值。
  ///
  /// Loads `l10n.yaml` from [projectRoot]. Missing file or fields
  /// fall back to [defaults].
  static Future<L10nConfig> load(String projectRoot) async {
    final file = File(path.join(projectRoot, 'l10n.yaml'));
    if (!await file.exists()) return defaults;

    final yaml = loadYaml(await file.readAsString());
    if (yaml is! Map) return defaults;

    // synthetic-package: true 且未配置 output-dir 时，
    // flutter gen-l10n 输出到 .dart_tool/flutter_gen/gen_l10n。
    final synthetic = yaml['synthetic-package'] == true;
    final outputDir = yaml['output-dir'] as String? ??
        (synthetic ? flutterGenFallbackDir : _defaultOutputDir);

    return L10nConfig(
      arbDir: yaml['arb-dir'] as String? ?? _defaultArbDir,
      outputDir: outputDir,
      outputLocalizationFile:
          yaml['output-localization-file'] as String? ?? _defaultOutputFile,
      outputClass: yaml['output-class'] as String? ?? _defaultOutputClass,
    );
  }
}
