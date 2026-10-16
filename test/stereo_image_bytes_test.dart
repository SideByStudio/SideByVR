import 'package:flutter_test/flutter_test.dart';
import 'package:sidebyvr/widgets/stereo_image_cache.dart';

void main() {
  group('StereoImage.bytesApprox', () {
    test('返回 width*height*4 之和', () {
      // 用 mock 替代真实 ui.Image 困难，这里只验证静态估算函数
      expect(
        StereoImage.bytesFromDimensions(1920, 2160, 1920, 2160),
        1920 * 2160 * 4 * 2,
      );
    });

    test('1920x2160 双眼约 31.6MB', () {
      final bytes = StereoImage.bytesFromDimensions(1920, 2160, 1920, 2160);
      // 1920*2160*4*2 = 33,177,600 bytes ≈ 31.6MB
      expect(bytes, greaterThan(31 * 1024 * 1024));
      expect(bytes, lessThan(32 * 1024 * 1024));
    });
  });
}
