// 版本检查：查询 pub.dev 判断 CLI 是否有新版本可用。
//
// Version check: queries pub.dev to determine if a newer CLI version exists.
//
// - CLI 自身版本来自 [cliVersion]（与 pubspec.yaml 同步）。
// - 默认查询包名 `fluzer`；未发布时 pub.dev 返回 404，降级为「不可用」。
// - 结果按包名缓存 24h，避免每次启动都打 API。
// - 网络异常 / 限流 / 包不存在均静默降级，不影响主流程。

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fluzer/src/i18n/gen/strings.g.dart';
import 'package:mason_logger/mason_logger.dart';

import '../config/template_config.dart';
import '../util/semantic_version.dart';

/// 默认查询的 pub.dev 包名 / Default pub.dev package name to check.
const String cliPackageName = 'fluzer';

// ---------------------------------------------------------------------------
// 值对象 / Value objects
// ---------------------------------------------------------------------------

/// 版本检查结果 / Result of a version check.
class VersionCheckResult {
  const VersionCheckResult({
    required this.current,
    required this.latest,
    required this.hasUpdate,
    required this.packageName,
    this.available = true,
  });

  /// 当前安装的版本 / Installed version.
  final String current;

  /// 远端最新版本 / Latest remote version.
  final String latest;

  /// 是否存在可更新版本 / Whether a newer version exists.
  final bool hasUpdate;

  /// 被查询的包名 / Queried package name.
  final String packageName;

  /// API 是否可达 / 包是否存在（404 视为不可达）。
  /// Whether the API was reachable and the package exists.
  final bool available;

  /// 不可用时（包未发布 / 网络异常）的降级结果。
  /// Fallback result when the check is unavailable.
  factory VersionCheckResult.unavailable({
    required String current,
    required String packageName,
  }) => VersionCheckResult(
    current: current,
    latest: current,
    hasUpdate: false,
    packageName: packageName,
    available: false,
  );
}

/// 单条版本缓存条目。
///
/// A single cached version-check entry for one package.
class VersionCacheEntry {
  const VersionCacheEntry({
    this.latest,
    this.available = true,
    required this.checkedAt,
  });

  /// 远端最新版本；null 表示本次检查不可达 / Cached latest; null = unavailable.
  final String? latest;

  /// API 是否可达 / Whether the API was reachable.
  final bool available;

  /// 缓存时间戳（毫秒）/ Cached timestamp in milliseconds.
  final int checkedAt;

