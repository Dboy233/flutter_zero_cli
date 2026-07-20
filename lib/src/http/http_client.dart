// 统一 HTTP 客户端：Dio 实例 + 镜像降级重试 + 超时策略。
//
// Unified HTTP client: shared Dio instance, mirror fallback retries, and
// timeout policy for registry fetching and template zip downloads.
//
// 直连使用较短超时（快速失败）；镜像为代理、响应更慢，使用更长超时
// （实测 ghfast.top 约 5s+）。任意直连失败（超时 / DNS / 连接错误，
// 均为 [DioException]）都会触发镜像重试。

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../template/template_config.dart';

/// CLI 统一 HTTP 客户端。
///
/// 封装镜像降级：先直连 [directTimeout]，失败后依次尝试
/// [template_config.dart] 中配置的镜像前缀（[mirrorTimeout]）。
/// 全部失败返回 `null`，由调用方决定降级策略。
///
/// Unified HTTP client with mirror fallback: direct request first, then
/// each configured mirror prefix. Returns `null` when all attempts fail.
class FluzerHttpClient {
  /// 创建客户端。
  ///
  /// [logger] 用于输出镜像降级提示与下载进度；测试时可注入。
  FluzerHttpClient({Logger? logger, Dio? dio})
      : _dio = dio ?? Dio(),
        // ignore: prefer_initializing_formals
        _logger = logger;

  final Logger? _logger;
  final Dio _dio;

  /// 直连超时（快速失败）。
  static const Duration directTimeout = Duration(seconds: 5);

  /// 镜像超时（代理响应更慢，给足预算）。
  static const Duration mirrorTimeout = Duration(seconds: 15);

  /// 镜像下载超时（zip 体积大，预算更宽）。
  static const Duration mirrorDownloadTimeout = Duration(seconds: 120);

  /// 下载超时（直连 zip 下载）。
  static const Duration downloadTimeout = Duration(seconds: 60);

  /// GET 文本内容（如 registry JSON），带镜像降级。
  ///
  /// 成功返回响应体字符串；全部失败返回 `null`。
  ///
  /// Fetches text content with mirror fallback. Returns `null` on failure.
  Future<String?> getText(String url) async {
    // 1. 直连（短超时，快速失败）。
    final direct = await _tryGet(url, directTimeout);
    if (direct != null) return direct;

    // 2. 依次尝试镜像。
    _logger?.warn('原始地址请求失败，尝试镜像下载。');
    for (final prefix in githubMirrorFallbacks) {
      final mirrorUrl = '$prefix$url';
      final body = await _tryGet(mirrorUrl, mirrorTimeout);
      if (body != null) {
        _logger?.info('镜像下载成功：$mirrorUrl');
        return body;
      }
      _logger?.warn('镜像请求失败，尝试下一个：$mirrorUrl');
    }
    _logger?.err('镜像下载也失败。');
    return null;
  }

  /// 下载文件到临时目录（如模板 zip），带镜像降级与进度显示。
  ///
  /// 成功返回下载的临时文件；全部失败返回 `null`。调用方负责删除文件。
  ///
  /// Downloads a file to a temp location with mirror fallback and a
  /// progress bar. Returns the temp file, or `null` on failure.
  Future<File?> downloadFile(String url) async {
    final direct = await _tryDownload(url, downloadTimeout);
    if (direct != null) return direct;

    _logger?.warn('原始地址请求失败，尝试镜像下载。');
    for (final prefix in githubMirrorFallbacks) {
      final mirrorUrl = '$prefix$url';
      final file = await _tryDownload(mirrorUrl, mirrorDownloadTimeout);
      if (file != null) {
        _logger?.info('镜像下载成功：$mirrorUrl');
        return file;
      }
      _logger?.warn('镜像请求失败，尝试下一个：$mirrorUrl');
    }
    _logger?.err('镜像下载也失败。');
    return null;
  }

  /// 单次 GET 尝试：HTTP 200 返回 body，其余情况（含网络异常）返回 null。
  Future<String?> _tryGet(String url, Duration timeout) async {
    try {
      final resp = await _dio.get<dynamic>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          connectTimeout: timeout,
          receiveTimeout: timeout,
          validateStatus: (_) => true,
        ),
      );
      if (resp.statusCode != 200) return null;
      return resp.data as String;
    } on Object {
      return null;
    }
  }

  /// 单次下载尝试：用 dio 直接落盘到临时文件，并显示进度条。
  ///
  /// HTTP 非 200 / 网络异常时删除半成品文件并返回 null。
  Future<File?> _tryDownload(String url, Duration receiveTimeout) async {
    final tempDir = await Directory.systemTemp.createTemp('fluzer_dl_');
    final savePath = p.join(tempDir.path, 'download.bin');
    final hasTerminal = stdout.hasTerminal;

    try {
      final response = await _dio.download(
        url,
        savePath,
        options: Options(
          receiveTimeout: receiveTimeout,
          validateStatus: (_) => true,
        ),
        onReceiveProgress: (received, total) {
          if (hasTerminal && total > 0) {
            final percent = (received / total * 100).floor();
            final filled = (percent / 100 * 40).floor();
            final bar = '${'=' * filled}>${' ' * (40 - filled - 1)}';
            stdout.write('\r下载模板: [$bar] $percent%');
          }
        },
      );
      if (response.statusCode != 200) {
        await tempDir.delete(recursive: true);
        return null;
      }
      if (hasTerminal) stdout.writeln(); // 换行
      return File(savePath);
    } on Object {
      await tempDir.delete(recursive: true);
      return null;
    }
  }
}
