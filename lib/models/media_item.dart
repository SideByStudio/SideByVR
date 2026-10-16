import 'dart:io';

enum MediaKind { image, gif, video }

/// Recognizes supported containers, not whether their contents are stereo.
MediaKind? mediaKindFromName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png')) {
    return MediaKind.image;
  }
  if (lower.endsWith('.sbs.mp4')) return MediaKind.video;
  return null;
}

/// Explicit naming is the safe default; ordinary photos require user opt-in.
bool isSbsMediaName(String name) {
  final lower = name.toLowerCase();
  return ['.sbs.jpg', '.sbs.jpeg', '.sbs.png', '.sbs.mp4'].any(lower.endsWith);
}

bool isViewableMediaName(String name, {bool includeUnmarkedImages = false}) {
  return isSbsMediaName(name) ||
      (includeUnmarkedImages && mediaKindFromName(name) == MediaKind.image);
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
