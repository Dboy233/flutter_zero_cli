// 模板相关配置常量。
//
// Template configuration constants.
//
// 发布前请确认以下地址已替换为真实值：
// - [templateRegistryUrl]
// - [defaultTemplateZipUrl]（版本段由 [minimumSupportedVersion] 自动拼接）
//
// 版本号 [cliVersion] 必须与 `pubspec.yaml` 的 `version` 保持同步。

/// CLI 自身版本号。发布新版本时须与 `pubspec.yaml` 的 `version` 同步。
///
/// This CLI's own version. Keep in sync with `pubspec.yaml` when releasing.
const String cliVersion = '1.1.3';

/// 远程 registry 地址（发布前替换为真实 raw URL）。
///
/// 指向 `flutter_zero_template/template_registry.json` 的 raw 链接，例如
/// `https://raw.githubusercontent.com/<owner>/<repo>/main/template_registry.json`
/// Remote registry URL (replace with the real raw URL before publishing).
const String templateRegistryUrl =
    'https://raw.githubusercontent.com/Dboy233/flutter_zero_template/main/template_registry.json';

/// 模板项目必须包含的最小版本号（CLI 能接受的最老模板版本）。
///
/// 与 [defaultTemplateZipUrl] 共用此值：兜底 zip 即该最低版本模板本身。
/// 发布 CLI 时**不要**把它同步成 CLI 版本，否则会错误排斥 1.0.x 等正常模板。
const String minimumSupportedVersion = '1.0.0';

/// 内置兜底模板 zip 地址（registry 拉取失败时使用）。
///
/// 版本段由 [minimumSupportedVersion] 自动拼接，二者保持同步；
/// 发布前请确认 URL 基址指向真实 Release 资源。
/// Built-in fallback template zip URL (used when registry fetch fails).
/// The version segment is derived from [minimumSupportedVersion].
const String defaultTemplateZipUrl =
    'https://github.com/Dboy233/flutter_zero_template/releases/download/$minimumSupportedVersion/bricks.zip';

/// 国内 GitHub 镜像降级地址（当 GitHub 原始地址请求失败时依次尝试）。
///
/// 规则：前缀 + 原始 URL，例如 `https://ghfast.top/https://github.com/...`。
///
/// 链接失效时可通过 https://ghproxy.link/ 查看最新可用地址。
/// GitHub mirror fallback prefixes, tried in order.
const List<String> githubMirrorFallbacks = <String>[
  'https://ghfast.top/',
  'https://api.gitproxy.dev/',
];

/// CLI 缓存根目录名（位于系统临时目录下）。
///
/// Cache root directory name under the system temp directory.
const String cacheDirName = 'fluzer_cache';
