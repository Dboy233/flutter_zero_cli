import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../util/semantic_version.dart';
import 'template_config.dart';

/// 项目配置加载与校验。
///
/// 从当前目录向上查找 `flutter_zero_config.yaml`，
/// 验证其为有效的 flutter_zero 模板项目。
///
///
/// Project configuration loader and validator.
///
/// Walks up from the current directory looking for
/// `flutter_zero_config.yaml`, validating that the directory
/// belongs to a flutter_zero template project.
class ProjectConfig {
  /// 创建项目配置。
  ///
  /// Creates a project configuration.
  const ProjectConfig({
    required this.version,
    required this.projectRoot,
    required this.templateName,
    required this.packageName,
    required this.minCliVersion,
  });

  /// 模板版本号。
  ///
  /// Template version.
  final String version;

  /// 项目根目录绝对路径。
  ///
  /// Absolute path of the project root.
  final String projectRoot;

  /// 模板名称。
  ///
  /// Template name.
  final String templateName;

  /// Flutter 包名，用于生成 package 导入。
  ///
  /// Flutter package name, used for package imports.
  final String packageName;

  /// 该模板版本要求的最低 CLI 版本。
  ///
  /// Minimum CLI version required by this template version.
  ///
  /// 缺失时（老项目未写入该字段）默认 `"0.0.0"`，表示兼容任意 CLI 版本。
  /// Defaults to `"0.0.0"` when missing (legacy projects), meaning any CLI
  /// version is accepted.
  final String minCliVersion;

  /// 判断当前运行的 CLI 版本是否满足该项目模板的最低要求。
  ///
  /// 用于 `new` / `gen-l10n` 命令的版本门禁：
  /// 当 [currentCliVersion] >= [minCliVersion] 时返回 `true`。
  ///
  /// Checks whether the running CLI version satisfies this template's
  /// minimum requirement. Returns `true` when
  /// [currentCliVersion] >= [minCliVersion].
  bool isCliCompatible(String currentCliVersion) {
    return SemanticVersion.parse(minCliVersion) <=
        SemanticVersion.parse(currentCliVersion);
  }

  /// 配置文件名。
  ///
  /// Configuration file name.
  static const String fileName = 'flutter_zero_config.yaml';

  /// 查找并加载项目配置。
  ///
  /// [start] 为向上查找的起始目录，默认当前工作目录；测试可注入临时目录。
  /// 返回配置；失败时抛出 [CliException]。
  ///
  ///
  /// Locates and loads the project configuration.
  ///
  /// [start] is the directory to walk up from (defaults to cwd).
  /// Returns the config or throws [CliException] on failure.
  static Future<ProjectConfig> load({Directory? start}) async {
    final root = await _findProjectRoot(start ?? Directory.current);
    if (root == null) {
      throw CliException(
        '未找到 $fileName，请确保在 flutter_zero 模板项目根目录下执行命令。\n'
        'Could not find $fileName. Make sure you run this command from a '
        'flutter_zero template project root.',
      );
    }

    final configFile = File(path.join(root.path, fileName));
    final raw = await configFile.readAsString();
    final yaml = loadYaml(raw);

    if (yaml is! Map) {
      throw CliException(
        '$fileName 格式错误：根节点必须是 Map。\n'
        'Invalid $fileName: root must be a Map.',
      );
    }

    final version = yaml['version'];
    if (version is! String || version.isEmpty) {
      throw CliException(
        '$fileName 中缺少有效的 version 字段。\n'
        'Missing valid "version" field in $fileName.',
      );
    }

    // minCliVersion 为可选字段：老项目可能未写入，默认 "0.0.0"（兼容任意 CLI）。
    final rawMinCli = yaml['minCliVersion'];
    final minCliVersion = rawMinCli is String && rawMinCli.isNotEmpty
        ? rawMinCli
        : '0.0.0';

    if (SemanticVersion.parse(version) <
        SemanticVersion.parse(minimumSupportedVersion)) {
      throw CliException(
        '模板版本 $version 过低，请使用 >= $minimumSupportedVersion 的项目模板。\n'
        'Template version $version is too old. '
        'Please use a project template >= $minimumSupportedVersion.',
      );
    }

    final templateName = yaml['template_name'];
    if (templateName is! String || templateName != 'flutter_zero') {
      throw CliException(
        '$fileName 中 template_name 必须是 "flutter_zero"。\n'
        'The "template_name" field in $fileName must be "flutter_zero".',
      );
    }

    // 额外校验项目结构是否存在
    final pubspecFile = File(path.join(root.path, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) {
      throw CliException(
        '项目目录缺少 pubspec.yaml。\n'
        'Missing pubspec.yaml in project root.',
      );
    }
    final pubspecYaml = loadYaml(await pubspecFile.readAsString());
    final packageName = pubspecYaml['name'];
    if (packageName is! String || packageName.isEmpty) {
      throw CliException(
        'pubspec.yaml 中缺少有效的 name 字段。\n'
        'Missing valid "name" field in pubspec.yaml.',
      );
    }

    final libDir = Directory(path.join(root.path, 'lib'));
    if (!await libDir.exists()) {
      throw CliException(
        '项目目录缺少 lib/ 目录，无法识别为 Flutter 项目。\n'
        'Missing lib/ directory in project root.',
      );
    }

    final injectionBase = File(
      path.join(root.path, 'lib', 'core', 'di', 'injection_base.dart'),
    );
    if (!await injectionBase.exists()) {
      throw CliException(
        '未找到 lib/core/di/injection_base.dart，无法自动注册模块。\n'
        'Could not find lib/core/di/injection_base.dart.',
      );
    }

    return ProjectConfig(
      version: version,
      projectRoot: root.path,
      templateName: templateName,
      packageName: packageName,
      minCliVersion: minCliVersion,
    );
  }

  /// 从 [start] 向上查找包含 `flutter_zero_config.yaml` 的目录。
  ///
  /// Walks up from [start] looking for `flutter_zero_config.yaml`.
  static Future<Directory?> _findProjectRoot(Directory start) async {
    var current = start.absolute;
    while (true) {
      final file = File(path.join(current.path, fileName));
      if (await file.exists()) return current;

      final parent = current.parent;
      if (parent.path == current.path) return null;
      current = parent;
    }
  }
}

/// CLI 业务异常。
///
/// CLI business exception.
class CliException implements Exception {
  /// 创建异常。
  ///
  /// Creates the exception.
  const CliException(this.message);

  /// 错误信息。
  ///
  /// Error message.
  final String message;

  @override
  String toString() => message;
}
