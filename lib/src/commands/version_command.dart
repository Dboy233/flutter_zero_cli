// `version` 命令：打印当前版本，并检查 pub.dev 是否有更新。
//
// `version` command: prints the current version and checks pub.dev for updates.

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../config/template_config.dart';
import '../logging/spinner.dart';
import '../version/version_check.dart';

/// `version` 命令：查看版本并检查更新。
///
/// `version` command: show version and check for updates.
class VersionCommand extends Command<int> {
  /// 创建 VersionCommand 实例。
  ///
  /// [versionCheckService] 可注入版本检查服务（测试用），省略时创建默认实例。
  ///
  /// Creates a VersionCommand instance.
  ///
  /// [versionCheckService] injects the version-check service (for tests);
  /// when omitted a default instance is created.
  VersionCommand({
    Logger? logger,
    VersionCheckService? versionCheckService,
  })  : _logger = logger ?? Logger(),
        _versionCheckService =
            versionCheckService ?? VersionCheckService(logger: logger ?? Logger());

  final Logger _logger;
  final VersionCheckService _versionCheckService;

  @override
  String get name => 'version';

  @override
  String get description =>
      '查看当前版本并检查更新 / Show version and check for updates';

  @override
  Future<int> run() async {
    _logger.info('fluzer $cliVersion');

    // 版本校验涉及 pub.dev 网络请求，用 spinner 体现等待过程；
    // --log 模式下 runWithSpinner 不显示 spinner，改为直接执行。
    final result = await runWithSpinner<VersionCheckResult>(
      logger: _logger,
      message: '正在检查更新…',
      work: () => _versionCheckService.checkForUpdate(),
    );

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
