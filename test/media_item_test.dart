import 'dart:io';

import 'package:sidebyvr/models/media_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mediaKindFromName', () {
    test('识别图片容器与标记视频，不区分大小写', () {
      expect(mediaKindFromName('001.sbs.jpg'), MediaKind.image);
      expect(mediaKindFromName('002.sbs.mp4'), MediaKind.video);
      expect(mediaKindFromName('003.SBS.JPG'), MediaKind.image);
      expect(mediaKindFromName('004.sbs.gif.mp4'), isNull);
      expect(mediaKindFromName('005.sbs.png'), MediaKind.image);
    });

    test('未知后缀不属于媒体', () {
      expect(mediaKindFromName('notes.txt'), isNull);
    });
  });

  group('isSbsMediaName', () {
    test('仅接受规范后缀而不是任意包含 sbs 的名称', () {
      expect(isSbsMediaName('mountain.sbs.jpg'), isTrue);
      expect(isSbsMediaName('clip.sbs.mp4'), isTrue);
      expect(isSbsMediaName('mountain_sbs.jpg'), isFalse);
      expect(isSbsMediaName('clip-sbs.mp4'), isFalse);
      expect(isSbsMediaName('animation.sbs.gif'), isFalse);
      expect(isSbsMediaName('mountain.SBS.JPG'), isTrue);
      expect(isSbsMediaName('normal.jpg'), isFalse);
      expect(isSbsMediaName('sbs-notes.txt'), isFalse);
    });
  });

  test('普通图片需要显式选择，普通视频及未支持格式仍拒绝', () {
    for (final name in ['photo.jpg', 'PHOTO.JPEG', 'album/image.PNG']) {
      expect(isViewableMediaName(name), isFalse);
      expect(isViewableMediaName(name, includeUnmarkedImages: true), isTrue);
    }
    for (final name in [
      'movie.mp4',
      'image.gif',
      'image.jps',
      'image.mpo',
      'image.jpg.txt',
    ]) {
      expect(isViewableMediaName(name, includeUnmarkedImages: true), isFalse);
    }
    expect(isViewableMediaName('IMAGE.SBS.PNG'), isTrue);
  });

  test('本地媒体保留文件信息并区分视频', () {
    final tempDir = Directory.systemTemp.createTempSync('media_item_test_');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final file = File('${tempDir.path}${Platform.pathSeparator}clip.sbs.mp4')
      ..writeAsBytesSync([1, 2, 3]);

    final item = MediaItem.local(file);

    expect(item.name, 'clip.sbs.mp4');
    expect(item.localPath, file.path);
    expect(item.size, 3);
    expect(item.isVideo, isTrue);
    expect(item.isImageLike, isFalse);
  });
}
