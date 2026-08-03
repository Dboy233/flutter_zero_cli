// 极简语义化版本（仅比较 major.minor.patch 数值，忽略 pre-release / build）。
//
// Minimal semantic version (compares major.minor.patch only).

/// 极简语义化版本。
///
/// 只比较 `major.minor.patch` 的数值，忽略 pre-release 与 build 元数据。
/// 用于 CLI 与模板之间的兼容性比较（如 `minCliVersion <= cliVersion`）。
class SemanticVersion implements Comparable<SemanticVersion> {
  const SemanticVersion(this.major, this.minor, this.patch);

  /// 全零版本，作为比较基线。
  static const zero = SemanticVersion(0, 0, 0);

  final int major;
  final int minor;
  final int patch;

  /// 解析 `major.minor.patch` 字符串，缺失段按 0 处理。
  static SemanticVersion parse(String value) {
    final parts = value.split('.');
    final major = int.tryParse(parts[0]) ?? 0;
    final minor = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final patch = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
    return SemanticVersion(major, minor, patch);
  }

  @override
  int compareTo(SemanticVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator >(SemanticVersion other) => compareTo(other) > 0;

  bool operator <(SemanticVersion other) => compareTo(other) < 0;

  bool operator >=(SemanticVersion other) => compareTo(other) >= 0;

  bool operator <=(SemanticVersion other) => compareTo(other) <= 0;

  /// 还原为 `major.minor.patch` 字符串（用于缓存键、日志等）。
  ///
  /// Formats back to `major.minor.patch` (used for cache keys, logs, etc.).
  @override
  String toString() => '$major.$minor.$patch';

  /// 值相等比较（按 major.minor.patch 数值）。
  ///
  /// Value equality by major.minor.patch.
  @override
  bool operator ==(Object other) =>
      other is SemanticVersion &&
      major == other.major &&
      minor == other.minor &&
      patch == other.patch;

  @override
  int get hashCode => major.hashCode ^ minor.hashCode ^ patch.hashCode;
}
