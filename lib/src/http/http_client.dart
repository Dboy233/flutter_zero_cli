// 统一 HTTP 客户端：Dio 实例 + 镜像降级竞速 + 超时策略。
//
// Unified HTTP client: shared Dio instance, mirror-fallback racing, and
// timeout policy for registry fetching and template zip downloads.
//
// 文本与 zip 下载均通过 [RaceHttpClient] 并发竞速：候选地址列表（直连 +
// 配置的 GitHub 镜像前缀）同时发起，第一个返回有效数据者胜出，其余立即
// 取消。因此不再需要顺序等待直连超时再回退镜像。

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mason_logger/mason_logger.dart';

import '../config/template_config.dart';
import 'race_http_client.dart';

/// CLI 统一 HTTP 客户端。
///
/// 封装镜像降级竞速：先直连，同时尝试 [template_config.dart] 中配置的镜像
/// 前缀。任意一个成功即采用，其余请求取消。全部失败返回 `null`，由调用方
/// 决定降级策略。
///
/// Unified HTTP client with mirror-fallback racing. Tries the direct URL and
/// every configured mirror prefix concurrently; the first success wins and
/// the rest are cancelled. Returns `null` when all attempts fail.
/// 是否显示下载进度条。
///
/// 仅在 `--log`（verbose 级别）且为交互终端时显示；默认模式由
/// [runWithSpinner] 的旋转 spinner 体现进度，避免重复输出与空行干扰。
/// 将 [hasTerminal] 作为参数传入，便于在测试（通常无终端）中显式断言
/// 各级别组合下的显示决策。
bool shouldShowDownloadProgress(Logger? logger, bool hasTerminal) =>
    hasTerminal && logger?.level == Level.verbose;

class FluzerHttpClient {
  /// 创建客户端。
  ///
  /// [logger] 用于输出竞速结果提示与下载进度；测试时可注入。[dio] 为统一
  /// Dio 实例，省略时新建并传递给内部 [RaceHttpClient]。
  ///
  /// Creates the client. [logger] is used for result hints and download
  /// progress; [dio] is the shared Dio instance (a new one is created and
  /// forwarded to the internal [RaceHttpClient] when omitted).
  FluzerHttpClient({this._logger, Dio? dio}) : _race = RaceHttpClient(dio: dio);

  final Logger? _logger;
  final RaceHttpClient _race;

  /// 文本 GET（registry 等）整体超时。
  ///
  /// Overall timeout for text GET (registry, etc.).
  static const Duration textTimeout = Duration(seconds: 30);

  /// 文件下载（模板 zip）整体超时。
  ///
  /// Overall timeout for file download (template zip).
  static const Duration fileTimeout = Duration(seconds: 180);

  /// GET 文本内容（如 registry JSON），带镜像竞速降级。
  ///
  /// 成功返回响应体字符串；全部失败返回 `null`。任一候选**抛异常**（非 200
  /// 视为软失败、不抛异常）时通过内部 [onFailure] 记录告警（被胜者取消的
  /// 候选属预期，不记录）。
  ///
  /// Fetches text content with mirror racing. Returns the body on success,
  /// or `null` if all candidates fail.
  Future<String?> getText(String url) async {
    final urls = _buildCandidateUrls(url);
    final result = await _race.getTextFirst(
      urls,
      perTimeout: textTimeout,
      overallTimeout: textTimeout,
      onFailure: _logFailure,
    );
    if (result == null) {
      _logger?.err('所有候选地址（直连 + 镜像）请求均失败。');
      return null;
    }
    _logger?.detail(
      result.url == url ? '直连请求成功：${result.url}' : '镜像请求成功：${result.url}',
    );
    return result.data;
  }

  /// 下载文件到临时目录（如模板 zip），带镜像竞速降级与进度显示。
  ///
  /// 成功返回 [DownloadedFile]（含落盘文件与临时目录）；全部失败返回 `null`。
  /// 调用方解压/使用后务必调用 [DownloadedFile.dispose] 清理临时目录。
  ///
  /// Downloads a file to a temp location with mirror racing and a progress
  /// bar. Returns a [DownloadedFile] on success, or `null` if all candidates
  /// fail. The caller must call [DownloadedFile.dispose] after use.
  Future<DownloadedFile?> downloadFile(String url) async {
    final urls = _buildCandidateUrls(url);
    // 进度条仅在 --log（verbose 级别）且为交互终端时显示；默认模式由
    // runWithSpinner 的旋转 spinner 体现进度，避免重复输出与空行干扰。
    final showProgress =
        shouldShowDownloadProgress(_logger, stdout.hasTerminal);

    void onProgress(String url, int received, int total) {
      if (!showProgress || total <= 0) return;
      final percent = (received / total * 100).floor();
      final filled = (percent / 100 * 40).floor();
      final bar = '${'=' * filled}>${' ' * (40 - filled - 1)}';
      stdout.write('\r下载模板: [$bar] $percent%');
    }

    final result = await _race.downloadFileFirst(
      urls,
      perTimeout: fileTimeout,
      overallTimeout: fileTimeout,
      onProgress: onProgress,
      onFailure: _logFailure,
    );
    if (showProgress) stdout.writeln();

    if (result == null) {
      _logger?.err('所有候选地址（直连 + 镜像）下载均失败。');
      return null;
    }
    _logger?.detail(
      result.url == url ? '直连下载成功：${result.url}' : '镜像下载成功：${result.url}',
    );
    return result.data;
  }

  /// 候选失败告警：被胜者取消（Dio cancel 异常）属预期，不记录；
  /// 其余网络/超时异常以 warn 记录，便于网络排查。
  ///
  /// Logs a per-candidate failure. A cancellation triggered by a winning
  /// candidate (Dio cancel) is expected and skipped; other errors warn.
  void _logFailure(String url, Object error) {
    if (error is DioException && error.type == DioExceptionType.cancel) return;
    _logger?.warn('候选地址请求失败：$url ($error)');
  }

  /// 构建候选地址列表：直连 + 各镜像前缀拼接到原 URL。
  ///
  /// Builds the candidate URL list: direct URL plus each mirror prefix
  /// prepended to the original URL.
  List<String> _buildCandidateUrls(String url) => [
    url,
    ...githubMirrorFallbacks.map((prefix) => '$prefix$url'),
  ];
}
