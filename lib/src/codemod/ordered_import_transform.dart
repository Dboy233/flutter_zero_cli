// ignore_for_file: depend_on_referenced_packages
import 'package:analyzer/dart/ast/ast.dart';
import 'package:codemod_recipe/codemod_recipe.dart';

/// 按 `directives_ordering` 规则插入 import 的 Transform。
///
/// 分组顺序：dart: → package: → relative，
/// 同组内按 URI 字符串字典序插入。
/// 已存在则跳过。
///
/// Transform that inserts an import while respecting the
/// `directives_ordering` lint rule.
///
/// Groups: dart: → package: → relative, sorted alphabetically within each
/// group. Skips if the import already exists.
class OrderedImportTransform implements CodeTransform {
  /// 创建 Transform。
  ///
  /// [uri] 为 import 的 URI，例如 `'package:flutter/material.dart'` 或
  /// `'../../features/user/user_module.dart'`。
  ///
  /// Creates the transform.
  ///
  /// [uri] is the import URI, e.g. `'package:flutter/material.dart'` or
  /// `'../../features/user/user_module.dart'`.
  const OrderedImportTransform(this.uri);

  /// 要插入的 import URI。
  ///
  /// Import URI to insert.
  final String uri;

  @override
  Future<List<SourcePatch>> apply(String source, CodemodContext context) async {
    if (source.contains("import '$uri';")) return [];

    final unit = parseSource(source);
    final imports = unit.directives.whereType<ImportDirective>().toList();

    final insertOffset = _findInsertOffset(imports);

    return [
      SourcePatch(
        insertOffset,
        0,
        "import '$uri';\n",
        description: 'Add import $uri',
      ),
    ];
  }

  int _findInsertOffset(List<ImportDirective> imports) {
    final dartImports = <ImportDirective>[];
    final packageImports = <ImportDirective>[];
    final relativeImports = <ImportDirective>[];

    for (final import in imports) {
      final value = import.uri.stringValue ?? '';
      if (value.startsWith('dart:')) {
        dartImports.add(import);
      } else if (value.startsWith('package:')) {
        packageImports.add(import);
      } else {
        relativeImports.add(import);
      }
    }

    final group = _groupFor(uri);

    if (group == 'relative') {
      if (relativeImports.isNotEmpty) {
        for (final import in relativeImports) {
          final value = import.uri.stringValue!;
          if (uri.compareTo(value) < 0) return import.offset;
        }
        return relativeImports.last.end;
      }
      if (packageImports.isNotEmpty) return packageImports.last.end;
      if (dartImports.isNotEmpty) return dartImports.last.end;
    }

    if (group == 'package') {
      if (packageImports.isNotEmpty) {
        for (final import in packageImports) {
          final value = import.uri.stringValue!;
          if (uri.compareTo(value) < 0) return import.offset;
        }
        return packageImports.last.end;
      }
      if (dartImports.isNotEmpty) return dartImports.last.end;
    }

    if (group == 'dart') {
      if (dartImports.isNotEmpty) {
        for (final import in dartImports) {
          final value = import.uri.stringValue!;
          if (uri.compareTo(value) < 0) return import.offset;
        }
        return dartImports.last.end;
      }
    }

    return 0;
  }

  String _groupFor(String value) {
    if (value.startsWith('dart:')) return 'dart';
    if (value.startsWith('package:')) return 'package';
    return 'relative';
  }
}
