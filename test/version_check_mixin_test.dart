// VersionCheckMixin 单元测试 / Unit tests for VersionCheckMixin.
//
// 通过 spy service 验证分支逻辑：缓存命中走 peek 快路径（不触网），
// 缓存未命中才调用注入的检查服务；两条路径均不抛异常、不阻断调用方。
//
// Uses a spy service to verify branching: a cache hit takes the peek fast
// path (no network call), while a cache miss invokes the injected service.

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fluzer/src/i18n/gen/strings.g.dart';
import 'package:fluzer/src/version/version_check.dart';
import 'package:fluzer/src/version/version_check_mixin.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// 仅用于测试 mixin 行为的假命令。
///
/// Fake command used solely to exercise the mixin.
class _FakeCmd extends Command<int> with VersionCheckMixin {
  _FakeCmd(this._logger, this._versionCheckService);

  final Logger _logger;
  @override
  Logger get logger => _logger;

  final VersionCheckService _versionCheckService;
  @override
  VersionCheckService get versionCheckService => _versionCheckService;

  @override
  Translations get messages => AppLocale.zh.buildSync();

  @override
  String get name => 'fake';

  @override
  String get description => 'fake';

  @override
  Future<int> run() async => 0;
}

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
  group('VersionCheckMixin.ensureUpdateNotified', () {
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
      final cmd = _FakeCmd(
        Logger(level: Level.quiet),
        _SpyVersionCheckService(
          () async {
            called = true;
            return VersionCheckResult(
              current: '1.0.0',
              latest: '9.9.9',
              hasUpdate: true,
              packageName: 'fluzer',
            );
          },
          logger: Logger(level: Level.quiet),
        ),
      );
      await cmd.ensureUpdateNotified();
      expect(called, isTrue);
    });

    test('缓存未命中 + 不可用 → 调用检查服务且不抛异常', () async {
      var called = false;
      final cmd = _FakeCmd(
        Logger(level: Level.quiet),
        _SpyVersionCheckService(
          () async {
            called = true;
            return VersionCheckResult.unavailable(
              current: '1.0.0',
              packageName: 'fluzer',
            );
          },
          logger: Logger(level: Level.quiet),
        ),
      );
      await cmd.ensureUpdateNotified();
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
      final cmd = _FakeCmd(
        Logger(level: Level.quiet),
        _SpyVersionCheckService(
          () async {
            called = true;
            throw StateError('不应被调用 / should not be called');
          },
          logger: Logger(level: Level.quiet),
        ),
      );
      await cmd.ensureUpdateNotified();
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
      final cmd = _FakeCmd(
        Logger(level: Level.quiet),
        _SpyVersionCheckService(
          () async {
            called = true;
            throw StateError('不应被调用 / should not be called');
          },
          logger: Logger(level: Level.quiet),
        ),
      );
      await cmd.ensureUpdateNotified();
      expect(called, isFalse);
    });
  });
}
