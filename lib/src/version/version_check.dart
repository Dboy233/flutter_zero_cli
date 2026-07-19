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

import '../template/template_config.dart';

/// 模块级复用的 Dio 实例（用于 pub.dev 版本查询）。
///
/// Shared Dio instance for pub.dev version queries.
final Dio _dio = Dio();

/// 默认查询的 pub.dev 包名 / Default pub.dev package name to check.
const String cliPackageName = 'fluzer';

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
  }) =>
      VersionCheckResult(
        current: current,
        latest: current,
        hasUpdate: false,
        packageName: packageName,
        available: false,
      );
}

/// 检查指定包是否有新版本。
///
/// 默认查询 [cliPackageName]（即 fluzer 自身）。[packageName] 可传入任意
/// 已发布的 pub 包，便于在未发布 CLI 时验证解析逻辑（如测试用 `args`）。
///
/// Checks whether a newer version of [packageName] exists on pub.dev.
Future<VersionCheckResult> checkForUpdate({
  String packageName = cliPackageName,
}) async {
  final cached = _readCache()[packageName] as Map<String, dynamic>?;
  if (cached != null && !_isStale(cached['checkedAt'] as int? ?? 0)) {
    final latest = cached['latest'] as String? ?? cliVersion;
    return VersionCheckResult(
      current: cliVersion,
      latest: latest,
      hasUpdate: _compareSemver(latest, cliVersion) > 0,
      packageName: packageName,
    );
  }

  try {
    final response = await _dio.get<dynamic>(
      'https://pub.dev/api/packages/$packageName',
      options: Options(
        responseType: ResponseType.json,
        receiveTimeout: const Duration(seconds: 3),
        validateStatus: (_) => true,
      ),
    );
    if (response.statusCode != 200) {
      return VersionCheckResult.unavailable(
        current: cliVersion,
        packageName: packageName,
      );
    }
    final data = response.data as Map<String, dynamic>;
    final latest = (data['latest']?['version'] as String?) ?? cliVersion;
    _writeCache(packageName, latest);
    return VersionCheckResult(
      current: cliVersion,
      latest: latest,
      hasUpdate: _compareSemver(latest, cliVersion) > 0,
      packageName: packageName,
    );
  } on Object {
    return VersionCheckResult.unavailable(
      current: cliVersion,
      packageName: packageName,
    );
  }
}

/// 比较 `major.minor.patch`，返回负数 / 0 / 正数。忽略 pre-release。
int _compareSemver(String a, String b) {
  final pa = a.split('.');
  final pb = b.split('.');
  for (var i = 0; i < 3; i++) {
    final na = int.tryParse(i < pa.length ? pa[i] : '0') ?? 0;
    final nb = int.tryParse(i < pb.length ? pb[i] : '0') ?? 0;
    if (na != nb) return na.compareTo(nb);
  }
  return 0;
}

/// 缓存目录（复用 CLI 的临时缓存区）/ Cache directory.
String get _cacheDir => '${Directory.systemTemp.path}/fluzer_cache';

String get _cacheFile => '$_cacheDir/version_check.json';

Map<String, dynamic> _readCache() {
  try {
    final file = File(_cacheFile);
    if (!file.existsSync()) return const {};
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  } on Object {
    return const {};
  }
}

void _writeCache(String packageName, String latest) {
  try {
    final dir = Directory(_cacheDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final file = File(_cacheFile);
    final all = _readCache();
    all[packageName] = {
      'latest': latest,
      'checkedAt': DateTime.now().millisecondsSinceEpoch,
    };
    file.writeAsStringSync(jsonEncode(all));
  } on Object {
    // 缓存写入失败不影响主流程 / Ignore cache write failures.
  }
}

bool _isStale(int checkedAt) {
  // 24 小时的毫秒数 / 24h in milliseconds.
  const ttlMillis = 24 * 60 * 60 * 1000;
  return DateTime.now().millisecondsSinceEpoch - checkedAt > ttlMillis;
}
