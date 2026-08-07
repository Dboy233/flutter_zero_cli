// 代码定位修改工具类：封装两类高频操作，支持一键调用。
//
// Code-modification utility class: wraps the two most common operations into
// one-call methods.
//
// - [addImport]：按 directives_ordering 规则插入 import（已存在则跳过）。
// - [insertAtMethodEnd]：在指定类的方法体末尾插入代码（幂等）。
//
// 底层复用 codemod_recipe 的 Transform 与 [CodemodFileEditor]（含自动格式化）。

import 'dart:io';

import 'package:fluzer/src/i18n/gen/strings.g.dart';

import 'codemod_file_editor.dart';
import 'insert_at_method_end_transform.dart';
import 'ordered_import_transform.dart';

/// 代码修改工具类。
///
/// Code modification utility.
///
/// 用法 / Usage:
/// ```dart
/// final mod = CodeMod(File('lib/core/di/injection_base.dart'));
/// await mod.addImport('../../features/user/user_module.dart');
/// await mod.insertAtMethodEnd(
///   className: 'InjectionBase',
///   methodName: 'registerFeatureModules',
///   code: '    UserModule.register(getIt);\n',
///   skipIfContains: 'UserModule.register(getIt)',
/// );
/// ```
class CodeMod {
  /// 创建工具实例。
  ///
  /// [file] 为目标 Dart 文件；[format] 为是否在写入后自动 `dart format`。
  ///
  /// Creates the utility. [file] is the target Dart file; [format] toggles
  /// post-write `dart format`.
  CodeMod(this.file, {this.format = true, Translations? messages})
    : _messages = messages ?? AppLocale.zh.buildSync();

  /// 目标 Dart 文件。
  ///
  /// Target Dart file.
  final File file;

  /// 本地化消息（类型安全访问器）。
  ///
  /// Localized messages (type-safe accessors).
  final Translations _messages;

  /// 是否在写入后自动格式化。
  ///
  /// Whether to format the file after writing patches.
  final bool format;

  /// 一键添加 import（按 directives_ordering 排序，已存在则跳过）。
  ///
  /// One-call import insertion (sorted per directives_ordering; skips if
  /// the import already exists).
  Future<void> addImport(String uri) async {
    await CodemodFileEditor(file, format: format, messages: _messages).apply([
      OrderedImportTransform(uri),
    ]);
  }

  /// 一键在指定类的方法体末尾插入代码（幂等）。
  ///
  /// One-call insertion at the end of a method body in a given class
  /// (idempotent via [skipIfContains]).
  Future<void> insertAtMethodEnd({
    required String className,
    required String methodName,
    required String code,
    String? skipIfContains,
  }) async {
    await CodemodFileEditor(file, format: format, messages: _messages).apply([
      InsertAtMethodEndTransform(
        className: className,
        methodName: methodName,
        code: code,
        skipIfContains: skipIfContains,
      ),
    ]);
  }
}
