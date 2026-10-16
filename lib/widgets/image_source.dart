import 'stereo_image_cache.dart';

/// 图片来源抽象。
///
/// `StereoView` 只认此接口，首版仅提供本地文件实现。
/// 缓存键由各实现提供，保证同一图片的缓存键空间一致。
abstract class ImageSource {
  /// 缓存键（唯一标识一张图，用于 LRU 去重）。
  const ImageSource();

  String get cacheKey;

  /// 通过 cache 加载并返回 StereoImage。
  Future<StereoImage> load(StereoImageCache cache);
}

/// 本地文件图片源。
class LocalImageSource implements ImageSource {
  final String path;

  const LocalImageSource(this.path);

  @override
  String get cacheKey => path;

  @override
  Future<StereoImage> load(StereoImageCache cache) => cache.getOrWait(path);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LocalImageSource && path == other.path;

  @override
  int get hashCode => path.hashCode;
}
