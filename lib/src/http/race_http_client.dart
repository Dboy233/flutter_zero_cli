// 并发竞速 HTTP 客户端：给定候选地址列表，谁先返回有效数据就采用谁，
// 其余请求立即用 CancelToken 取消，避免顺序回退时逐个等待超时。
//
// Race HTTP client: given a list of candidate URLs, the first to return
// valid data wins and the remaining requests are cancelled immediately via
// CancelToken, so we never wait for the first URL to time out before trying
// the next one.

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

/// 竞速结果：数据 + 实际获胜的 URL（用于日志）。
///
/// Race result: the payload plus the URL that actually won (for logging).
class RaceResult<T> {
  /// 创建竞速结果。
  ///
  /// Creates a race result.
  const RaceResult(this.data, this.url);

  /// 获胜请求返回的数据。
  ///
  /// The data returned by the winning request.
  final T data;

  /// 实际获胜的候选 URL。
  ///
  /// The candidate URL that won.
  final String url;
}

/// 下载得到的文件与其所在临时目录。
///
/// 用完后调用 [dispose] 清理临时目录，避免 `systemTemp` 堆积。相比直接返回
/// 裸 `File`、再由调用方用 `file.parent` 推断临时目录，此处显式携带
/// [tempDir] 让清理职责清晰、解耦。
///
/// A downloaded file together with its owning temp directory. Call [dispose]
/// when done to clean up, instead of relying on `file.parent` inference.
class DownloadedFile {
  /// 创建下载文件描述。
  ///
  /// Creates a downloaded file description.
  const DownloadedFile(this.file, this.tempDir);

  /// 胜出下载落盘的文件。
  ///
  /// The downloaded file on disk.
  final File file;

  /// 文件所在的临时目录（调用方负责在 [dispose] 中清除）。
  ///
  /// The temp directory holding [file; cleared by [dispose].
  final Directory tempDir;

  /// 删除临时目录，释放磁盘空间。
  ///
  /// Deletes the temp directory.
  Future<void> dispose() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }
}

/// 文本 GET 传输函数（可注入，便于测试）。
///
/// [url] 候选地址；[token] 用于取消；[timeout] 单请求超时。
/// 返回响应体字符串；非 200 或异常应返回 `null`。
///
/// Text GET transport (injectable for testing). Returns the response body,
/// or `null` on non-200 / error.
typedef TextTransport =
    Future<String?> Function(String url, CancelToken token, Duration? timeout);

/// 文件下载传输函数（可注入，便于测试）。
///
/// [url] 候选地址；[token] 用于取消；[timeout] 单请求超时；
/// [onProgress] 进度回调（received / total）。
/// 返回下载得到的 [DownloadedFile]；非 200 或异常应返回 `null`。
///
/// File download transport (injectable for testing). Returns the downloaded
/// [DownloadedFile], or `null` on non-200 / error.
typedef FileTransport =
    Future<DownloadedFile?> Function(
      String url,
      CancelToken token,
      Duration? timeout,
      void Function(int received, int total)? onProgress,
    );

/// 候选失败回调：[url] 为失败的候选地址，[error] 为抛出的异常
///（含超时、网络错误、被取消等）。
///
/// Per-candidate failure callback: [url] is the failed candidate and [error]
/// is the thrown exception.
typedef RaceFailureCallback = void Function(String url, Object error);

/// 并发竞速 HTTP 客户端（门面）。
///
/// 对外只暴露 [getTextFirst] / [downloadFileFirst] 两个方法；每个方法构造
/// [_RaceManager] 并调用其 [startRace] 并发发起所有候选请求，第一个成功者胜出
/// 并取消其余。传输实现可注入（[textTransport] / [fileTransport]），便于单测
/// 用假实现确定性验证。
///
/// Concurrent race HTTP client (facade). Exposes [getTextFirst] /
/// [downloadFileFirst]; each builds a [_RaceManager] and calls its [startRace]
/// to fire all candidates in parallel, completing with the first success while
/// cancelling the rest. Transports are injectable for deterministic tests.
class RaceHttpClient {
  /// 创建竞速客户端。
  ///
  /// [dio] 真实 Dio 实例（省略时新建）；[textTransport] / [fileTransport]
  /// 注入自定义传输（测试用），省略时回落到基于 [dio] 的默认实现。
  ///
  /// Creates a race client. [dio] is the real Dio instance (a new one is
  /// created if omitted). [textTransport] / [fileTransport] inject custom
  /// transports for tests; when omitted the Dio-based defaults are used.
  RaceHttpClient({Dio? dio, this._textTransport, this._fileTransport})
    : _dio = dio ?? Dio();