  factory VersionCacheEntry.fromJson(Map<String, dynamic> json) {
    return VersionCacheEntry(
      latest: json['latest'] as String?,
      available: json['available'] as bool? ?? true,
      checkedAt: json['checkedAt'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'latest': latest,
    'available': available,
    'checkedAt': checkedAt,
  };
}

// ---------------------------------------------------------------------------
// 服务类 / Service
// ---------------------------------------------------------------------------

/// 版本检查服务——外观模式封装缓存、网络查询与版本比较。
///
/// [logger] 与 [dio] 通过构造注入，满足依赖倒置（DIP）；实例化后所有方法
/// 均可直接访问共享依赖，无需逐方法传递参数。
///
/// Facade that wraps cache I/O, pub.dev querying, and version comparison.
/// [logger] and [dio] are constructor-injected (DIP); once constructed, every
/// method has direct access to the shared dependencies.
class VersionCheckService {
  VersionCheckService({
    Logger? logger,
    Dio? dio,
    Translations? messages,
  })  : _logger = logger ?? Logger(),
        _dio = dio ?? Dio(),
        _messages = messages ?? AppLocale.zh.buildSync();

  final Logger _logger;
  final Dio _dio;
  final Translations _messages;

  // ---- 公共 API ----

  /// 同步读取缓存中的版本检查结果（不触网）。
  ///
  /// 仅当缓存存在且未过期时返回结果；否则返回 null，调用方需自行发起网络检查。
  ///
  /// Synchronous read of the cached version check (no network).
  VersionCheckResult? peekCachedUpdate({String packageName = cliPackageName}) {
    final entry = _readCache()[packageName];
    if (entry == null) return null;
    // 可用结果缓存 24h；不可用结果（包未发布 / 网络异常）只缓存 10 分钟。
    final stale = entry.available
        ? _isStale(entry.checkedAt)
        : _isRecentUnavailable(entry.checkedAt);
    if (stale) {
      _logger.detail(
        _messages.versionCheck.detailCacheExpired(packageName: packageName),
      );
      return null;
    }
    if (!entry.available) {
      _logger.detail(
        _messages.versionCheck.detailCacheUnavailable(packageName: packageName),
      );
      return VersionCheckResult.unavailable(
        current: cliVersion,
        packageName: packageName,
      );
    }
    final latest = entry.latest ?? cliVersion;
    final hasUpdate =
        SemanticVersion.parse(latest) > SemanticVersion.parse(cliVersion);
    _logger.detail(
      _messages.versionCheck.detailCacheHit(
        packageName: packageName,
        latest: latest,
        hasUpdate: hasUpdate,
      ),
    );
    return VersionCheckResult(
      current: cliVersion,
      latest: latest,
      hasUpdate: hasUpdate,
      packageName: packageName,
    );
  }

  /// 检查指定包是否有新版本。
  ///
  /// 先读缓存（[peekCachedUpdate]），命中直接返回；否则查询 pub.dev。
  ///
  /// Checks whether a newer version exists on pub.dev.
  /// Reads the cache first; falls back to a network request when stale/missing.
  Future<VersionCheckResult> checkForUpdate({
    String packageName = cliPackageName,
  }) async {
    final cached = peekCachedUpdate(packageName: packageName);
    if (cached != null) {
      _logger.detail(
        _messages.versionCheck.detailUsingCached(packageName: packageName),
      );
      return cached;
    }

    try {
      _logger.detail(
        _messages.versionCheck.detailCheckingPubdev(packageName: packageName),
      );
      final response = await _dio.get<dynamic>(
        'https://pub.dev/api/packages/$packageName',
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 3),
          validateStatus: (_) => true,
        ),
      );
      if (response.statusCode != 200) {
        _logger.detail(
          _messages.versionCheck.detailPubdevStatus(
            statusCode: response.statusCode ?? 0,
            packageName: packageName,
          ),
        );
        _writeCache(packageName, null);
        return VersionCheckResult.unavailable(
          current: cliVersion,
          packageName: packageName,
        );
      }
      final data = response.data as Map<String, dynamic>;
      final latest = (data['latest']?['version'] as String?) ?? cliVersion;
      final hasUpdate =
          SemanticVersion.parse(latest) > SemanticVersion.parse(cliVersion);
      _logger.detail(
        _messages.versionCheck.detailPubdevResult(
          packageName: packageName,
          current: cliVersion,
          latest: latest,
          hasUpdate: hasUpdate,
        ),
      );
      _writeCache(packageName, latest);
      return VersionCheckResult(
        current: cliVersion,
        latest: latest,
        hasUpdate: hasUpdate,
        packageName: packageName,
      );
    } on Object catch (e) {
      _logger.detail(
        _messages.versionCheck.detailCheckFailed(
          packageName: packageName,
          error: e,
        ),
      );
      _writeCache(packageName, null);
      return VersionCheckResult.unavailable(
        current: cliVersion,
        packageName: packageName,
      );
    }
  }

  // ---- 私有：缓存 I/O ----

  String get _cacheDir => '${Directory.systemTemp.path}/$cacheDirName';

  String get _cacheFile => '$_cacheDir/version_check.json';

  Map<String, VersionCacheEntry> _readCache() {
    try {
      final file = File(_cacheFile);
      if (!file.existsSync()) return {};
      final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return raw.map(
        (k, v) =>
            MapEntry(k, VersionCacheEntry.fromJson(v as Map<String, dynamic>)),
      );
    } on Object catch (e) {
      _logger.detail(_messages.versionCheck.detailCacheReadFailed(error: e));
      return {};
    }
  }

  /// 写入缓存。[latest] 为 null 表示本次检查不可用（包未发布 / 网络异常）。
  void _writeCache(String packageName, String? latest) {
    try {
      final dir = Directory(_cacheDir);
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final file = File(_cacheFile);
      final all = _readCache();
      all[packageName] = VersionCacheEntry(
        latest: latest,
        available: latest != null,
        checkedAt: DateTime.now().millisecondsSinceEpoch,
      );
      final json = <String, dynamic>{};
      for (final e in all.entries) {
        json[e.key] = e.value.toJson();
      }
      file.writeAsStringSync(jsonEncode(json));
    } on Object catch (e) {
      _logger.detail(_messages.versionCheck.detailCacheWriteFailed(error: e));
    }
  }

  // ---- 私有：过期策略 ----

  bool _isStale(int checkedAt) {
    const ttlMillis = 24 * 60 * 60 * 1000; // 24h
    return DateTime.now().millisecondsSinceEpoch - checkedAt > ttlMillis;
  }

  /// 不可用结果是否已超过 10 分钟缓存窗口（true = 过期，需重新探测）。
  bool _isRecentUnavailable(int checkedAt) {
    const ttlMillis = 10 * 60 * 1000; // 10min
    return DateTime.now().millisecondsSinceEpoch - checkedAt > ttlMillis;
  }
}
