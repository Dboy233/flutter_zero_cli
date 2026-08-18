// 命名规范转换工具（纯函数，无外部依赖）。
//
// Naming-case conversion utilities (pure functions, no external deps).

/// snake_case 命名转换工具。
///
/// 将 snake_case 标识符转换为 PascalCase / camelCase；无外部依赖，逻辑
/// 全部封装为静态方法，避免模块级函数。
///
/// Snake-case conversion utilities. Converts snake_case identifiers to
/// PascalCase / camelCase; all logic lives in static methods (no top-level
/// functions).
class CaseConverter {
  /// 创建转换工具。
  ///
  /// Creates the converter.
  const CaseConverter();

  /// 将 snake_case 转为 PascalCase。
  ///
  /// 示例 / Example: `user_profile` → `UserProfile`。
  static String toPascalCase(String input) {
    return input
        .split('_')
        .map(
          (word) =>
              word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join();
  }
}
