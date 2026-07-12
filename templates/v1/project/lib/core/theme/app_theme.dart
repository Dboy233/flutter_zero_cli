import 'package:flutter/material.dart';

/// 应用主题定义。
///
/// 本类提供统一的浅色与深色主题，包含一致的排版、颜色和组件默认值。
/// 在 [MaterialApp] 中使用 [AppTheme.lightTheme] 和 [AppTheme.darkTheme]。
///
///
/// Application theme definitions.
///
/// This class provides light and dark themes with consistent typography,
/// colors and component defaults. Use [AppTheme.lightTheme] and
/// [AppTheme.darkTheme] in [MaterialApp].
class AppTheme {
  AppTheme._();

  /// 用于生成配色方案的种子颜色。
  ///
  ///
  /// Seed color used to generate the color scheme.
  static const Color _seedColor = Colors.deepPurple;

  /// 浅色主题配置。
  ///
  ///
  /// Light theme configuration.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  /// 深色主题配置。
  ///
  ///
  /// Dark theme configuration.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
