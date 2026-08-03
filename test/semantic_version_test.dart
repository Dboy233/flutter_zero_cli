import 'package:fluzer/src/util/semantic_version.dart';
import 'package:test/test.dart';

void main() {
  group('SemanticVersion.parse', () {
    test('完整三段', () {
      final v = SemanticVersion.parse('1.2.3');
      expect(v.major, 1);
      expect(v.minor, 2);
      expect(v.patch, 3);
    });

    test('缺段补零', () {
      expect(SemanticVersion.parse('1').patch, 0);
      expect(SemanticVersion.parse('1.2').patch, 0);
    });

    test('非法段按 0 处理', () {
      final v = SemanticVersion.parse('x.y.z');
      expect(v, const SemanticVersion(0, 0, 0));
    });

    test('前导零不影响数值', () {
      expect(SemanticVersion.parse('01.02.03'),
          SemanticVersion.parse('1.2.3'));
    });
  });

  group('SemanticVersion 比较', () {
    test('patch 不同', () {
      expect(SemanticVersion.parse('1.0.0') < SemanticVersion.parse('1.0.1'),
          isTrue);
      expect(SemanticVersion.parse('1.0.1') > SemanticVersion.parse('1.0.0'),
          isTrue);
    });

    test('minor 不同', () {
      expect(SemanticVersion.parse('1.0.9') < SemanticVersion.parse('1.1.0'),
          isTrue);
    });

    test('major 不同', () {
      expect(SemanticVersion.parse('0.9.9') < SemanticVersion.parse('1.0.0'),
          isTrue);
    });

    test('相等', () {
      expect(SemanticVersion.parse('2.3.4') == SemanticVersion.parse('2.3.4'),
          isTrue);
      expect(SemanticVersion.parse('2.3.4') <= SemanticVersion.parse('2.3.4'),
          isTrue);
      expect(SemanticVersion.parse('2.3.4') >= SemanticVersion.parse('2.3.4'),
          isTrue);
    });

    test('compareTo 符号', () {
      expect(
        SemanticVersion.parse('1.0.0').compareTo(SemanticVersion.parse('2.0.0')),
        lessThan(0),
      );
    });
  });

  group('SemanticVersion.toString', () {
    test('往返一致', () {
      expect(SemanticVersion.parse('2.3.4').toString(), '2.3.4');
    });
  });
}
