import 'package:fluzer/src/util/regular_utils.dart';
import 'package:fluzer/src/util/string_case.dart';
import 'package:test/test.dart';

void main() {
  group('VersionExtractor.extractVersion', () {
    test('release 路径含版本号', () {
      expect(
        VersionExtractor.extractVersion(
          'https://github.com/owner/repo/releases/download/1.0.0/bricks.zip',
        ),
        '1.0.0',
      );
    });

    test('v 前缀版本号', () {
      expect(
        VersionExtractor.extractVersion(
          'https://github.com/owner/repo/releases/download/v2.3.4/bricks.zip',
        ),
        '2.3.4',
      );
    });

    test('带预发布/构建元数据只取主版本段', () {
      expect(
        VersionExtractor.extractVersion('https://x/v1.2.3-beta.1+build.5/file'),
        '1.2.3',
      );
    });

    test('无版本号返回 null', () {
      expect(VersionExtractor.extractVersion('https://x.com/latest/bricks.zip'), isNull);
    });
  });

  group('CaseConverter.toPascalCase', () {
    test('多段 snake_case', () {
      expect(CaseConverter.toPascalCase('user_profile'), 'UserProfile');
    });
    test('单段', () {
      expect(CaseConverter.toPascalCase('user'), 'User');
    });
    test('空串', () {
      expect(CaseConverter.toPascalCase(''), '');
    });
    test('连续段与已大写首字母', () {
      expect(CaseConverter.toPascalCase('a_b_c'), 'ABC');
    });
  });
}
