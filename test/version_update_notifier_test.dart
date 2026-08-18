// 启动版本提示单元测试 / Unit tests for VersionUpdateNotifier.
//
// 通过 spy service 验证分支逻辑：缓存命中走 peek 快路径（不触网、不注册步骤），
// 缓存未命中则向 StepRunner 注册检查步骤，直到 runAll 才真正调用检查服务；
// 两条路径均不抛异常、不阻断调用方。
//
// 注意：notify 只负责「注册」，因此断言前必须先 await steps.runAll()，否则
// 缓存未命中分支的检查服务不会被调用。
//
// Uses a spy service to verify branching: a cache hit takes the peek fast
// path (no network call, no step registered), while a cache miss registers a
// step that only invokes the injected service once runAll executes.

import 'dart:convert';
import 'dart:io';

import 'package:fluzer/src/i18n/gen/strings.g.dart';
import 'package:fluzer/src/util/step_runner.dart';
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
  _SpyVersionCheckService(
    this._onCheck, {
    super.logger,
    super.cacheDir,
  });

  final Future<VersionCheckResult> Function() _onCheck;

  @override
  Future<VersionCheckResult> checkForUpdate({
    String packageName = cliPackageName,
  }) async =>
      _onCheck();
}

void main() {
  group('VersionUpdateNotifier.notify', () {
    late Directory cacheDir;
    late File cacheFile;

    setUp(() {
      cacheDir = Directory.systemTemp.createTempSync('vnotif_');
      cacheFile = File(p.join(cacheDir.path, 'version_check.json'));
    });

    tearDown(() {
      if (cacheDir.existsSync()) cacheDir.deleteSync(recursive: true);
    });

    test('缓存未命中 + 有更新 → runAll 后调用检查服务且不抛异常', () async {
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
        cacheDir: cacheDir,
      );
      final steps = StepRunner(
        logger: logger,
        translations: AppLocale.zh.buildSync(),
      );
      await VersionUpdateNotifier(
        logger: logger,
        translations: AppLocale.zh.buildSync(),
        versionCheckService: service,
      ).notify(steps);
      // notify 只注册步骤，此时尚未触网
      expect(called, isFalse);

      await steps.runAll();
      expect(called, isTrue);
    });

    test('缓存未命中 + 不可用 → runAll 后调用检查服务且不抛异常', () async {
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
        cacheDir: cacheDir,
      );
      final steps = StepRunner(
        logger: logger,
        translations: AppLocale.zh.buildSync(),
      );
      await VersionUpdateNotifier(
        logger: logger,
        translations: AppLocale.zh.buildSync(),
        versionCheckService: service,
      ).notify(steps);

      await steps.runAll();
      expect(called, isTrue);
    });

    test('缓存命中且有更新 → 走 peek 快路径，不注册步骤、不调用检查服务', () async {
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
        cacheDir: cacheDir,
      );
      final steps = StepRunner(
        logger: logger,
        translations: AppLocale.zh.buildSync(),
      );
      await VersionUpdateNotifier(
        logger: logger,
        translations: AppLocale.zh.buildSync(),
        versionCheckService: service,
      ).notify(steps);
      // 未注册任何步骤，runAll 为空操作，不会触网
      await steps.runAll();
      expect(called, isFalse);
    });

    test('缓存命中但不可用 → 不注册步骤、不调用检查服务', () async {
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
        cacheDir: cacheDir,
      );
      final steps = StepRunner(
        logger: logger,
        translations: AppLocale.zh.buildSync(),
      );
      await VersionUpdateNotifier(
        logger: logger,
        translations: AppLocale.zh.buildSync(),
        versionCheckService: service,
      ).notify(steps);
      await steps.runAll();
      expect(called, isFalse);
    });
  });
}
