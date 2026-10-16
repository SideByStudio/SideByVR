import 'package:flutter_test/flutter_test.dart';
import 'package:sidebyvr/widgets/image_source.dart';

void main() {
  group('ImageSource', () {
    test('LocalImageSource.cacheKey 等于 path', () {
      final source = LocalImageSource('/foo/bar.jps');
      expect(source.cacheKey, '/foo/bar.jps');
    });

    test('两个相同 path 的 LocalImageSource 相等', () {
      final a = LocalImageSource('/foo/bar.jps');
      final b = LocalImageSource('/foo/bar.jps');
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });
  });
}
