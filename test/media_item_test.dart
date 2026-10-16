import 'dart:io';

import 'package:sidebyvr/models/media_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mediaKindFromName', () {
    test('只识别精确的小写 .sbs.jpg 与 .sbs.mp4 后缀', () {
      expect(mediaKindFromName('001.sbs.jpg'), MediaKind.image);
      expect(mediaKindFromName('002.sbs.mp4'), MediaKind.video);
      expect(mediaKindFromName('003.SBS.JPG'), isNull);
      expect(mediaKindFromName('004.sbs.gif.mp4'), isNull);
      expect(mediaKindFromName('005.sbs.png'), isNull);
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
      expect(isSbsMediaName('mountain.SBS.JPG'), isFalse);
      expect(isSbsMediaName('normal.jpg'), isFalse);
      expect(isSbsMediaName('sbs-notes.txt'), isFalse);
    });
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
