import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fluzer/src/http/race_http_client.dart';
import 'package:test/test.dart';

/// 可注入的假文本传输：延迟 [delay] 后返回 [result]，记录是否被取消。
///
/// Injectable fake text transport: returns [result] after [delay] and records
/// whether its [CancelToken] was cancelled.
class _FakeTextTransport {
  _FakeTextTransport(this.delay, this.result);

  final Duration delay;
  final String? result;
  CancelToken? capturedToken;
  final Completer<bool> wasCancelled = Completer<bool>();

  Future<String?> call(String url, CancelToken token, Duration? timeout) {
    capturedToken = token;
    token.whenCancel.then((_) {
      if (!wasCancelled.isCompleted) wasCancelled.complete(true);
    });
    return Future.delayed(delay, () => result);
  }
}

/// 可注入的假文件传输：延迟 [delay] 后逐段上报 [steps] 进度，返回 [result]。
///
/// Injectable fake file transport: reports [steps] progress after [delay] and
/// returns [result].
class _FakeFileTransport {
  _FakeFileTransport(this.delay, this.steps, this.result);

  final Duration delay;
  final List<int> steps;
  final DownloadedFile? result;
  CancelToken? capturedToken;
  final Completer<bool> wasCancelled = Completer<bool>();

  Future<DownloadedFile?> call(
    String url,
    CancelToken token,
    Duration? timeout,
    void Function(int received, int total)? onProgress,
  ) async {
    capturedToken = token;
    token.whenCancel.then((_) {
      if (!wasCancelled.isCompleted) wasCancelled.complete(true);
    });
    await Future.delayed(delay);
    for (final step in steps) {
      if (token.isCancelled) break;
      onProgress?.call(step, 100);
      await Future.delayed(Duration.zero);
    }
    return result;
  }
}

/// 会抛异常的假文件传输，用于验证 [RaceFailureCallback]。
///
/// Fake file transport that throws, used to verify [RaceFailureCallback].
class _ThrowingFileTransport {
  _ThrowingFileTransport(this.delay, this.error);

  final Duration delay;
  final Object error;

  Future<DownloadedFile?> call(
    String url,
    CancelToken token,
    Duration? timeout,
    void Function(int received, int total)? onProgress,
  ) async {
    await Future.delayed(delay);
    throw error;
  }
}

/// 永不主动完成的假文本传输；token 被取消时以 null 收尾（模拟"被取消=失败"）。
///
/// Fake text transport that never completes until its token is cancelled.
class _HangTextTransport {
  final List<CancelToken> captured = [];

  Future<String?> call(String url, CancelToken token, Duration? timeout) {
    captured.add(token);
    final c = Completer<String?>();
    token.whenCancel.then((_) => c.complete(null));
    return c.future;
  }
}

