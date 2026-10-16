import 'dart:io';

import 'package:sidebyvr/widgets/zip_extractor.dart';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('zip_extractor_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  File makeZip(String name, Map<String, List<int>> files) {
    final archive = Archive();
    for (final entry in files.entries) {
      archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
    }
    final bytes = ZipEncoder().encode(archive)!;
    return File('${tempDir.path}${Platform.pathSeparator}$name')
      ..writeAsBytesSync(bytes);
  }

  test('递归提取规范 SBS 后缀媒体并过滤普通或旧命名文件', () async {
    final zip = makeZip('album.zip', {
      'normal.jpg': [1],
      'folder/scene.sbs.jpg': [2, 3],
      '动画/motion.sbs.mp4': [4, 5, 6],
      'folder/legacy_sbs.jpg': [7],
    });
    final destination = '${tempDir.path}${Platform.pathSeparator}extracted';

    final media = await ZipExtractor.extract(
      zipPath: zip.path,
      destinationPath: destination,
    );

    expect(media.map((item) => item.name), [
      'folder/scene.sbs.jpg',
      '动画/motion.sbs.mp4',
    ]);
    expect(media.every((item) => File(item.localPath).existsSync()), isTrue);
  });

  test('拒绝路径穿越条目', () async {
    final zip = makeZip('unsafe.zip', {
      '../outside.sbs.jpg': [1],
      'safe.sbs.jpg': [2],
    });
    final destination = '${tempDir.path}${Platform.pathSeparator}extracted';

    final media = await ZipExtractor.extract(
      zipPath: zip.path,
      destinationPath: destination,
    );

    expect(media.single.name, 'safe.sbs.jpg');
    expect(
      File(
        '${tempDir.path}${Platform.pathSeparator}outside.sbs.jpg',
      ).existsSync(),
      isFalse,
    );
  });

  test('没有 SBS 媒体时返回明确错误', () async {
    final zip = makeZip('normal.zip', {
      'normal.jpg': [1],
      'readme.txt': [2],
    });

    expect(
      () => ZipExtractor.extract(
        zipPath: zip.path,
        destinationPath: '${tempDir.path}${Platform.pathSeparator}extracted',
      ),
      throwsA(isA<StateError>()),
    );
  });
}
