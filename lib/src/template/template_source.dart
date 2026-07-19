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

import 'package:dio/dio.dart';
import 'package:mason_logger/mason_logger.dart';

import 'brick_loader.dart';
import 'semantic_version.dart';
import 'template_config.dart';

/// 模块级复用的 Dio 实例（用于 registry / 版本号拉取）。
///
/// Shared Dio instance for registry / version fetching.
final Dio _dio = Dio();

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
    return LocalBrickLoader(Directory(bricksDir));
  }

  // 2. 测试 / 调试：允许通过环境变量强制指定远程 URL。
  final overrideUrl = Platform.environment['FLUZER_TEMPLATE_ZIP_URL'];
  if (overrideUrl != null && overrideUrl.isNotEmpty) {
    return RemoteBrickLoader(zipUrl: overrideUrl);
  }
  // 3. 远程：从 registry 选出版本兼容的模板 zip URL（失败回退内置默认值）。
  final selected = await _selectTemplateZipUrl(logger: logger);
  return RemoteBrickLoader(
    zipUrl: selected.url,
    templateVersion: selected.version,
    mirrorFallback: githubMirrorFallback,
    logger: logger,
  );
}

/// 从 registry 选出版本兼容的模板 zip URL 及其版本号。
///
/// 遍历 `templates`，在所有 `minCliVersion <= [cliVersion]` 的记录中，
/// 选取 `version` 最大者的 `url` 与 `version`；无匹配或拉取失败时回退
/// [defaultTemplateZipUrl]，此时 `version` 为 `null`（缓存键退化为 URL 哈希）。
/// 当 GitHub 原始地址超时时，会尝试用 [githubMirrorFallback] 前缀重试。
///
/// Selects the version-compatible template zip URL (and its version) from the
/// registry. Falls back to [defaultTemplateZipUrl] with a `null` version.
Future<({String url, String? version})> _selectTemplateZipUrl({
  Logger? logger,
}) async {
  try {
    final json = await _fetchWithMirrorFallback(
      templateRegistryUrl,
      (body) => jsonDecode(body) as Map<String, dynamic>,
      logger: logger,
    );
    if (json == null) return (url: defaultTemplateZipUrl, version: defaultTemplateVersion);

    final templates = (json['templates'] as List?) ?? <dynamic>[];
    String? bestUrl;
    SemanticVersion? bestVersion;
    for (final item in templates) {
      final t = item as Map<String, dynamic>;
      final minCli = SemanticVersion.parse(t['minCliVersion'] as String? ?? '0.0.0');
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

/// 镜像前缀列表（按优先级依次尝试）。
///
/// 首项为配置项 [githubMirrorFallback]，其后为备用镜像；任一可达即胜出。
/// Ordered mirror prefixes (tried in order); the first reachable one wins.
const List<String> _mirrorPrefixes = <String>[
  githubMirrorFallback, // https://ghfast.top/
  'https://ghproxy.com/',
];

/// 尝试请求 [url]；GitHub 原始地址失败（超时 / DNS / 连接）时，依次用镜像前缀重试。
///
/// 直连使用较短超时（快速失败）；镜像为代理、响应更慢，使用更长超时（实测
/// ghfast.top 约 5s+，故给足预算，否则必然在 3s 内超时失败）。
/// 任意直连失败都会触发镜像重试，而非仅 [TimeoutException]。
///
/// 全部失败时返回 null，由调用方回退 [defaultTemplateZipUrl]。
Future<T?> _fetchWithMirrorFallback<T>(
  String url,
  T? Function(String body) parse, {
  Logger? logger,
}) async {
  // 1. 直连（短超时，快速失败）。
  try {
    final resp = await _getWithTimeout(url, const Duration(seconds: 5));
    if (resp != null) return parse(resp.data as String);
  } on Object {
    // 直连超时 / DNS / 连接失败：落入镜像重试。
  }

  // 2. 依次尝试镜像。
  logger?.warn('原始地址请求失败，尝试镜像下载。');
  for (final prefix in _mirrorPrefixes) {
    final mirrorUrl = '$prefix$url';
    try {
      final resp = await _getWithTimeout(mirrorUrl, const Duration(seconds: 15));
      if (resp != null) {
        logger?.info('镜像下载成功：$mirrorUrl');
        return parse(resp.data as String);
      }
      logger?.warn('镜像返回非 200，尝试下一个：$mirrorUrl');
    } on Object {
      logger?.warn('镜像请求失败，尝试下一个：$mirrorUrl');
    }
  }
  logger?.err('镜像下载也失败，回退到内置默认模板。');
  return null;
}

/// 带超时的 GET：仅当 HTTP 200 时返回响应，否则返回 null；网络 / 超时异常上抛。
///
/// Timeout-guarded GET: returns the response only on HTTP 200, else null;
/// network/timeout errors are rethrown.
Future<Response?> _getWithTimeout(String url, Duration timeout) async {
  final resp = await _dio.get<dynamic>(
    url,
    options: Options(
      responseType: ResponseType.plain,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      validateStatus: (_) => true,
    ),
  );
  if (resp.statusCode != 200) return null;
  return resp;
}
