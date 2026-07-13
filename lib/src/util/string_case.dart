// 命名规范转换工具（纯函数，无外部依赖）。
//
// Naming-case conversion utilities (pure functions, no external deps).

/// 将 snake_case 转为 PascalCase。
///
/// 示例 / Example: `user_profile` → `UserProfile`。
String toPascalCase(String input) {
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

/// 将 snake_case 转为 camelCase。
///
/// 示例 / Example: `user_profile` → `userProfile`。
String toCamelCase(String input) {
  final pascal = toPascalCase(input);
  if (pascal.isEmpty) return pascal;
  return '${pascal[0].toLowerCase()}${pascal.substring(1)}';
}
