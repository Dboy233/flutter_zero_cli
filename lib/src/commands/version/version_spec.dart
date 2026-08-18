// 版本规格（Specification 模式）。
//
// 用声明式规则表达「某个模板版本是否归本适配器处理」，
// 取代硬编码的 `if (major == n)`。支持半开区间与「全部匹配」兜底。
//
// Version specification (Specification pattern).
//
// Expresses declaratively whether a template version belongs to an adapter,
// replacing hard-coded `if (major == n)`. Supports half-open ranges and an
// "always matches" fallback.

import 'package:fluzer/src/util/semantic_version.dart';

/// 版本匹配规格抽象。
///
/// Version-matching specification.
abstract class VersionSpec {
  /// 创建规格。
  ///
  /// Creates the specification.
  const VersionSpec();

  /// [version] 是否满足本规格。
  ///
  /// Whether [version] satisfies this specification.
  bool isSatisfiedBy(SemanticVersion version);
}

/// 半开区间规格 `[lower, upper)`：`lower` 含，`upper` 不含。
///
/// 省略 [upper] 表示无上界（含 `lower` 起的所有版本）。
///
/// Half-open range `[lower, upper)`: inclusive `lower`, exclusive `upper`.
/// Omit [upper] for an unbounded upper bound (everything from `lower` on).
class RangeSpec implements VersionSpec {
  /// 创建区间规格。
  ///
  /// Creates a range specification.
  const RangeSpec(this.lower, [this.upper]);

  /// 下界（含）。
  ///
  /// Lower bound (inclusive).
  final SemanticVersion lower;

  /// 上界（不含）；为 `null` 表示无上界。
  ///
  /// Upper bound (exclusive); `null` means unbounded.
  final SemanticVersion? upper;

  @override
  bool isSatisfiedBy(SemanticVersion version) {
    if (version < lower) return false;
    if (upper != null && version >= upper!) return false;
    return true;
  }
}

/// 全部匹配规格（Null Object）：任意版本都满足。
///
/// 用于责任链末端的兜底适配器，使链永不「失败」。
///
/// "Matches everything" specification (Null Object): satisfies any version.
/// Used by the chain's terminal fallback adapter so the chain never fails.
class AnySpec implements VersionSpec {
  /// 创建全部匹配规格。
  ///
  /// Creates the "matches everything" specification.
  const AnySpec();

  @override
  bool isSatisfiedBy(SemanticVersion version) => true;
}
