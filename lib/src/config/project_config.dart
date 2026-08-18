import 'dart:io';

import 'package:fluzer/src/i18n/gen/strings.g.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// 项目配置加载。
///
/// 从当前目录向上查找配置文件
/// （[fileNames]：v1 `flutter_zero_config.yaml` 或 v2 `fluzer.yaml`），
/// 读取其中的 `version` / `template_name` / `package` 等字段。
/// 两种命名均可识别，向下兼容老项目。
///
/// CLI 不再依据模板版本做兼容性门禁（力求适配所有模板版本），
/// 故 [load] 只做「字段存在性」校验，不再拒绝特定版本，也不再校验
/// `lib/` 目录与 DI 注入点等内部结构。
///
///
/// Project configuration loader.
///
/// Walks up from the current directory looking for any of [fileNames]
/// (v1 `flutter_zero_config.yaml` or v2 `fluzer.yaml`), reading its
/// `version` / `template_name` / `package` fields. Both names are
/// recognized for backward compatibility with legacy projects.
///
/// The CLI no longer gates on the template version (it aims to support all
/// template versions), so [load] only validates field presence—it neither
/// rejects specific versions nor checks internal structure like `lib/`.
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

  /// 配置文件名（按查找优先级排序）。
  ///
  /// 均为合法配置名：v1 老项目使用 [_fileNameV1]，v2 起改用 [_fileNameV2]。
  /// [findConfigFile] / [findProjectRoot] / [load] 均兼容二者。
  ///
  /// Configuration file names (in lookup priority order).
  ///
  /// Both are valid config names: legacy projects use [_fileNameV1],
  /// v2+ uses [_fileNameV2]. [findConfigFile] / [findProjectRoot] / [load]
  /// recognize both.
  static const String _fileNameV1 = 'flutter_zero_config.yaml';
  static const String _fileNameV2 = 'fluzer.yaml';
  static const List<String> fileNames = [_fileNameV1, _fileNameV2];

  /// 查找并加载项目配置。
  ///
  /// [start] 为向上查找的起始目录，默认当前工作目录；测试可注入临时目录。
  /// [messages] 为本地化消息（默认中文），用于异常提示国际化。
  /// 返回配置；失败时抛出 [CliException]。
  ///
  /// 兼容 [fileNames] 中的任一文件名（v1/v2），读取命中文件的真实内容。
  ///
  /// Locates and loads the project configuration.
  ///
  /// [start] is the directory to walk up from (defaults to cwd).
  /// [messages] are the localized messages (defaults to Chinese) used for
  /// exception messages. Returns the config or throws [CliException].
  ///
  /// Recognizes any of [fileNames] (v1/v2) and reads the hit file's content.
  static Future<ProjectConfig> load({
    Directory? start,
    Translations? messages,
  }) async {
    final m = messages ?? AppLocale.zh.buildSync();
    final configFile = await findConfigFile(start ?? Directory.current);
    if (configFile == null) {
      throw CliException(m.config.notFound(fileName: fileNames.join('or')));
    }
    final root = configFile.parent;

    final raw = await configFile.readAsString();
    final yaml = loadYaml(raw);

    if (yaml is! Map) {
      throw CliException(m.config.rootNotMap(fileName: fileNames.join('or')));
    }

    final fileName = path.basename(configFile.path);
    final version = yaml['version'];
    if (version is! String || version.isEmpty) {
      throw CliException(m.config.missingVersion(fileName: fileName));
    }

    final templateName = yaml['template_name'];
    if (templateName is! String || templateName != 'flutter_zero') {
      throw CliException(m.config.templateNameInvalid(fileName: fileName));
    }

    // 读取 pubspec 的 package 名（gen-l10n 生成导入需要）。
    // 不校验 lib/ 目录与 DI 注入点等内部结构——CLI 适配所有模板版本，
    // 结构差异由各命令的版本适配器自行处理。
    final pubspecFile = File(path.join(root.path, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) {
      throw CliException(m.config.missingPubspec);
    }
    final pubspecYaml = loadYaml(await pubspecFile.readAsString());
    final packageName = pubspecYaml['name'];
    if (packageName is! String || packageName.isEmpty) {
      throw CliException(m.config.missingPubspecName);
    }

    return ProjectConfig(
      version: version,
      projectRoot: root.path,
      templateName: templateName,
      packageName: packageName,
    );
  }

  /// 从 [start] 向上查找命中任一配置文件 [fileNames] 的 [File]。
  ///
  /// 返回首个命中的配置文件；都未命中返回 `null`。
  /// 它是 [findProjectRoot] 与 [TemplateVersionReader] 的**单一文件定位事实源**，
  /// 避免重复查找逻辑（向上遍历策略只此一处维护）。
  ///
  /// Walks up from [start] looking for the first of [fileNames];
  /// returns the hit [File], or `null` if none found.
  /// This is the single source of truth for file location, shared by
  /// [findProjectRoot] and [TemplateVersionReader].
  static Future<File?> findConfigFile(Directory start) async {
    var current = start.absolute;
    while (true) {
      for (final name in fileNames) {
        final file = File(path.join(current.path, name));
        if (await file.exists()) return file;
      }

      final parent = current.parent;
      if (parent.path == current.path) return null;
      current = parent;
    }
  }

  /// 从 [start] 向上查找包含任一配置文件 [fileNames] 的目录。
  ///
  /// Walks up from [start] looking for any of [fileNames].
  static Future<Directory?> findProjectRoot(Directory start) async {
    final configFile = await findConfigFile(start);
    return configFile?.parent;
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

/// 目标目录已存在异常。
///
/// 由 `create` 在目标目录已存在时抛出。该目录**不是本次命令创建的**，
/// 属于用户既有数据，捕获方必须直接报错返回，**不得执行任何清理/删除**。
///
/// 因此它与普通 [CliException] 的区别不只是「失败原因」，
/// 更决定了失败后能否清理目标目录，捕获时务必单独处理。
///
/// Thrown by `create` when the target directory already exists.
///
/// The directory was **not created by this run** and belongs to the user, so
/// handlers must report the error and return without performing any
/// cleanup/deletion.
class DirExistsException extends CliException {
  /// 创建异常。
  ///
  /// Creates the exception.
  const DirExistsException(super.message);
}
