import 'dart:io';

enum MediaKind { image, gif, video }

MediaKind? mediaKindFromName(String name) {
  if (name.endsWith('.sbs.jpg')) return MediaKind.image;
  if (name.endsWith('.sbs.mp4')) return MediaKind.video;
  return null;
}

/// 首版只展示严格使用规范后缀的 SBS 媒体。
///
/// 合法后缀只有小写 `.sbs.jpg` 和 `.sbs.mp4`。ZIP 文件本身不受此规则
/// 限制；过滤发生在 ZIP 内部媒体条目上。
bool isSbsMediaName(String name) {
  return mediaKindFromName(name) != null;
}

class MediaItem {
  final String name;
  final MediaKind kind;
  final String cacheKey;
  final String localPath;
  final int? size;

  const MediaItem({
    required this.name,
    required this.kind,
    required this.cacheKey,
    required this.localPath,
    this.size,
  });

  bool get isVideo => kind == MediaKind.video;
  bool get isImageLike => kind == MediaKind.image || kind == MediaKind.gif;

  factory MediaItem.local(File file) {
    final kind = mediaKindFromName(file.path);
    if (kind == null) {
      throw ArgumentError.value(file.path, 'file', 'Unsupported media type');
    }
    return MediaItem(
      name: file.path.split(Platform.pathSeparator).last,
      kind: kind,
      cacheKey: file.path,
      localPath: file.path,
      size: file.lengthSync(),
    );
  }

  factory MediaItem.cached({
    required String displayName,
    required String localPath,
    int? size,
  }) {
    final kind = mediaKindFromName(displayName);
    if (kind == null) {
      throw ArgumentError.value(
        displayName,
        'displayName',
        'Unsupported media type',
      );
    }
    return MediaItem(
      name: displayName,
      kind: kind,
      cacheKey: localPath,
      localPath: localPath,
      size: size,
    );
  }
}
