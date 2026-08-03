// 模板来源解析：根据环境变量 / 远程 registry 决定使用本地还是远程加载器。
//
// Template source resolution: chooses a local or remote loader based on
// environment variables and the remote template registry.
//
// 解析优先级（Priority）：
// 1. `FLUZER_BRICKS_DIR` 非空 → [LocalBrickLoader]（本地开发 / 调试）；
// 2. `FLUZER_TEMPLATE_ZIP_URL` 非空 → 强制使用该 URL 的 [RemoteBrickLoader]（测试 / 调试）；
// 3. 否则远程：从 [templateRegistryUrl] 拉取 registry，按 CLI 版本
//    （[cliVersion]）选出 `minCliVersion <= cliVersion` 中 `version` 最大者的
//    zip URL；拉取失败则回退 [defaultTemplateZipUrl]。
//
// 发布说明（Publishing）：
// - 发布前请将 [templateRegistryUrl] 与 [defaultTemplateZipUrl] 替换为真实地址。
// - registry 采用"兼容性桶"结构：每条记录代表一个 `minCliVersion` 级别下的最新
//   模板快照；模板发 PATCH/MINOR 只更新该记录的 `version`/`url`，发 MAJOR 才新增记录。
//   详见 `flutter_zero_template/template_registry.json` 与 `VERSIONING_CLI.md`。

import 'dart:convert';
import 'dart:io';

import 'package:fluzer/src/util/regular_utils.dart';
import 'package:mason_logger/mason_logger.dart';

import '../config/project_config.dart';
import '../config/template_config.dart';
import '../http/http_client.dart';
import '../util/semantic_version.dart';
import 'brick_loader.dart';

/// 模板来源解析器。
///
/// 封装「解析 [BrickLoader]」与「从 registry 选取模板 zip URL」两类职责，
/// 并将 [FluzerHttpClient] / [Logger] 改为构造注入，便于测试。
///
/// 文件头的解析优先级说明同样适用于 [resolve]。
class TemplateSourceResolver {
  /// 创建解析器。
  ///
  /// [httpClient] 不传时内部新建（与改造前默认行为一致）；
  /// [logger] 不传时使用默认 [Logger]，仅用于镜像降级 / 下载提示。
  TemplateSourceResolver({FluzerHttpClient? httpClient, Logger? logger})
    : _httpClient = httpClient ?? FluzerHttpClient(logger: logger),
      _logger = logger ?? Logger();

  final FluzerHttpClient _httpClient;
  final Logger _logger;

  /// 解析当前应使用的 [BrickLoader]（详见文件头优先级说明）。
  ///
  /// [pinnedVersion] 非空时按精确版本钉死下载源（用于 `new`），
  /// 为 `null` 时按 CLI 版本选最新兼容版本（用于 `create`）。
  Future<BrickLoader> resolve({String? pinnedVersion}) async {
    // 1. 本地开发 / 调试：显式指定本地 bricks 目录时优先使用。
    final bricksDir = Platform.environment['FLUZER_BRICKS_DIR'];
    if (bricksDir != null && bricksDir.isNotEmpty) {
      _logger.warn(
        '正在使用环境变量\'FLUZER_BRICKS_DIR\'执行的模板目录。 '
        'The template directory that is being executed using environment variables \'FLUZER_BRICKS_DIR\'',
      );
      _logger.warn('FLUZER_BRICKS_DIR = $bricksDir');
      return LocalBrickLoader(Directory(bricksDir));
    }

    // 2. 测试 / 调试：允许通过环境变量强制指定远程 URL。
    // url必须是发布的可以下载的github链接。
    final overrideUrl = Platform.environment['FLUZER_TEMPLATE_ZIP_URL'];
    if (overrideUrl != null && overrideUrl.isNotEmpty) {
      _logger.warn(
        '正在使用环境变量\'FLUZER_TEMPLATE_ZIP_URL\'模板下载地址。 '
        'The environment variable \'FLUZER_TEMPLATE_ZIP_URL\' template is being used to download the address.',
      );
      _logger.warn('FLUZER_TEMPLATE_ZIP_URL = $overrideUrl');
      return RemoteBrickLoader(
        zipUrl: overrideUrl,
        templateVersion: RegularUtils.extractVersion(overrideUrl),
      );
    }
    // 3. 远程：从 registry 选取模板 zip URL（失败回退内置默认值）。
    final selected = pinnedVersion == null
        ? await selectLatest()
        : await selectExact(pinnedVersion);
    return RemoteBrickLoader(
      zipUrl: selected.url,
      templateVersion: selected.version,
      httpClient: _httpClient,
    );
  }

