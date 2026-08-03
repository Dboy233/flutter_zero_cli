// Brick 加载器：将 brick 名称解析为 Mason 可消费的 [Brick]。
//
// Brick loader: resolves a brick name into a Mason-consumable [Brick].
//
// - [LocalBrickLoader]：从本地目录读取（测试 / 开发阶段）。
// - [RemoteBrickLoader]：从 GitHub 下载 zip 解压后读取（线上版本）。

import 'dart:io';

import 'package:archive/archive.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

import '../config/project_config.dart';
import '../http/http_client.dart';
import '../config/template_config.dart';

/// Brick 加载器抽象。
///
/// Abstract brick loader.
abstract class BrickLoader {
  /// 根据 brick 名称加载并返回 [Brick]。
  ///
  /// Loads and returns a [Brick] for the given [brickName].
  Future<Brick> load(String brickName);
}

/// 本地 Brick 加载器。
///
/// [bricksRoot] 为包含各 brick 子目录的根目录，例如
/// `flutter_zero_template/bricks`，其中每个子目录即一个 brick。
///
/// Local brick loader. [bricksRoot] is the directory that contains one
/// subdirectory per brick, e.g. `flutter_zero_template/bricks`.
class LocalBrickLoader extends BrickLoader {
  /// 创建本地加载器。
  ///
  /// Creates a local loader.
  LocalBrickLoader(this.bricksRoot);

  /// 各 brick 子目录的根目录。
  ///
  /// Root directory containing one subdirectory per brick.
  final Directory bricksRoot;

  @override
  Future<Brick> load(String brickName) async {
    final dir = Directory(p.normalize(p.join(bricksRoot.path, brickName)));
    if (!dir.existsSync()) {
      throw CliException('本地模板不存在：\nLocal template not found: ${dir.path}');
    }
    return Brick.path(dir.path);
  }
}

/// 远程 Brick 加载器（线上版本）。
///
/// 从 [zipUrl] 下载 zip 并解压到缓存目录，加载其中 `bricks/<brickName>`
/// 目录。下载结果按模板版本号缓存（`template_<版本号>`），不同版本互不覆盖；
/// 若未知版本号（如环境变量覆盖 / 回退默认地址），则退化为按 [zipUrl] 哈希缓存。
/// 下载失败（直连与镜像均不可达）时抛出 [CliException]。
///
/// Remote brick loader (production). Downloads a zip from [zipUrl], extracts
/// it into a cache directory, and loads `bricks/<brickName>` from it.
/// Results are cached by template version (`template_<version>`); when the
/// version is unknown it falls back to a hash of [zipUrl].
class RemoteBrickLoader extends BrickLoader {
  /// 创建远程加载器。
  ///
  /// [zipUrl] 为模板仓库的 zip 下载链接（如 GitHub release / archive 链接）。
  /// [templateVersion] 为该模板的语义化版本号（来自 registry），用于生成可读的
  /// 缓存键 `template_<版本号>`；为 `null` 时退化为 [zipUrl] 哈希缓存。
  /// [httpClient] 为统一 HTTP 客户端（含镜像降级与下载进度）；省略时新建。
  ///
  /// Creates a remote loader. [zipUrl] is the zip download URL of the
  /// template repository (e.g. a GitHub release or archive link).
  RemoteBrickLoader({
    required this.zipUrl,
    this.templateVersion,
    FluzerHttpClient? httpClient,
    Directory? cacheDir,
    Logger? logger,
  }) : httpClient = httpClient ?? FluzerHttpClient(),
       cacheDir =
           cacheDir ??
           Directory(p.join(Directory.systemTemp.path, cacheDirName)),
       cacheKey = (templateVersion != null && templateVersion.isNotEmpty)
           ? 'template_$templateVersion'
           : 'fluzer_${zipUrl.hashCode.abs()}',
       logger = logger ?? Logger();

  /// 模板 zip 下载链接。
  ///
  /// Template zip download URL.
  final String zipUrl;

  /// 模板的语义化版本号（用于生成可读缓存键），未知时为 `null`。
  ///
  /// Semantic version of the template (for a readable cache key), or `null`.
  final String? templateVersion;

  /// 统一 HTTP 客户端（镜像降级 + 下载进度）。
  ///
  /// Unified HTTP client (mirror fallback + download progress).
  final FluzerHttpClient httpClient;

  /// 缓存根目录。
  ///
  /// Cache root directory.
  final Directory cacheDir;

  /// 缓存键：优先 `template_<版本号>`，未知版本时退化为 [zipUrl] 哈希。
  ///
  /// Cache key: prefers `template_<version>`, falls back to a [zipUrl] hash.
  final String cacheKey;

  /// log
  final Logger logger;

  @override
  Future<Brick> load(String brickName) async {
    final bricksRoot = await _resolveBricksRoot();
    final dir = Directory(p.join(bricksRoot.path, brickName));
    if (!dir.existsSync()) {
      throw CliException(
        '远程模板中未找到 brick：$brickName\n'
        'Brick not found in remote templates: $brickName',
      );
    }
    return Brick.path(dir.path);
  }

  /// 确保 zip 已下载并解压，返回其中的 `bricks` 目录。
  ///
  /// Ensures the zip is downloaded and extracted, returning the `bricks`
  /// directory inside it.
  Future<Directory> _resolveBricksRoot() async {
    final extractDir = Directory(p.join(cacheDir.path, cacheKey));
    if (extractDir.existsSync()) {
      final cacheBricksDir = _findBricksDir(extractDir);
      logger.info('使用缓存模板/Use caching templates:$cacheBricksDir');
      return cacheBricksDir;
    }

    final downloaded = await httpClient.downloadFile(zipUrl);
    if (downloaded == null) {
      throw CliException(
        '模板下载失败（直连与镜像均不可达）：\n'
        'Failed to download templates: $zipUrl',
      );
    }
    try {
      final bytes = await downloaded.file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        final filePath = p.normalize(p.join(extractDir.path, file.name));
        // 防御 Zip Slip：拒绝逃逸出解压目录的条目。
        if (!p.isWithin(extractDir.path, filePath)) {
          throw CliException(
            '模板 zip 包含非法路径：${file.name}\n'
            'Template zip contains an illegal path: ${file.name}',
          );
        }
        if (file.isFile) {
          final outFile = File(filePath);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }
    } finally {
      // 解压完成（无论成败）后清理临时 zip，避免 systemTemp 堆积。
      await downloaded.dispose();
    }
    final bricksDir = _findBricksDir(extractDir);
    return bricksDir;
  }

  /// 在解压树中定位 `bricks` 目录（兼容 zip 顶层多一层仓库目录的情况）。
  ///
  /// Locates the `bricks` directory within the extracted tree, tolerating a
  /// top-level repository folder created by some zip archives.
  Directory _findBricksDir(Directory root) {
    final direct = Directory(p.join(root.path, 'bricks'));
    if (direct.existsSync()) return direct;
    for (final entity in root.listSync(recursive: true)) {
      if (entity is Directory && p.basename(entity.path) == 'bricks') {
        return entity;
      }
    }
    throw CliException(
      '远程模板中未找到 bricks 目录。\n'
      'No "bricks" directory found in remote templates.',
    );
  }
}
