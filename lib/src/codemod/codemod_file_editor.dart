import 'dart:io';

import 'package:codemod_recipe/codemod_recipe.dart';

/// 对单个 Dart 文件应用 [CodeTransform] 并写回磁盘，可选自动格式化。
///
/// Applies a list of [CodeTransform] to a single Dart file and writes the
/// result back to disk. Optionally runs `dart format` after applying patches.
class CodemodFileEditor {
  /// 创建文件编辑器。
  ///
  /// [format] 为 `true`（默认）时，补丁写入后会调用 `dart format` 对文件
  /// 进行格式化。
  ///
  /// Creates a file editor for [file].
  /// When [format] is `true` (default), `dart format` is run after patches
  /// are applied.
  CodemodFileEditor(this._file, {this.format = true});

  final File _file;

  /// 是否在写入后自动格式化文件。
  ///
  /// Whether to run `dart format` on the file after writing patches.
  final bool format;

  /// 读取文件，依次应用所有 [transforms]，将补丁写回文件。
  ///
  /// [context] 会传给每个 transform；未提供时使用空 Context。
  ///
  /// Reads the file, applies [transforms], and writes the patched source
  /// back. [context] is passed to each transform; an empty context is used
  /// if omitted.
  Future<void> apply(
    List<CodeTransform> transforms, {
    CodemodContext? context,
  }) async {
    final source = await _file.readAsString();
    final ctx = context ?? CodemodContext({});
    final patches = <SourcePatch>[];

    for (final transform in transforms) {
      patches.addAll(await transform.apply(source, ctx));
    }

    if (patches.isEmpty) return;

    validateNonOverlappingPatches(patches);
    final result = applyPatches(source, patches);
    await _file.writeAsString(result);

    if (format) await _formatFile();
  }

  Future<void> _formatFile() async {
    final result = await Process.run('dart', [
      'format',
      _file.path,
    ], runInShell: true);
    if (result.exitCode != 0) {
      throw StateError('格式化失败 / Format failed: ${result.stderr}');
    }
  }
}
