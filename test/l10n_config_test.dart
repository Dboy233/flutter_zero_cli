// L10nConfig.load 单元测试 / Unit tests for L10nConfig.load.
//
// 覆盖：文件缺失回退 defaults、YAML 非 Map 回退 defaults、字段缺失回退、
// 完整字段解析、synthetic-package 与 output-dir 的交互回退策略。
//
// Covers: missing-file fallback, non-Map YAML fallback, field-missing
// fallback, full-field parsing, and synthetic-package/output-dir interaction.

import 'dart:io';

import 'package:fluzer/src/gen_l10n/l10n_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('l10n_config_');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<File> writeYaml(Map<String, Object> yaml) async {
    final file = File(p.join(tempDir.path, 'l10n.yaml'));
    final buffer = StringBuffer();
    yaml.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    await file.writeAsString(buffer.toString());
    return file;
  }

  test('文件不存在回退 defaults', () async {
    final config = await L10nConfig.load(tempDir.path);
    expect(config.arbDir, 'lib/l10n');
    expect(config.outputDir, 'lib/l10n/gen');
    expect(config.outputLocalizationFile, 'app_localizations.dart');
    expect(config.outputClass, 'AppLocalizations');
  });

  test('YAML 非 Map 回退 defaults', () async {
    final file = File(p.join(tempDir.path, 'l10n.yaml'));
    await file.writeAsString('- just\n- a\n- list\n');
    final config = await L10nConfig.load(tempDir.path);
    expect(config.arbDir, 'lib/l10n');
    expect(config.outputDir, 'lib/l10n/gen');
    expect(config.outputLocalizationFile, 'app_localizations.dart');
    expect(config.outputClass, 'AppLocalizations');
  });

  test('字段缺失回退默认值', () async {
    await writeYaml({'arb-dir': 'lib/i18n'});
    final config = await L10nConfig.load(tempDir.path);
    expect(config.arbDir, 'lib/i18n');
    // 无 synthetic-package 且无 output-dir → 默认 output-dir
    expect(config.outputDir, 'lib/l10n/gen');
    expect(config.outputLocalizationFile, 'app_localizations.dart');
    expect(config.outputClass, 'AppLocalizations');
  });

  test('完整字段解析', () async {
    await writeYaml({
      'arb-dir': 'lib/i18n',
      'output-dir': 'lib/generated',
      'output-localization-file': 'messages.dart',
      'output-class': 'Messages',
    });
    final config = await L10nConfig.load(tempDir.path);
    expect(config.arbDir, 'lib/i18n');
    expect(config.outputDir, 'lib/generated');
    expect(config.outputLocalizationFile, 'messages.dart');
    expect(config.outputClass, 'Messages');
  });

  test('synthetic-package: true 且无 output-dir → flutterGenFallbackDir', () async {
    await writeYaml({'synthetic-package': true});
    final config = await L10nConfig.load(tempDir.path);
    expect(config.outputDir, L10nConfig.flutterGenFallbackDir);
  });

  test('synthetic-package: true 且有 output-dir → 使用显式值', () async {
    await writeYaml({
      'synthetic-package': true,
      'output-dir': 'lib/custom',
    });
    final config = await L10nConfig.load(tempDir.path);
    expect(config.outputDir, 'lib/custom');
  });

  test('synthetic-package: false 且无 output-dir → 默认 output-dir', () async {
    await writeYaml({'synthetic-package': false});
    final config = await L10nConfig.load(tempDir.path);
    expect(config.outputDir, 'lib/l10n/gen');
  });
}