  final Dio _dio;
  final TextTransport? _textTransport;
  final FileTransport? _fileTransport;

  /// 在飞请求的 token 集合，供 [cancelAll] 主动取消。
  ///
  /// Active request tokens, used by [cancelAll].
  final Set<CancelToken> _activeTokens = {};

  /// 文本 GET 单请求超时（也是整体超时默认值）。
  ///
  /// Per-request (and default overall) timeout for text GET.
  static const Duration defaultTextTimeout = Duration(seconds: 30);

  /// 文件下载单请求超时（也是整体超时默认值）。
  ///
  /// Per-request (and default overall) timeout for file download.
  static const Duration defaultFileTimeout = Duration(seconds: 180);

  /// 取消所有在飞请求（进程退出 / 命令中止时调用）。
  ///
  /// Cancels every in-flight request (e.g. on process exit / command abort).
  void cancelAll() {
    for (final token in _activeTokens) {
      token.cancel();
    }
  }

  /// 并发 GET 文本，返回首个成功响应体（含获胜 URL）；全部失败返回 `null`。
  ///
  /// [onFailure] 在每个候选**抛异常**失败时调用（被取消的候选也会触发，
  /// 调用方可据此过滤取消类异常）。[perTimeout] 为单请求超时，[overallTimeout]
  /// 为整体硬上限：任一超过即取消全部并返回 `null`（因此整体超时通常应是
  /// 真正的"最长等待"，可与单请求超时相等或更短）。
  ///
  /// Races text GETs and returns the first successful body (with the winning
  /// URL). Returns `null` if all candidates fail. [onFailure] is invoked when
  /// a candidate throws (including cancellation). [overallTimeout] is the hard
  /// cap: once exceeded every request is cancelled.
  Future<RaceResult<String>?> getTextFirst(
    List<String> urls, {
    Duration? perTimeout,
    Duration? overallTimeout,
    RaceFailureCallback? onFailure,
  }) {
    final timeout = perTimeout ?? defaultTextTimeout;
    final overall = overallTimeout ?? defaultTextTimeout;
    final transport =
        _textTransport ??
        (String url, CancelToken token, Duration? t) => _dioGet(url, token, t);
    final manager = _RaceManager<String>(urls, overall, onFailure, null);
    _trackTokens(manager);
    return manager.startRace((url, token, _) => transport(url, token, timeout));
  }

  /// 并发下载文件，返回首个成功下载的 [DownloadedFile]（含获胜 URL）；
  /// 全部失败返回 `null`。
  ///
  /// [onProgress] 仅反映「当前领先者」的进度（同文件各镜像 total 相等，
  /// 取 received 最大者为领先者），并做只进不退钳制，避免竞速期间进度条抖动。
  /// 其余参数同 [getTextFirst]。
  ///
  /// Races file downloads and returns the first successful [DownloadedFile]
  /// (with the winning URL). [onProgress] reflects only the current leader's
  /// progress (candidates serve the same file, so totals are equal; the max
  /// `received` wins), clamped to never decrease.
  Future<RaceResult<DownloadedFile>?> downloadFileFirst(
    List<String> urls, {
    String tempPrefix = 'fluzer_dl_',
    Duration? perTimeout,
    Duration? overallTimeout,
    void Function(String url, int received, int total)? onProgress,
    RaceFailureCallback? onFailure,
  }) {
    final timeout = perTimeout ?? defaultFileTimeout;
    final overall = overallTimeout ?? defaultFileTimeout;
    final transport =
        _fileTransport ??
        (String url, CancelToken token, Duration? t, prog) {
          return _dioDownload(url, token, t, tempPrefix, prog);
        };
    final manager = _RaceManager<DownloadedFile>(
      urls,
      overall,
      onFailure,
      onProgress,
    );
    _trackTokens(manager);
    return manager.startRace(
      (url, token, prog) => transport(url, token, timeout, prog),
    );
  }