void main() {
  group('RaceHttpClient.getTextFirst', () {
    test('先返回者胜出，其余请求被取消', () async {
      final winner = _FakeTextTransport(Duration.zero, 'ok');
      final loser = _FakeTextTransport(const Duration(seconds: 1), 'slow');
      final client = RaceHttpClient(
        textTransport: (url, token, t) =>
            url == 'a' ? winner(url, token, t) : loser(url, token, t),
      );

      final res = await client.getTextFirst(['a', 'b']);

      expect(res?.data, 'ok');
      expect(res?.url, 'a');
      expect(
        await loser.wasCancelled.future.timeout(const Duration(seconds: 2)),
        isTrue,
      );
    });

    test('全部失败返回 null', () async {
      final t1 = _FakeTextTransport(Duration.zero, null);
      final t2 = _FakeTextTransport(Duration.zero, null);
      final client = RaceHttpClient(
        textTransport: (url, token, t) =>
            url == 'a' ? t1(url, token, t) : t2(url, token, t),
      );

      final res = await client.getTextFirst(['a', 'b']);
      expect(res, isNull);
    });

    test('整体超时返回 null 且全部取消', () async {
      final s1 = _FakeTextTransport(const Duration(seconds: 1), 'late');
      final s2 = _FakeTextTransport(const Duration(seconds: 1), 'late');
      final client = RaceHttpClient(
        textTransport: (url, token, t) =>
            url == 'a' ? s1(url, token, t) : s2(url, token, t),
      );

      final res = await client.getTextFirst(
        ['a', 'b'],
        perTimeout: const Duration(seconds: 1),
        overallTimeout: const Duration(milliseconds: 50),
      );
      expect(res, isNull);
      expect(
        await s1.wasCancelled.future.timeout(const Duration(seconds: 2)),
        isTrue,
      );
      expect(
        await s2.wasCancelled.future.timeout(const Duration(seconds: 2)),
        isTrue,
      );
    });

    test('空地址列表返回 null', () async {
      final client = RaceHttpClient(
        textTransport: (url, token, t) => Future<String?>.value('x'),
      );
      expect(await client.getTextFirst([]), isNull);
    });
  });

  group('RaceHttpClient.downloadFileFirst', () {
    late Directory tempDir;
    late File winnerFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('race_dl_');
      winnerFile = File('${tempDir.path}${Platform.pathSeparator}win.bin')
        ..writeAsStringSync('zip-content');
    });

    tearDown(() => tempDir.delete(recursive: true));

    test('先下载完成者胜出，其余被取消', () async {
      final winner = _FakeFileTransport(Duration.zero, const [
        100,
      ], DownloadedFile(winnerFile, tempDir));
      final loser = _FakeFileTransport(const Duration(seconds: 1), const [
        100,
      ], null);
      final client = RaceHttpClient(
        fileTransport: (url, token, t, prog) => url == 'a'
            ? winner(url, token, t, prog)
            : loser(url, token, t, prog),
      );

      final res = await client.downloadFileFirst(['a', 'b']);
      expect(res?.data.file.path, winnerFile.path);
      expect(res?.data.tempDir.path, tempDir.path);
      expect(
        await loser.wasCancelled.future.timeout(const Duration(seconds: 2)),
        isTrue,
      );
    });

    test('进度取当前领先者且只进不退', () async {
      // a 领先到 50 后获胜；b 中途报 20、40（均 <= 50，被钳制）。
      final a = _FakeFileTransport(Duration.zero, const [
        10,
        30,
        50,
      ], DownloadedFile(winnerFile, tempDir));
      final b = _FakeFileTransport(Duration.zero, const [20, 40], null);
      final receivedLog = <int>[];
      final client = RaceHttpClient(
        fileTransport: (url, token, t, prog) =>
            url == 'a' ? a(url, token, t, prog) : b(url, token, t, prog),
      );

      final res = await client.downloadFileFirst([
        'a',
        'b',
      ], onProgress: (url, received, total) => receivedLog.add(received));
      expect(res?.data.file.path, winnerFile.path);
      expect(receivedLog, isNotEmpty);
      for (var i = 1; i < receivedLog.length; i++) {
        expect(
          receivedLog[i],
          greaterThanOrEqualTo(receivedLog[i - 1]),
          reason: '进度应只进不退',
        );
      }
      expect(receivedLog.last, 50);
    });

    test('全部下载失败返回 null', () async {
      final f1 = _FakeFileTransport(Duration.zero, const [100], null);
      final f2 = _FakeFileTransport(Duration.zero, const [100], null);
      final client = RaceHttpClient(
        fileTransport: (url, token, t, prog) =>
            url == 'a' ? f1(url, token, t, prog) : f2(url, token, t, prog),
      );

      final res = await client.downloadFileFirst(['a', 'b']);
      expect(res, isNull);
    });

    test('onFailure 仅对抛异常的候选触发', () async {
      final errors = <String>[];
      final t1 = _ThrowingFileTransport(Duration.zero, Exception('boom-a'));
      final t2 = _ThrowingFileTransport(Duration.zero, Exception('boom-b'));
      final client = RaceHttpClient(
        fileTransport: (url, token, t, prog) =>
            url == 'a' ? t1(url, token, t, prog) : t2(url, token, t, prog),
      );

      final res = await client.downloadFileFirst([
        'a',
        'b',
      ], onFailure: (url, error) => errors.add(url));
      expect(res, isNull);
      // 两个候选都抛异常，应各回调一次（不含被取消的情况）。
      expect(errors, unorderedEquals(['a', 'b']));
    });

    test('cancelAll 取消在飞请求并返回 null', () async {
      final hang = _HangTextTransport();
      // 注意：downloadFileFirst 用 fileTransport，这里复用 hang 不适用；
      // 用文本竞速验证 cancelAll 更合适，故改走 getTextFirst 的 hang 等价物。
      final client = RaceHttpClient(
        textTransport: (url, token, t) {
          hang.captured.add(token);
          final c = Completer<String?>();
          token.whenCancel.then((_) => c.complete(null));
          return c.future;
        },
      );

      final future = client.getTextFirst([
        'a',
        'b',
      ], overallTimeout: const Duration(seconds: 5));
      // 让请求先起飞。
      await Future.delayed(Duration.zero);
      client.cancelAll();
      final res = await future;
      expect(res, isNull);
      expect(hang.captured.every((t) => t.isCancelled), isTrue);
    });
  });

  group('DownloadedFile', () {
    test('dispose 删除临时目录', () async {
      final dir = await Directory.systemTemp.createTemp('downloaded_file_');
      final file = File('${dir.path}${Platform.pathSeparator}data.bin')
        ..writeAsStringSync('x');
      final downloaded = DownloadedFile(file, dir);
      expect(await dir.exists(), isTrue);
      await downloaded.dispose();
      expect(await dir.exists(), isFalse);
    });

    test('dispose 对不存在目录安全', () async {
      final dir = Directory.systemTemp.createTempSync('downloaded_file_');
      final file = File('${dir.path}${Platform.pathSeparator}data.bin');
      final downloaded = DownloadedFile(file, dir);
      await dir.delete(recursive: true);
      // 不应抛异常。
      await downloaded.dispose();
    });
  });
}