  /// 从 registry 选出版本兼容的模板 zip URL 及其版本号。
  ///
  /// 遍历 `templates`，在所有 `minCliVersion <= [cliVersion]` 的记录中，
  /// 选取 `version` 最大者的 `url` 与 `version`；无匹配或拉取失败时回退
  /// [defaultTemplateZipUrl]，此时 `version` 为 `null`（缓存键退化为 URL 哈希）。
  Future<({String url, String? version})> selectLatest({
    String registryUrl = templateRegistryUrl,
  }) async {
    try {
      final body = await _httpClient.getText(registryUrl);
      if (body == null) {
        return (
          url: defaultTemplateZipUrl,
          version: RegularUtils.extractVersion(defaultTemplateZipUrl),
        );
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final templates = (json['templates'] as List?) ?? <dynamic>[];
      String? bestUrl;
      SemanticVersion? bestVersion;
      for (final item in templates) {
        final t = item as Map<String, dynamic>;
        final minCli = SemanticVersion.parse(
          t['minCliVersion'] as String? ?? '0.0.0',
        );
        if (minCli > SemanticVersion.parse(cliVersion)) continue;
        final version = SemanticVersion.parse(
          t['version'] as String? ?? '0.0.0',
        );
        if (bestVersion == null || version > bestVersion) {
          bestVersion = version;
          bestUrl = t['url'] as String?;
        }
      }
      if (bestUrl == null || bestVersion == null) {
        return (url: defaultTemplateZipUrl, version: null);
      }
      return (url: bestUrl, version: bestVersion.toString());
    } on Object {
      return (url: defaultTemplateZipUrl, version: null);
    }
  }

  /// 从 registry 选取指定精确 [version] 的模板 zip URL 及其版本号。
  ///
  /// 用于 `new` 命令按项目模板版本钉死下载源。找不到该版本条目或拉取失败时
  /// 抛出 [CliException]，提示用户升级 CLI 或检查 registry。
  Future<({String url, String? version})> selectExact(
    String version, {
    String registryUrl = templateRegistryUrl,
  }) async {
    try {
      final body = await _httpClient.getText(registryUrl);
      if (body == null) {
        throw CliException(
          '无法拉取模板 registry，无法定位模板版本 $version 的下载源。\n'
          'Could not fetch the template registry to locate download source '
          'for template version $version.',
        );
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final templates = (json['templates'] as List?) ?? <dynamic>[];
      for (final item in templates) {
        final t = item as Map<String, dynamic>;
        final entryVersion = t['version'] as String?;
        if (entryVersion == version) {
          final url = t['url'] as String?;
          if (url == null || url.isEmpty) {
            throw CliException(
              '模板版本 $version 在 registry 中缺少有效的 url 字段。\n'
              'Template version $version has no valid "url" in the registry.',
            );
          }
          return (url: url, version: entryVersion);
        }
      }
      throw CliException(
        '当前模板 registry 未收录版本 $version，请确认该模板版本已发布，'
        '或升级 fluzer 到支持该模板的版本。\n'
        'Template version $version was not found in the registry. '
        'Confirm it is published or upgrade fluzer.',
      );
    } on CliException {
      rethrow;
    } on Object catch (e) {
      throw CliException(
        '定位模板版本 $version 的下载源失败：$e\n'
        'Failed to locate download source for template version $version: $e',
      );
    }
  }
}
