// `cache` 命令：管理本地模板缓存（list / clean）。
//
// 缓存根目录为 `系统临时目录/fluzer_cache`，其中每个子目录是一份按版本
// 隔离的模板缓存（`template_<版本号>` 或 `fluzer_<url 哈希>`）。

import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fluzer/src/i18n/gen/strings.g.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../../commands/base_command.dart';
import '../../commands/cache/cache_context.dart';
import '../../config/template_config.dart';

/// `cache` 命令：查看 / 清空本地模板缓存。
///
/// `cache` command: lists or clears the local template cache.
class CacheCommand extends BaseCommand<CacheCommandContext> {
  /// 创建 CacheCommand 实例。
  ///
  /// [logger] / [translations] / [versionCheckService] 由外部必填注入（[Fluzer]
  /// 统一提供；本命令不 opt-in 启动提示，但仍持有以避免 [BaseCommand] 重复默认值）；
  /// [cacheDir] 可选，省略时回退到系统临时目录。
  ///
  /// Creates a CacheCommand instance.
  ///
  /// [logger] / [translations] / [versionCheckService] are required (injected by
  /// [Fluzer]); this command does not opt into the startup notice but still holds
  /// the service to avoid a base default; [cacheDir] defaults to the system temp.
  CacheCommand({
    required super.logger,
    required super.versionCheckService,
    Directory? cacheDir,
    required super.translations,
  })  : _cacheDir = cacheDir ??
            Directory(p.join(Directory.systemTemp.path, cacheDirName)) {
    addSubcommand(_CacheListCommand(logger, _cacheDir, translations));
    addSubcommand(_CacheCleanCommand(logger, _cacheDir, translations));
  }

  final Directory _cacheDir;

  @override
  String get name => 'cache';

  @override
  String get description => translations.cache.description;

  @override
  Future<CacheCommandContext> buildContext(ArgResults args) async =>
      const CacheCommandContext();

  @override
  Future<int> execute(CacheCommandContext ctx) async => 0;
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
    if (!await _cacheDir.exists()) {
      _logger.info(_messages.cache.noneNotExist);
      return 0;
    }

    final versions = (await _cacheDir.list().toList())
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
    if (!await _cacheDir.exists()) {
      _logger.info(_messages.cache.cleanNotExist);
      return 0;
    }

    final versionDirs =
        (await _cacheDir.list().toList()).whereType<Directory>().toList();
    if (versionDirs.isEmpty) {
      _logger.info(_messages.cache.cleanNone);
      return 0;
    }

    var removed = 0;
    for (final dir in versionDirs) {
      try {
        await dir.delete(recursive: true);
        removed++;
      } on Object catch (e) {
        _logger.warn(_messages.cache.deleteFailed(name: p.basename(dir.path), error: e));
      }
    }
    _logger.success(_messages.cache.cleared(count: removed));
    return 0;
  }
}
