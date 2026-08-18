// 启动版本提示单元测试 / Unit tests for ensureUpdateNotified.
//
// 通过 spy service 验证分支逻辑：缓存命中走 peek 快路径（不触网），
// 缓存未命中才调用注入的检查服务；两条路径均不抛异常、不阻断调用方。
//
// 原 [VersionCheckMixin.ensureUpdateNotified] 已抽离为独立顶层函数，本文件
// 随之改为测试该函数。
//
// Uses a spy service to verify branching: a cache hit takes the peek fast
// path (no network call), while a cache miss invokes the injected service.

import 'dart:convert';
import 'dart:io';

import 'package:fluzer/src/i18n/gen/strings.g.dart';
import 'package:fluzer/src/version/version_check.dart';
import 'package:fluzer/src/version/version_update_notifier.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// spy 版版本检查服务，可注入回调追踪调用，同时保留真实缓存读写。
///
/// Spy version-check service that injects a callback for call tracking
/// while keeping real cache I/O from the parent class.
class _SpyVersionCheckService extends VersionCheckService {
  _SpyVersionCheckService(this._onCheck, {super.logger});

  final Future<VersionCheckResult> Function() _onCheck;

  @override
  Future<VersionCheckResult> checkForUpdate({
    String packageName = cliPackageName,
  }) async =>
      _onCheck();
}

void main() {
  group('ensureUpdateNotified', () {
    late Directory cacheDir;
    late File cacheFile;

    setUp(() {
      cacheDir = Directory(p.join(Directory.systemTemp.path, 'fluzer_cache'));
      cacheFile = File(p.join(cacheDir.path, 'version_check.json'));
      if (cacheFile.existsSync()) cacheFile.deleteSync();
    });

    tearDown(() {
      if (cacheFile.existsSync()) cacheFile.deleteSync();
    });

    test('缓存未命中 + 有更新 → 调用检查服务且不抛异常', () async {
      var called = false;
      final logger = Logger(level: Level.quiet);
      final service = _SpyVersionCheckService(
        () async {
          called = true;
          return VersionCheckResult(
            current: '1.0.0',
            latest: '9.9.9',
            hasUpdate: true,
            packageName: 'fluzer',
          );
        },
        logger: logger,
      );
      await ensureUpdateNotified(
        logger: logger,
        translations: AppLocale.zh.buildSync(),
        versionCheckService: service,
      );
      expect(called, isTrue);
    });

    test('缓存未命中 + 不可用 → 调用检查服务且不抛异常', () async {
      var called = false;
      final logger = Logger(level: Level.quiet);
      final service = _SpyVersionCheckService(
        () async {
          called = true;
          return VersionCheckResult.unavailable(
            current: '1.0.0',
            packageName: 'fluzer',
          );
        },
        logger: logger,
      );
      await ensureUpdateNotified(
        logger: logger,
        translations: AppLocale.zh.buildSync(),
        versionCheckService: service,
      );
      expect(called, isTrue);
    });

    test('缓存命中且有更新 → 走 peek 快路径，不调用检查服务', () async {
      cacheDir.createSync(recursive: true);
      cacheFile.writeAsStringSync(jsonEncode({
        'fluzer': {
          'latest': '9.9.9',
          'available': true,
          'checkedAt': DateTime.now().millisecondsSinceEpoch,
        },
      }));
      var called = false;
      final logger = Logger(level: Level.quiet);
      final service = _SpyVersionCheckService(
        () async {
          called = true;
          throw StateError('不应被调用 / should not be called');
        },
        logger: logger,
      );
      await ensureUpdateNotified(
        logger: logger,
        translations: AppLocale.zh.buildSync(),
        versionCheckService: service,
      );
      expect(called, isFalse);
    });

    test('缓存命中但不可用 → 不调用检查服务', () async {
      cacheDir.createSync(recursive: true);
      cacheFile.writeAsStringSync(jsonEncode({
        'fluzer': {
          'latest': null,
          'available': false,
          'checkedAt': DateTime.now().millisecondsSinceEpoch,
        },
      }));
      var called = false;
      final logger = Logger(level: Level.quiet);
      final service = _SpyVersionCheckService(
        () async {
          called = true;
          throw StateError('不应被调用 / should not be called');
        },
        logger: logger,
      );
      await ensureUpdateNotified(
        logger: logger,
        translations: AppLocale.zh.buildSync(),
        versionCheckService: service,
      );
      expect(called, isFalse);
    });
  });
}
