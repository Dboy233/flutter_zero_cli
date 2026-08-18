// `version` 命令：打印当前版本，并检查 pub.dev 是否有更新。
//
// `version` command: prints the current version and checks pub.dev for updates.

import 'package:args/args.dart';

import '../../commands/base_command.dart';
import '../../commands/version/version_context.dart';
import '../../config/template_config.dart';
import '../../util/spinner.dart';
import '../../version/version_check.dart';

/// `version` 命令：查看版本并检查更新。
///
/// `version` command: show version and check for updates.
class VersionCommand extends BaseCommand<VersionCommandContext> {
  /// 创建 VersionCommand 实例。
  ///
  /// [logger] / [versionCheckService] / [translations] 由外部必填注入（[Fluzer]
  /// 统一提供）。
  ///
  /// Creates a VersionCommand instance.
  ///
  /// [logger] / [versionCheckService] / [translations] are required (injected by
  /// [Fluzer]).
  VersionCommand({
    required super.logger,
    required super.versionCheckService,
    required super.translations,
  });

  @override
  String get name => 'version';

  @override
  String get description => translations.version.description;

  @override
  Future<VersionCommandContext> buildContext(ArgResults args) async =>
      const VersionCommandContext();

  @override
  Future<int> execute(VersionCommandContext ctx) async {
    logger.info('fluzer $cliVersion');

    // 版本校验涉及 pub.dev 网络请求，用 spinner 体现等待过程；
    // --log 模式下 SpinnerRunner 不显示 spinner，改为直接执行。
    final result = await SpinnerRunner(
      logger: logger,
      translations: translations,
    ).run<VersionCheckResult>(
      message: translations.version.checking,
      work: () => versionCheckService.checkForUpdate(),
    );

    if (!result.available) {
      logger.info(translations.version.checkUnavailable);
      return 0;
    }

    if (result.hasUpdate) {
      logger.info(translations.version.newVersionFound(latest: result.latest));
      logger.info('  dart pub global activate fluzer');
    } else {
      logger.info(translations.version.alreadyLatest);
    }
    return 0;
  }
}
