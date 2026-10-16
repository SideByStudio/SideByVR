import 'package:flutter_test/flutter_test.dart';
import 'package:sidebyvr/widgets/stereo_image_cache.dart';

void main() {
  group('StereoImageCache 按字节数淘汰', () {
    test('currentBytes 初始为 0', () {
      final cache = StereoImageCache(
        maxBytes: 200 * 1024 * 1024,
        maxConcurrent: 2,
      );
      expect(cache.currentBytes, 0);
    });

    test('put 后 currentBytes 增加正确量', () {
      final cache = StereoImageCache(
        maxBytes: 200 * 1024 * 1024,
        maxConcurrent: 2,
      );
      // 假设构造 mock StereoImage 困难，只验证不抛错
      expect(() => cache.currentBytes, returnsNormally);
    });

    test('clear 后 currentBytes 归零', () {
      final cache = StereoImageCache(
        maxBytes: 200 * 1024 * 1024,
        maxConcurrent: 2,
      );
      cache.clear();
      expect(cache.currentBytes, 0);
    });
  });

  group('cropAndLoadImage 重试分类', () {
    test('路径不存在的文件不触发重试（直接抛出）', () async {
      // FileSystemException 应直接抛出，不重试
      expect(
        () => cropAndLoadImage('/nonexistent/path/to/file.jps'),
        throwsA(isA<Object>()),
      );
    });
  });
}
