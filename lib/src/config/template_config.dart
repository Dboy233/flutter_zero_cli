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
const String cliVersion = '2.0.0';

/// 远程 registry 地址（发布前替换为真实 raw URL）。
///
/// 指向 `flutter_zero_template/template_registry.json` 的 raw 链接，例如
/// `https://raw.githubusercontent.com/<owner>/<repo>/main/template_registry.json`
/// Remote registry URL (replace with the real raw URL before publishing).
const String templateRegistryUrl =
    'https://raw.githubusercontent.com/Dboy233/flutter_zero_template/main/template_registry.json';

/// 兜底模板 zip 的版本段（**仅用于拼接下载 URL**，不是兼容性门槛）。
///
/// 注意：CLI 已不再依据模板版本做兼容性门禁（力求适配所有模板版本），
/// 此常量只作为 `create` 命令 registry 拉取失败时的兜底下载地址版本段，
/// 与 CLI 能否运行某模板无关。发布 CLI 时**不要**把它同步成 CLI 版本。
const String minimumSupportedVersion = '1.0.0';

/// 内置兜底模板 zip 地址（registry 拉取失败时使用）。
///
/// 版本段由 [minimumSupportedVersion] 自动拼接，二者保持同步；
/// 发布前请确认 URL 基址指向真实 Release 资源。
/// 该地址仅作下载兜底，**不参与任何版本兼容性判断**。
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
