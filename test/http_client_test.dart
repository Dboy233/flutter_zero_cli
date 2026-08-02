import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fluzer/src/http/http_client.dart';
import 'package:test/test.dart';

void main() {
  group('FluzerHttpClient.getText', () {
    late HttpServer server;
    late int port;

    setUp(() async {
      server = await HttpServer.bind('127.0.0.1', 0);
      port = server.port;
    });

    tearDown(() => server.close(force: true));

    test('200 → 返回 body', () async {
      server.listen((req) async {
        req.response
          ..statusCode = 200
          ..write('hello-world');
        await req.response.close();
      });
      final client = FluzerHttpClient(dio: Dio());
      final body = await client.getText('http://127.0.0.1:$port/ok');
      expect(body, 'hello-world');
    });

    test('非 200 → 返回 null（直连失败时镜像也失败）', () async {
      server.listen((req) async {
        req.response.statusCode = 404;
        await req.response.close();
      });
      final client = FluzerHttpClient(dio: Dio());
      final body = await client.getText('http://127.0.0.1:$port/missing');
      expect(body, isNull);
    });

    test('连接失败 → 返回 null', () async {
      // 关闭服务后用不可达端口请求
      await server.close(force: true);
      final deadPort = port;
      final client = FluzerHttpClient(dio: Dio());
      final body = await client.getText('http://127.0.0.1:$deadPort/x');
      expect(body, isNull);
    });
  });

  group('FluzerHttpClient.downloadFile', () {
    late HttpServer server;
    late int port;

    setUp(() async {
      server = await HttpServer.bind('127.0.0.1', 0);
      port = server.port;
    });

    tearDown(() => server.close(force: true));

    test('200 → 返回文件且内容一致', () async {
      server.listen((req) async {
        req.response
          ..statusCode = 200
          ..headers.contentType = ContentType.text
          ..write('zip-content');
        await req.response.close();
      });
      final client = FluzerHttpClient(dio: Dio());
      final downloaded = await client.downloadFile('http://127.0.0.1:$port/dl');
      expect(downloaded, isNotNull);
      expect(await downloaded!.file.readAsString(), 'zip-content');
      await downloaded.dispose();
    });

    test('非 200 → 返回 null', () async {
      server.listen((req) async {
        req.response.statusCode = 500;
        await req.response.close();
      });
      final client = FluzerHttpClient(dio: Dio());
      final file = await client.downloadFile('http://127.0.0.1:$port/fail');
      expect(file, isNull);
    });
  });
}
