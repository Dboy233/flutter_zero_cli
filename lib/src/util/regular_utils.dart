/// 版本号提取器：从 URL 中匹配语义化版本号。
///
/// Extracts a semantic version string from a URL.
class VersionExtractor {
  const VersionExtractor._();

  /// 从给定的 URL 字符串中提取版本号。
  /// 如果找到匹配则返回版本字符串（仅主版本号部分），否则返回 null。
  ///
  /// Extracts the major.minor.patch portion from a URL, or null.
  static String? extractVersion(String url) {
    // 正则匹配语义化版本号（主版本.次版本.补丁版本，可选预发布和构建元数据）
    final RegExp versionRegExp = RegExp(
      r'(\d+\.\d+\.\d+)(?:-[a-zA-Z0-9.-]+)?(?:\+[a-zA-Z0-9.-]+)?',
      caseSensitive: false,
    );

    final match = versionRegExp.firstMatch(url);
    return match?.group(1);
  }
}
