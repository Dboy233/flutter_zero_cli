abstract class RegularUtils {
  /// 从给定的 URL 字符串中提取版本号。
  /// 如果找到匹配的版本号则返回该字符串，否则抛出 [FormatException]。
  static String? extractVersion(String url) {
    // 正则匹配语义化版本号（主版本.次版本.补丁版本，可选预发布和构建元数据）
    final RegExp versionRegExp = RegExp(
      r'(\d+\.\d+\.\d+)(?:-[a-zA-Z0-9.-]+)?(?:\+[a-zA-Z0-9.-]+)?',
      caseSensitive: false,
    );

    final Match? match = versionRegExp.firstMatch(url);
    if (match != null) {
      return match.group(1); // 返回捕获的主版本号部分（不含预发布和构建信息）
    } else {
      return null;
    }
  }
}
