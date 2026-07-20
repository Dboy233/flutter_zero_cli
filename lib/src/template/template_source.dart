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

import '../http/http_client.dart';
import 'brick_loader.dart';
import 'semantic_version.dart';
import 'template_config.dart';

/// 解析当前应使用的 [BrickLoader]。
///
/// [logger] 用于在镜像降级或下载时向控制台输出提示；测试时可注入。
///
/// 解析顺序见文件头注释。返回 [Future] 因为远程模式需异步拉取 registry。
///
/// Resolves the [BrickLoader] to use (async, see header for the order).
Future<BrickLoader> resolveBrickLoader({Logger? logger}) async {
  // 1. 本地开发 / 调试：显式指定本地 bricks 目录时优先使用。
  final bricksDir = Platform.environment['FLUZER_BRICKS_DIR'];
  if (bricksDir != null && bricksDir.isNotEmpty) {
    logger?.warn(
      '正在使用环境变量\'FLUZER_BRICKS_DIR\'执行的模板目录。 '
      'The template directory that is being executed using environment variables \'FLUZER_BRICKS_DIR\'',
    );
    logger?.warn('FLUZER_BRICKS_DIR = $bricksDir');
    return LocalBrickLoader(Directory(bricksDir));
  }

  // 2. 测试 / 调试：允许通过环境变量强制指定远程 URL。
  // url必须是发布的可以下载的github链接。
  final overrideUrl = Platform.environment['FLUZER_TEMPLATE_ZIP_URL'];
  if (overrideUrl != null && overrideUrl.isNotEmpty) {
    logger?.warn(
      '正在使用环境变量\'FLUZER_TEMPLATE_ZIP_URL\'模板下载地址。 '
      'The environment variable \'FLUZER_TEMPLATE_ZIP_URL\' template is being used to download the address.',
    );
    logger?.warn('FLUZER_TEMPLATE_ZIP_URL = $overrideUrl');
    return RemoteBrickLoader(
      zipUrl: overrideUrl,
      templateVersion: RegularUtils.extractVersion(overrideUrl),
    );
  }
  // 3. 远程：从 registry 选出版本兼容的模板 zip URL（失败回退内置默认值）。
  final httpClient = FluzerHttpClient(logger: logger);
  final selected = await _selectTemplateZipUrl(httpClient);
  logger?.info('使用远程模板地址：${selected.url}');
  return RemoteBrickLoader(
    zipUrl: selected.url,
    templateVersion: selected.version,
    httpClient: httpClient,
  );
}

/// 从 registry 选出版本兼容的模板 zip URL 及其版本号。
///
/// 遍历 `templates`，在所有 `minCliVersion <= [cliVersion]` 的记录中，
/// 选取 `version` 最大者的 `url` 与 `version`；无匹配或拉取失败时回退
/// [defaultTemplateZipUrl]，此时 `version` 为 `null`（缓存键退化为 URL 哈希）。
///
/// Selects the version-compatible template zip URL (and its version) from the
/// registry. Falls back to [defaultTemplateZipUrl] with a `null` version.
Future<({String url, String? version})> _selectTemplateZipUrl(
  FluzerHttpClient httpClient,
) async {
  try {
    final body = await httpClient.getText(templateRegistryUrl);
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
      final version = SemanticVersion.parse(t['version'] as String? ?? '0.0.0');
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
