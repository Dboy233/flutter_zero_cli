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

import 'package:fluzer/src/i18n/gen/strings.g.dart';
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
  TemplateSourceResolver({
    FluzerHttpClient? httpClient,
    Logger? logger,
    Translations? messages,
  }) : _httpClient = httpClient ?? FluzerHttpClient(logger: logger, messages: messages),
       _messages = messages ?? AppLocale.zh.buildSync(),
       _logger = logger ?? Logger();

  final FluzerHttpClient _httpClient;
  final Translations _messages;
  final Logger _logger;

  /// 解析当前应使用的 [BrickLoader]（详见文件头优先级说明）。
  ///
  /// [pinnedVersion] 非空时按精确版本钉死下载源（用于 `new`），
  /// 为 `null` 时按 CLI 版本选最新兼容版本（用于 `create`）。
  Future<BrickLoader> resolve({String? pinnedVersion}) async {
    // 1. 本地开发 / 调试：显式指定本地 bricks 目录时优先使用。
    final bricksDir = Platform.environment['FLUZER_BRICKS_DIR'];
    if (bricksDir != null && bricksDir.isNotEmpty) {
      _logger.detail(_messages.template.usingBricksDir);
      _logger.detail('FLUZER_BRICKS_DIR = $bricksDir');
      return LocalBrickLoader(Directory(bricksDir), messages: _messages);
    }

    // 2. 测试 / 调试：允许通过环境变量强制指定远程 URL。
    // url必须是发布的可以下载的github链接。
    final overrideUrl = Platform.environment['FLUZER_TEMPLATE_ZIP_URL'];
    if (overrideUrl != null && overrideUrl.isNotEmpty) {
      _logger.detail(_messages.template.usingZipUrl);
      _logger.detail('FLUZER_TEMPLATE_ZIP_URL = $overrideUrl');
      return RemoteBrickLoader(
        zipUrl: overrideUrl,
        templateVersion: VersionExtractor.extractVersion(overrideUrl),
        httpClient: _httpClient,
        messages: _messages,
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
      messages: _messages,
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
          version: VersionExtractor.extractVersion(defaultTemplateZipUrl),
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
        // 与「registry 不可达」分支（body == null）保持一致的缓存键：
        // 都从默认 URL 提取版本号，避免同一默认模板因回退路径不同而被
        // 缓存为两个不同的键、重复下载。
        return (
          url: defaultTemplateZipUrl,
          version: VersionExtractor.extractVersion(defaultTemplateZipUrl),
        );
      }
      return (url: bestUrl, version: bestVersion.toString());
    } on Object catch (e) {
      _logger.detail(_messages.template.registryFallback(error: e));
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
        throw CliException(_messages.template.registryUnavailable(version: version));
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
              _messages.template.registryMissingUrl(version: version),
            );
          }
          return (url: url, version: entryVersion);
        }
      }
      throw CliException(
        _messages.template.registryVersionNotFound(version: version),
      );
    } on CliException {
      rethrow;
    } on Object catch (e) {
      throw CliException(
        _messages.template.registryLocateFailed(version: version, error: e),
      );
    }
  }
}
