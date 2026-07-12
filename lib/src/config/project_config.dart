import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

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

  /// 配置文件名。
  ///
  /// Configuration file name.
  static const String fileName = 'flutter_zero_config.yaml';

  /// 模板项目必须包含的最小版本号。
  ///
  /// 未来 CLI 支持多版本时可改为版本范围兼容。
  ///
  /// Minimum supported template version.
  static const String minimumSupportedVersion = '1.0.0';

  /// 查找并加载项目配置。
  ///
  /// 返回配置；失败时抛出 [CliException]。
  ///
  ///
  /// Locates and loads the project configuration.
  ///
  /// Returns the config or throws [CliException] on failure.
  static Future<ProjectConfig> load() async {
    final root = await _findProjectRoot(Directory.current);
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

    if (_compareVersions(version, minimumSupportedVersion) < 0) {
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

  /// 简单版本号比较，支持 x.y.z 格式。
  ///
  /// Simple x.y.z version comparison.
  static int _compareVersions(String a, String b) {
    final aParts = a.split('.').map(int.tryParse).toList();
    final bParts = b.split('.').map(int.tryParse).toList();
    for (var i = 0; i < aParts.length && i < bParts.length; i++) {
      final av = aParts[i] ?? 0;
      final bv = bParts[i] ?? 0;
      if (av != bv) return av.compareTo(bv);
    }
    return aParts.length.compareTo(bParts.length);
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
