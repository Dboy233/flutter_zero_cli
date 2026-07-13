// Brick 加载器：将 brick 名称解析为 Mason 可消费的 [Brick]。
//
// Brick loader: resolves a brick name into a Mason-consumable [Brick].
//
// - [LocalBrickLoader]：从本地目录读取（测试 / 开发阶段）。
// - [RemoteBrickLoader]：从 GitHub 下载 zip 解压后读取（线上版本）。

import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

import '../config/project_config.dart';

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
      throw CliException(
        '本地模板不存在：\nLocal template not found: ${dir.path}',
      );
    }
    return Brick.path(dir.path);
  }
}

/// 远程 Brick 加载器（线上版本）。
///
/// 从 [zipUrl] 下载 zip 并解压到缓存目录，加载其中 `bricks/<brickName>`
/// 目录。下载结果按 [zipUrl] 哈希缓存，不同版本不会相互覆盖。
///
/// Remote brick loader (production). Downloads a zip from [zipUrl], extracts
/// it into a cache directory, and loads `bricks/<brickName>` from it.
/// Results are cached by a hash of [zipUrl] so different versions don't clash.
class RemoteBrickLoader extends BrickLoader {
  /// 创建远程加载器。
  ///
  /// [zipUrl] 为模板仓库的 zip 下载链接（如 GitHub release / archive 链接）。
  ///
  /// Creates a remote loader. [zipUrl] is the zip download URL of the
  /// template repository (e.g. a GitHub release or archive link).
  RemoteBrickLoader({
    required this.zipUrl,
    Directory? cacheDir,
  }) : cacheDir =
            cacheDir ?? Directory(p.join(Directory.systemTemp.path, 'fluzer_cache')),
        cacheKey = 'fluzer_${zipUrl.hashCode.abs()}';

  /// 模板 zip 下载链接。
  ///
  /// Template zip download URL.
  final String zipUrl;

  /// 缓存根目录。
  ///
  /// Cache root directory.
  final Directory cacheDir;

  /// 基于 [zipUrl] 的缓存键（避免不同版本相互覆盖）。
  ///
  /// Cache key derived from [zipUrl].
  final String cacheKey;

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
    if (extractDir.existsSync()) return _findBricksDir(extractDir);

    final response = await http.get(Uri.parse(zipUrl));
    if (response.statusCode != 200) {
      throw CliException(
        '模板下载失败（HTTP ${response.statusCode}）：\n'
        'Failed to download templates: $zipUrl',
      );
    }

    final archive = ZipDecoder().decodeBytes(response.bodyBytes);
    for (final file in archive) {
      final filePath = p.join(extractDir.path, file.name);
      if (file.isFile) {
        final outFile = File(filePath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      }
    }
    return _findBricksDir(extractDir);
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
