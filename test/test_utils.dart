// 跨平台测试辅助：临时目录安全删除。
//
// Windows 下新建的 .dart 等文件可能被杀毒软件 / 索引服务短暂锁定，
// 删除失败属常态。这里重试几次，仍失败则交予系统临时目录清理，
// 避免误判测试失败（与 debug_flag_test 中的处理方式一致）。

import 'dart:async';
import 'dart:io';

/// 跨平台安全删除 [dir]（含重试以应对 Windows 文件锁定）。
Future<void> deleteTempDir(Directory dir) async {
  for (var i = 0; i < 3; i++) {
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
      return;
    } on FileSystemException {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
}
