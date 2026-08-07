// `cache` 命令：管理本地模板缓存（list / clean）。
//
// `cache` command: manages the local template cache (list / clean).
//
// 缓存根目录为 `系统临时目录/fluzer_cache`，其中每个子目录是一份按版本
// 隔离的模板缓存（`template_<版本号>` 或 `fluzer_<url 哈希>`）。

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fluzer/src/i18n/gen/strings.g.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../config/template_config.dart';

/// `cache` 命令：查看 / 清空本地模板缓存。
///
/// `cache` command: lists or clears the local template cache.
class CacheCommand extends Command<int> {
  /// 创建 CacheCommand 实例。
  ///
  /// Creates a CacheCommand instance.
  CacheCommand({
    Logger? logger,
    Directory? cacheDir,
    Translations? messages,
  })  : _logger = logger ?? Logger(),
        _messages = messages ?? AppLocale.zh.buildSync(),
        _cacheDir = cacheDir ??
            Directory(p.join(Directory.systemTemp.path, cacheDirName)) {
    addSubcommand(_CacheListCommand(_logger, _cacheDir, _messages));
    addSubcommand(_CacheCleanCommand(_logger, _cacheDir, _messages));
  }

  final Logger _logger;
  final Translations _messages;
  final Directory _cacheDir;

  @override
  String get name => 'cache';

  @override
  String get description => _messages.cache.description;
}

/// `cache list`：列出所有已缓存的模板版本。
class _CacheListCommand extends Command<int> {
  _CacheListCommand(this._logger, this._cacheDir, this._messages);

  final Logger _logger;
  final Translations _messages;
  final Directory _cacheDir;

  @override
  String get name => 'list';

  @override
  String get description => _messages.cache.listDescription;

  @override
  Future<int> run() async {
    if (!_cacheDir.existsSync()) {
      _logger.info(_messages.cache.noneNotExist);
      return 0;
    }

    final versions = _cacheDir
        .listSync()
        .whereType<Directory>()
        .map((d) => p.basename(d.path))
        .toList()
      ..sort();

    if (versions.isEmpty) {
      _logger.info(_messages.cache.noneVersions);
      return 0;
    }

    _logger.info(_messages.cache.directory(path: _cacheDir.path));
    for (final v in versions) {
      _logger.info('  $v');
    }
    return 0;
  }
}

/// `cache clean`：清空所有缓存的模板版本（保留版本检查等非目录缓存文件）。
class _CacheCleanCommand extends Command<int> {
  _CacheCleanCommand(this._logger, this._cacheDir, this._messages);

  final Logger _logger;
  final Translations _messages;
  final Directory _cacheDir;

  @override
  String get name => 'clean';

  @override
  String get description => _messages.cache.cleanDescription;

  @override
  Future<int> run() async {
    if (!_cacheDir.existsSync()) {
      _logger.info(_messages.cache.cleanNotExist);
      return 0;
    }

    final versionDirs = _cacheDir.listSync().whereType<Directory>().toList();
    if (versionDirs.isEmpty) {
      _logger.info(_messages.cache.cleanNone);
      return 0;
    }

    var removed = 0;
    for (final dir in versionDirs) {
      try {
        dir.deleteSync(recursive: true);
        removed++;
      } on Object catch (e) {
        _logger.warn(_messages.cache.deleteFailed(name: p.basename(dir.path), error: e));
      }
    }
    _logger.success(_messages.cache.cleared(count: removed));
    return 0;
  }
}
