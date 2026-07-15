// 模板来源解析：根据环境变量 / 远程 registry 决定使用本地还是远程加载器。
//
// Template source resolution: chooses a local or remote loader based on
// environment variables and the remote template registry.
//
// 解析优先级（Priority）：
// 1. `FLUZER_BRICKS_DIR` 非空 → [LocalBrickLoader]（本地开发 / 调试）；
// 2. `FLUZER_TEMPLATE_ZIP_URL` 非空 → 强制使用该 URL 的 [RemoteBrickLoader]（测试 / 调试）；
// 3. 否则远程：从 [_templateRegistryUrl] 拉取 registry，按 CLI 版本
//    （[cliVersion]）选出 `minCliVersion <= cliVersion` 中 `version` 最大者的
//    zip URL；拉取失败则回退 [_defaultTemplateZipUrl]。
//
// 发布说明（Publishing）：
// - 发布前请将 [_templateRegistryUrl] 与 [_defaultTemplateZipUrl] 替换为真实地址。
// - registry 采用"兼容性桶"结构：每条记录代表一个 `minCliVersion` 级别下的最新
//   模板快照；模板发 PATCH/MINOR 只更新该记录的 `version`/`url`，发 MAJOR 才新增记录。
//   详见 `flutter_zero_template/template_registry.json` 与 `VERSIONING_CLI.md`。

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'brick_loader.dart';

/// CLI 自身版本号。发布新版本时须与 `pubspec.yaml` 的 `version` 同步。
///
/// This CLI's own version. Keep in sync with `pubspec.yaml` when releasing.
const String cliVersion = '1.0.0';

/// 远程 registry 地址（发布前替换为真实 raw URL）。
///
/// 指向 `flutter_zero_template/template_registry.json` 的 raw 链接，例如
/// `https://raw.githubusercontent.com/<owner>/<repo>/main/template_registry.json`
/// Remote registry URL (replace with the real raw URL before publishing).
const String _templateRegistryUrl =
    'https://raw.githubusercontent.com/<owner>/<repo>/main/template_registry.json';

/// 内置兜底模板 zip 地址（registry 拉取失败时使用）。
///
/// 发布前替换为真实 Release 固定版本链接，例如
/// `https://github.com/<owner>/<repo>/releases/download/v1.0.0/bricks.zip`
/// Built-in fallback template zip URL (used when registry fetch fails).
const String _defaultTemplateZipUrl =
    'https://github.com/<owner>/<repo>/releases/download/v1.0.0/bricks.zip';

/// 解析当前应使用的 [BrickLoader]。
///
/// 解析顺序见文件头注释。返回 [Future] 因为远程模式需异步拉取 registry。
///
/// Resolves the [BrickLoader] to use (async, see header for the order).
Future<BrickLoader> resolveBrickLoader() async {
  // 1. 本地开发 / 调试：显式指定本地 bricks 目录时优先使用。
  final bricksDir = Platform.environment['FLUZER_BRICKS_DIR'];
  if (bricksDir != null && bricksDir.isNotEmpty) {
    return LocalBrickLoader(Directory(bricksDir));
  }

  // 2. 测试 / 调试：允许通过环境变量强制指定远程 URL。
  final overrideUrl = Platform.environment['FLUZER_TEMPLATE_ZIP_URL'];
  if (overrideUrl != null && overrideUrl.isNotEmpty) {
    return RemoteBrickLoader(zipUrl: overrideUrl);
  }

  // 3. 远程：从 registry 选出版本兼容的模板 zip URL（失败回退内置默认值）。
  return RemoteBrickLoader(zipUrl: await _selectTemplateZipUrl());
}

/// 从 registry 选出版本兼容的模板 zip URL。
///
/// 遍历 `templates`，在所有 `minCliVersion <= [cliVersion]` 的记录中，
/// 选取 `version` 最大者的 `url`；无匹配或拉取失败时回退 [_defaultTemplateZipUrl]。
///
/// Selects the version-compatible template zip URL from the registry.
Future<String> _selectTemplateZipUrl() async {
  try {
    final response = await http.get(Uri.parse(_templateRegistryUrl));
    if (response.statusCode != 200) return _defaultTemplateZipUrl;
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final templates = (json['templates'] as List?) ?? <dynamic>[];
    var bestUrl = _defaultTemplateZipUrl;
    var bestVersion = _Version.zero;
    for (final item in templates) {
      final t = item as Map<String, dynamic>;
      final minCli = _Version.parse(t['minCliVersion'] as String? ?? '0.0.0');
      if (minCli > _Version.parse(cliVersion)) continue;
      final version = _Version.parse(t['version'] as String? ?? '0.0.0');
      if (version > bestVersion) {
        bestVersion = version;
        bestUrl = t['url'] as String? ?? _defaultTemplateZipUrl;
      }
    }
    return bestUrl;
  } on Object {
    return _defaultTemplateZipUrl;
  }
}

/// 极简语义化版本（仅比较 major.minor.patch 数值，忽略 pre-release / build）。
///
/// Minimal semantic version (compares major.minor.patch only).
class _Version implements Comparable<_Version> {
  const _Version(this.major, this.minor, this.patch);

  /// 全零版本，作为比较基线。
  static const zero = _Version(0, 0, 0);

  final int major;
  final int minor;
  final int patch;

  /// 解析 `major.minor.patch` 字符串，缺失段按 0 处理。
  static _Version parse(String value) {
    final parts = value.split('.');
    final major = int.tryParse(parts[0]) ?? 0;
    final minor = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final patch = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
    return _Version(major, minor, patch);
  }

  @override
  int compareTo(_Version other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator >(_Version other) => compareTo(other) > 0;
  bool operator <(_Version other) => compareTo(other) < 0;
  bool operator >=(_Version other) => compareTo(other) >= 0;
  bool operator <=(_Version other) => compareTo(other) <= 0;
}
