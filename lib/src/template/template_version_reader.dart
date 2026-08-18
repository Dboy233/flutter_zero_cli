// 模板版本读取器（读模板自带 version 声明）。
//
// 仅读取项目配置文件（flutter_zero_config.yaml 或 fluzer.yaml）的 `version`
// 字段，不执行 ProjectConfig 的全量校验，避免与适配器的后续全量加载重复、冲突。
//
// Template version reader (reads the template's own version declaration).
//
// Reads only the `version` field of the project config file
// (flutter_zero_config.yaml or fluzer.yaml), without running ProjectConfig's
// full validation, so it stays lightweight and independent of the adapter's
// later full load.

import 'dart:io';

import 'package:fluzer/src/config/project_config.dart';
import 'package:fluzer/src/i18n/gen/strings.g.dart';
import 'package:fluzer/src/util/semantic_version.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// 模板版本信息（版本 + 项目根目录）。
///
/// Template version info (version + project root).
class ProjectVersionInfo {
  /// 创建版本信息。
  ///
  /// Creates the version info.
  const ProjectVersionInfo({required this.version, required this.projectRoot});

  /// 模板版本号。
  ///
  /// Template version.
  final SemanticVersion version;

  /// 项目根目录绝对路径。
  ///
  /// Absolute project root path.
  final String projectRoot;
}

/// 模板版本读取器。
///
/// Template version reader.
class TemplateVersionReader {
  /// 创建版本读取器。
  ///
  /// Creates the version reader.
  const TemplateVersionReader({required this.translations});

  /// 本地化消息（默认中文），用于异常提示国际化。
  ///
  /// Localized messages (defaults to Chinese) for exception i18n.
  final Translations translations;

  /// 从 [start] 向上查找项目并读取模板版本。
  ///
  /// 兼容 [ProjectConfig.fileNames] 中的任一文件名（v1/v2），
  /// 复用 [ProjectConfig.findConfigFile] 作为唯一文件定位事实源，
  /// 不重复实现向上查找逻辑，也不执行全量校验。
  ///
  /// Walks up from [start] to locate the project and read its template version.
  /// Recognizes any of [ProjectConfig.fileNames] (v1/v2) and reuses
  /// [ProjectConfig.findConfigFile] as the single file locator.
  Future<ProjectVersionInfo> read(Directory start) async {
    final configFile = await ProjectConfig.findConfigFile(start);
    if (configFile == null) {
      throw CliException(
        translations.config.notFound(
          fileName: ProjectConfig.fileNames.join(' or '),
        ),
      );
    }

    final raw = await configFile.readAsString();
    final yaml = loadYaml(raw);
    final version = yaml is Map ? yaml['version'] : null;
    if (version is! String || version.isEmpty) {
      throw CliException(
        translations.config.missingVersion(
          fileName: path.basename(configFile.path),
        ),
      );
    }

    return ProjectVersionInfo(
      version: SemanticVersion.parse(version),
      projectRoot: configFile.parent.path,
    );
  }
}
