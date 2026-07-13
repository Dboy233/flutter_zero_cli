// 基于 Mason 的 brick 渲染器。
//
// Mason-based brick renderer.
//
// 封装 [BrickLoader] 解析与 [MasonGenerator] 生成，对外只暴露 [generate]
// 一个方法，命令层无需关心模板来自本地还是远程。
//
// Wraps [BrickLoader] resolution and [MasonGenerator] generation, exposing a
// single [generate] method so command layers don't care whether the template
// comes from local disk or a remote zip.

import 'dart:io';

import 'package:mason/mason.dart';

import 'brick_loader.dart';

/// Brick 渲染器。
///
/// Brick renderer.
class BrickRenderer {
  /// 创建渲染器。
  ///
  /// Creates a renderer.
  const BrickRenderer(this.loader);

  /// Brick 加载器（本地或远程）。
  ///
  /// Brick loader (local or remote).
  final BrickLoader loader;

  /// 生成指定 brick 到 [outputDir]，传入 Mason 变量 [vars]。
  ///
  /// [brickName] 如 `'feature'` / `'project'`。
  ///
  /// Generates the given [brickName] into [outputDir] with Mason [vars].
  /// [brickName] is e.g. `'feature'` or `'project'`.
  Future<void> generate({
    required String brickName,
    required Directory outputDir,
    required Map<String, dynamic> vars,
  }) async {
    final brick = await loader.load(brickName);
    final generator = await MasonGenerator.fromBrick(brick);
    final target = DirectoryGeneratorTarget(outputDir);
    await generator.generate(
      target,
      vars: vars,
      fileConflictResolution: FileConflictResolution.overwrite,
    );
  }
}
