// `version` 命令：打印当前版本，并检查 pub.dev 是否有更新。
//
// `version` command: prints the current version and checks pub.dev for updates.

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../template/template_source.dart';
import '../version/version_check.dart';

/// `version` 命令：查看版本并检查更新。
///
/// `version` command: show version and check for updates.
class VersionCommand extends Command<int> {
  /// 创建 VersionCommand 实例 / Creates a VersionCommand instance.
  VersionCommand({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;

  @override
  String get name => 'version';

  @override
  String get description =>
      '查看当前版本并检查更新 / Show version and check for updates';

  @override
  Future<int> run() async {
    _logger.info('fluzer $cliVersion');

    final result = await checkForUpdate();
    if (!result.available) {
      _logger.info('（无法检查更新：包尚未发布或网络异常）');
      return 0;
    }

    if (result.hasUpdate) {
      _logger.info('发现新版本 ${result.latest}，运行以下命令升级：');
      _logger.info('  dart pub global activate fluzer');
    } else {
      _logger.info('已是最新版本');
    }
    return 0;
  }
}
