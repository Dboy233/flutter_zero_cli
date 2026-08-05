import 'dart:convert';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:fluzer/src/config/template_config.dart';
import 'package:fluzer/src/version/version_check.dart';
import 'package:test/test.dart';

void main() {
  group('VersionCacheEntry', () {
    test('fromJson 创建条目', () {
      final entry = VersionCacheEntry.fromJson({
        'latest': '1.2.0',
        'available': true,
        'checkedAt': 1234567890,
      });
      expect(entry.latest, '1.2.0');
      expect(entry.available, true);
      expect(entry.checkedAt, 1234567890);
    });

    test('toJson 序列化', () {
      final entry = VersionCacheEntry(
        latest: '1.2.0',
        available: false,
        checkedAt: 1234567890,
      );
      final json = entry.toJson();
      expect(json['latest'], '1.2.0');
      expect(json['available'], false);
      expect(json['checkedAt'], 1234567890);
    });

    test('fromJson → toJson 往返', () {
      final original = {
        'latest': '2.0.0',
        'available': true,
        'checkedAt': 9876543210,
      };
      final entry = VersionCacheEntry.fromJson(original);
      final back = entry.toJson();
      expect(back['latest'], '2.0.0');
      expect(back['available'], true);
      expect(back['checkedAt'], 9876543210);
    });

    test('fromJson 缺字段用默认值', () {
      final entry = VersionCacheEntry.fromJson(<String, dynamic>{});
      expect(entry.latest, isNull);
      expect(entry.available, true);
      expect(entry.checkedAt, 0);
    });
  });

  group('peekCachedUpdate', () {
    late String cacheFile;
    late VersionCheckService service;

    setUp(() {
      service = VersionCheckService(logger: Logger(level: Level.quiet));
      cacheFile =
          '${Directory.systemTemp.path}/$cacheDirName/version_check.json';
      final dir = Directory('${Directory.systemTemp.path}/$cacheDirName');
      if (dir.existsSync()) {
        final file = File(cacheFile);
        if (file.existsSync()) file.deleteSync();
      }
    });

    tearDown(() {
      final file = File(cacheFile);
      if (file.existsSync()) file.deleteSync();
    });

    test('缓存文件不存在返回 null', () {
      expect(service.peekCachedUpdate(), isNull);
    });

    test('缓存命中且无更新返回 hasUpdate=false', () {
      _writeTestCache({
        'test_pkg': {
          'latest': '1.1.3',
          'available': true,
          'checkedAt': DateTime.now().millisecondsSinceEpoch,
        },
      });
      final result = service.peekCachedUpdate(packageName: 'test_pkg');
      expect(result, isNotNull);
      expect(result!.hasUpdate, false);
      expect(result.available, true);
      expect(result.current, cliVersion);
    });

    test('缓存命中且有更新返回 hasUpdate=true', () {
      _writeTestCache({
        'test_pkg': {
          'latest': '999.0.0',
          'available': true,
          'checkedAt': DateTime.now().millisecondsSinceEpoch,
        },
      });
      final result = service.peekCachedUpdate(packageName: 'test_pkg');
      expect(result, isNotNull);
      expect(result!.hasUpdate, true);
      expect(result.latest, '999.0.0');
      expect(result.available, true);
    });

    test('可用缓存超过 24h 返回 null', () {
      final old = DateTime.now().millisecondsSinceEpoch -
          (25 * 60 * 60 * 1000); // 25h
      _writeTestCache({
        'test_pkg': {
          'latest': '999.0.0',
          'available': true,
          'checkedAt': old,
        },
      });
      expect(service.peekCachedUpdate(packageName: 'test_pkg'), isNull);
    });

    test('不可用缓存未超 10min 返回 unavailable', () {
      final recent = DateTime.now().millisecondsSinceEpoch -
          (5 * 60 * 1000); // 5min
      _writeTestCache({
        'test_pkg': {
          'latest': null,
          'available': false,
          'checkedAt': recent,
        },
      });
      final result = service.peekCachedUpdate(packageName: 'test_pkg');
      expect(result, isNotNull);
      expect(result!.available, false);
      expect(result.hasUpdate, false);
    });

    test('不可用缓存超过 10min 返回 null', () {
      final old = DateTime.now().millisecondsSinceEpoch -
          (15 * 60 * 1000); // 15min
      _writeTestCache({
        'test_pkg': {
          'latest': null,
          'available': false,
          'checkedAt': old,
        },
      });
      expect(service.peekCachedUpdate(packageName: 'test_pkg'), isNull);
    });
  });
}

void _writeTestCache(Map<String, dynamic> data) {
  final dir = Directory('${Directory.systemTemp.path}/$cacheDirName');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  File('${dir.path}/version_check.json').writeAsStringSync(jsonEncode(data));
}
