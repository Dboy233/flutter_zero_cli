import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;

/// 模板渲染引擎，负责从 `.tmpl` 文件加载并渲染。
///
/// Template rendering engine that loads `.tmpl` files and renders them.
class TemplateEngine {
  /// 创建模板引擎。
  ///
  /// [templatesDir] 是存放 `.tmpl` 文件的根目录。
  ///
  /// Creates a template engine.
  ///
  /// [templatesDir] is the root directory containing `.tmpl` files.
  TemplateEngine({required this.templatesDir});

  /// 存放 `.tmpl` 文件的根目录。
  ///
  /// Root directory containing `.tmpl` files.
  final Directory templatesDir;

  /// 通过 `package:fluzer` 解析默认模板目录。
  ///
  /// [version] 为项目模板版本号（如 `1.0.0`），解析结果会定位到
  /// `templates/v<major>` 目录。
  ///
  /// Resolves the default template directory from the package root.
  ///
  /// [version] is the project template version (e.g. `1.0.0`);
  /// the result points to `templates/v<major>`.
  static Future<Directory> resolvePackageTemplatesDirectory({
    String version = '1.0.0',
  }) async {
    final libFileUri = await Isolate.resolvePackageUri(
      Uri.parse('package:fluzer/fluzer.dart'),
    );
    if (libFileUri == null) {
      throw StateError(
        '无法解析 fluzer 包路径，模板目录定位失败。\n'
        'Could not resolve fluzer package path; '
        'template directory lookup failed.',
      );
    }

    final libFile = File.fromUri(libFileUri);
    final packageRoot = libFile.parent.parent;
    final versionDir = 'v${version.split('.').first}';
    return Directory(path.join(packageRoot.path, 'templates', versionDir));
  }

  /// 加载相对 [templatesDir] 的模板文件。
  ///
  /// [relativePath] 使用 `/` 分隔，例如 `feature/module.tmpl`。
  ///
  /// Loads a template file relative to [templatesDir].
  ///
  /// [relativePath] uses `/` separators, e.g. `feature/module.tmpl`.
  Future<String> load(String relativePath) async {
    final file = File(path.join(templatesDir.path, relativePath));
    if (!await file.exists()) {
      throw StateError('模板文件不存在 / Template file not found: ${file.path}');
    }
    return file.readAsString();
  }

  /// 同步加载模板文件（适用于同步方法中调用）。
  ///
  /// [relativePath] 使用 `/` 分隔，例如 `features/module/module_module.dart.tmpl`。
  ///
  ///
  /// Synchronously loads a template file (for use in sync methods).
  ///
  /// [relativePath] uses `/` separators, e.g.
  /// `features/module/module_module.dart.tmpl`.
  String loadSync(String relativePath) {
    final file = File(path.join(templatesDir.path, relativePath));
    if (!file.existsSync()) {
      throw StateError('模板文件不存在 / Template file not found: ${file.path}');
    }
    return file.readAsStringSync();
  }

  /// 渲染模板字符串，替换 `{{key}}` 占位符。
  ///
  /// Renders a template string by replacing `{{key}}` placeholders.
  String render(String template, Map<String, String> vars) {
    var result = template;
    for (final entry in vars.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    return result;
  }

  /// 将 snake_case 转为 PascalCase。
  ///
  /// Example: `user_profile` → `UserProfile`.
  String toPascalCase(String input) {
    return input
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join();
  }

  /// 将 snake_case 转为 camelCase。
  ///
  /// Example: `user_profile` → `userProfile`.
  String toCamelCase(String input) {
    final pascal = toPascalCase(input);
    if (pascal.isEmpty) return pascal;
    return '${pascal[0].toLowerCase()}${pascal.substring(1)}';
  }
}