  /// 登记在飞令牌供 [cancelAll] 主动取消；竞速结束后自动移除，避免集合无限增长。
  ///
  /// Registers in-flight tokens for [cancelAll]; auto-removed when the race
  /// completes so the set does not grow unbounded.
  void _trackTokens<T>(_RaceManager<T> manager) {
    _activeTokens.removeWhere((t) => t.isCancelled);
    _activeTokens.addAll(manager.tokens);
    unawaited(
      manager.future.whenComplete(
        () => _activeTokens.removeAll(manager.tokens),
      ),
    );
  }

  /// 默认文本 GET 传输（基于 Dio）。
  ///
  /// Default text GET transport (Dio-based).
  Future<String?> _dioGet(
    String url,
    CancelToken token,
    Duration? timeout,
  ) async {
    try {
      final resp = await _dio.get<dynamic>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          connectTimeout: timeout,
          receiveTimeout: timeout,
          validateStatus: (_) => true,
        ),
        cancelToken: token,
      );
      if (resp.statusCode != 200) return null;
      return resp.data as String;
    } on Object {
      return null;
    }
  }

  /// 默认文件下载传输（基于 Dio，落盘临时目录）。
  ///
  /// Default file download transport (Dio-based, to a temp dir).
  Future<DownloadedFile?> _dioDownload(
    String url,
    CancelToken token,
    Duration? timeout,
    String tempPrefix,
    void Function(int received, int total)? onProgress,
  ) async {
    final tempDir = await Directory.systemTemp.createTemp(tempPrefix);
    final savePath = '${tempDir.path}${Platform.pathSeparator}download.bin';
    try {
      final response = await _dio.download(
        url,
        savePath,
        options: Options(receiveTimeout: timeout, validateStatus: (_) => true),
        cancelToken: token,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress?.call(received, total);
        },
      );
      if (response.statusCode != 200) {
        await tempDir.delete(recursive: true);
        return null;
      }
      return DownloadedFile(File(savePath), tempDir);
    } on Object {
      // createTemp 可能已失败（此时目录不存在），先判断再删，避免二次异常。
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
      return null;
    }
  }
}

/// 竞速管理者：持有所有候选的统筹状态（完成器、取消令牌、超时计时器、"全部
/// 失败"计数、进度领先者），并以方法表达胜负判定、整齐取消与统一收尾，另提供
/// [startRace] 驱动整个竞速。各候选的执行细节由 [_Competitor] 负责；竞争者通过
/// 注入的回调（即本管理者的 win / markSoftFailure / markHardFailure /
/// reportProgress 方法）上报结果，互不认识。
///
/// Race manager: owns the orchestration state for all candidates and expresses
/// win/lose resolution, bulk cancellation and unified completion as methods,
/// plus [startRace] to drive the whole race. Each candidate's execution lives
/// in [_Competitor], which reports back via injected callbacks (this manager's
/// own methods), so workers stay decoupled from the manager type.
class _RaceManager<T> {
  _RaceManager(
    List<String> urls,
    this.overallTimeout,
    this.onFailure,
    this.onProgress,
  ) : urls = urls,
      tokens = [for (final _ in urls) CancelToken()],
      pendingFailures = urls.length;

  final List<String> urls;
  final Duration overallTimeout;
  final RaceFailureCallback? onFailure;

  /// 对外进度回调（下载竞速用，文本 GET 为 `null`）。
  final void Function(String url, int received, int total)? onProgress;

  final Completer<RaceResult<T>?> completer = Completer<RaceResult<T>?>();

  /// 每个候选对应的取消令牌。
  final List<CancelToken> tokens;

  bool _settled = false;

  /// 仅用于「全部候选均失败」判定：胜者出现会直接 [_settle]，不在此递减。
  int pendingFailures;

  Timer? _timer;

  /// 当前领先者（进度展示用，非胜者）：received 最大者。
  int _bestReceived = 0;
  String? _bestUrl;

  /// 竞速结果 Future。
  Future<RaceResult<T>?> get future => completer.future;

  /// 注册整体超时：到点取消全部候选并完成 `null`。
  void armTimeout() {
    _timer = Timer(overallTimeout, () {
      if (_settled) return;
      _settle(null);
      for (final token in tokens) {
        token.cancel();
      }
    });
  }

  /// 取消除 [winner] 外的所有候选。
  void cancelOthers(int winner) {
    for (var i = 0; i < tokens.length; i++) {
      if (i != winner) tokens[i].cancel();
    }
  }

