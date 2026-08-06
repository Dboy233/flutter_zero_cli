import 'package:fluzer/src/util/regular_utils.dart';
import 'package:test/test.dart';

void main() {
  test('链接提取版本号', () {
    const String url =
        'https://github.com/Dboy233/flutter_zero_template/releases/download/1.0.0/bricks.zip';
    var version = VersionExtractor.extractVersion(url);
    expect(version, '1.0.0');
  });
}
