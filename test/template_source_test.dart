import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fluzer/src/config/project_config.dart';
import 'package:fluzer/src/config/template_config.dart';
import 'package:fluzer/src/http/http_client.dart';
import 'package:fluzer/src/template/template_source.dart';
import 'package:test/test.dart';

/// 启动一个本地 HTTP 服务，按 path 返回不同 registry JSON，返回服务地址。
Future<(HttpServer, String)> _startRegistryServer(String registryJson) async {
  final server = await HttpServer.bind('127.0.0.1', 0);
  server.listen((req) async {
    req.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(registryJson);
    await req.response.close();
  });
  final url = 'http://127.0.0.1:${server.port}/template_registry.json';
  return (server, url);
}

const _twoVersions = '''
{
  "templates": [
    {"minCliVersion": "1.0.0", "version": "1.0.0", "url": "https://x/1.0.0.zip"},
    {"minCliVersion": "1.1.0", "version": "1.0.1", "url": "https://x/1.0.1.zip"}
  ]
}''';

void main() {
  late HttpServer server;
  late String registryUrl;
  late FluzerHttpClient client;
  late TemplateSourceResolver resolver;

  setUp(() async {
    client = FluzerHttpClient(dio: Dio());
    resolver = TemplateSourceResolver(httpClient: client);
  });

  tearDown(() => server.close(force: true));

  group('selectTemplateZipUrl (按 CLI 版本选最大兼容)', () {
    setUp(() async {
      final r = await _startRegistryServer(_twoVersions);
      server = r.$1;
      registryUrl = r.$2;
    });

    test('cliVersion 1.1.0 时选 version 最大且兼容者 (1.0.1)', () async {
      // cliVersion 为常量 '1.1.0'，两条均 <= 1.1.0，取最大 version。
      final result = await resolver.selectLatest(registryUrl: registryUrl);
      expect(result.version, '1.0.1');
      expect(result.url, 'https://x/1.0.1.zip');
    });

    test('registry 拉取失败（500）→ 回退 defaultTemplateZipUrl', () async {
      await server.close(force: true);
      final bad = await HttpServer.bind('127.0.0.1', 0);
      bad.listen((req) async {
        req.response.statusCode = 500;
        await req.response.close();
      });
      server = bad;
      final result = await resolver.selectLatest(
        registryUrl: 'http://127.0.0.1:${bad.port}/x',
      );
      expect(result.url, defaultTemplateZipUrl);
    });

    test('无兼容条目 → 回退 defaultTemplateZipUrl', () async {
      final r = await _startRegistryServer('''
      {"templates": [
        {"minCliVersion": "9.9.9", "version": "9.9.9", "url": "https://x/9.9.9.zip"}
      ]}''');
      await server.close(force: true);
      server = r.$1;
      final result = await resolver.selectLatest(registryUrl: r.$2);
      expect(result.url, defaultTemplateZipUrl);
    });
  });

  group('selectTemplateZipUrlForVersion (按精确版本钉死)', () {
    setUp(() async {
      final r = await _startRegistryServer(_twoVersions);
      server = r.$1;
      registryUrl = r.$2;
    });

    test('命中精确版本 → 返回其 url 与 version', () async {
      final result = await resolver.selectExact(
        '1.0.1',
        registryUrl: registryUrl,
      );
      expect(result.url, 'https://x/1.0.1.zip');
      expect(result.version, '1.0.1');
    });

    test('版本未收录 → 抛 CliException', () async {
      expect(
        () => resolver.selectExact('9.9.9', registryUrl: registryUrl),
        throwsA(isA<CliException>()),
      );
    });

    test('命中但 url 缺失 → 抛 CliException', () async {
      final r = await _startRegistryServer('''
      {"templates": [
        {"minCliVersion": "1.0.0", "version": "1.0.0"}
      ]}''');
      await server.close(force: true);
      server = r.$1;
      expect(
        () => resolver.selectExact('1.0.0', registryUrl: r.$2),
        throwsA(isA<CliException>()),
      );
    });

    test('registry 拉取失败 → 抛 CliException', () async {
      await server.close(force: true);
      final bad = await HttpServer.bind('127.0.0.1', 0);
      bad.listen((req) async {
        req.response.statusCode = 500;
        await req.response.close();
      });
      server = bad;
      expect(
        () => resolver.selectExact(
          '1.0.1',
          registryUrl: 'http://127.0.0.1:${bad.port}/x',
        ),
        throwsA(isA<CliException>()),
      );
    });
  });
}