  /// 某候选完整成功 → 它胜出。
  void win(int index, T result) {
    if (_settled) return;
    cancelOthers(index);
    _settle(RaceResult<T>(result, urls[index]));
  }

  /// 某候选软失败（返回 `null`，不含异常）：递减失败计数。
  void markSoftFailure() {
    if (_settled) return;
    pendingFailures--;
    if (pendingFailures == 0) _settle(null);
  }

  /// 某候选硬失败（抛异常）：先回调 [onFailure]，再按软失败处理。
  void markHardFailure(String url, Object error) {
    if (_settled) return;
    onFailure?.call(url, error);
    markSoftFailure();
  }

  /// 进度上报（下载竞速用）：同一文件各镜像 total 相等，取 received 最大者为
  /// 领先者并做只进不退钳制，再透传对外 [onProgress]。
  void reportProgress(String url, int received, int total) {
    if (onProgress == null) return;
    if (_bestUrl == null || received > _bestReceived) {
      _bestReceived = received;
      _bestUrl = url;
      onProgress!(url, received, total);
    }
  }

  /// 统一收尾：保证只完成一次，并清理计时器。
  void _settle(RaceResult<T>? value) {
    if (_settled) return;
    _settled = true;
    _timer?.cancel();
    completer.complete(value);
  }

  /// 驱动竞速：注册整体超时，并为每个候选创建 [_Competitor] 启动其请求。
  /// 各竞争者通过本管理者的 win / markSoftFailure / markHardFailure /
  /// reportProgress 方法（以函数形式注入）上报结果，互不认识。
  ///
  /// Drives the race: arms the overall timeout and starts a [_Competitor] per
  /// candidate. Workers report back via this manager's methods (injected as
  /// functions), so they stay decoupled from the manager type.
  Future<RaceResult<T>?> startRace(
    Future<T?> Function(
      String url,
      CancelToken token,
      void Function(int received, int total)? onProgress,
    )
    runner,
  ) {
    if (urls.isEmpty) {
      _settle(null);
      return future;
    }
    armTimeout();
    for (var i = 0; i < urls.length; i++) {
      unawaited(
        _Competitor<T>(
          index: i,
          url: urls[i],
          token: tokens[i],
          runner: runner,
          onWon: win,
          onFailed: (_) => markSoftFailure(),
          onErrored: markHardFailure,
          onProgress: (received, total) =>
              reportProgress(urls[i], received, total),
        ).run(),
      );
    }
    return future;
  }
}

/// 单个候选的执行者：持有自己的地址、取消令牌与传输函数，负责发起这一路请求，
/// 并把结果（成功 / 软失败 / 硬失败 / 进度）上报给管理者。管理者在构造时通过
/// 回调注入胜负判定逻辑，二者无循环引用。
///
/// A single race competitor (worker): owns its URL, cancel token and transport,
/// runs its own request, and reports the outcome (win / soft-fail / hard-fail /
/// progress) back to the manager via injected callbacks.
class _Competitor<T> {
  _Competitor({
    required this.index,
    required this.url,
    required this.token,
    required this.runner,
    required this.onWon,
    required this.onFailed,
    required this.onErrored,
    required this.onProgress,
  });

  final int index;
  final String url;
  final CancelToken token;

  /// 执行本路请求的传输函数（进度回调可选，文本 GET 忽略）。
  final Future<T?> Function(
    String url,
    CancelToken token,
    void Function(int received, int total)? onProgress,
  )
  runner;

  final void Function(int index, T result) onWon;
  final void Function(int index) onFailed;
  final void Function(String url, Object error) onErrored;

  /// transport 的进度回调（不含 url 形态，由管理者在注入时补充）。
  final void Function(int received, int total)? onProgress;

  /// 启动本路请求：成功回调 [onWon]，返回 `null` 回调 [onFailed]，抛异常回调
  /// [onErrored]。用 async/await 而非 `.then/.catchError`，可读性更高。
  ///
  /// Runs this competitor: reports a win on success, a soft failure on `null`,
  /// or a hard failure on throw.
  Future<void> run() async {
    try {
      final result = await runner(url, token, onProgress);
      if (result != null) {
        onWon(index, result);
      } else {
        onFailed(index);
      }
    } on Object catch (error) {
      onErrored(url, error);
    }
  }
}
