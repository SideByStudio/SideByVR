// lib/widgets/stereo_image_cache.dart
import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// 裁剪后的左右眼图片
class StereoImage {
  final ui.Image left;
  final ui.Image right;

  /// 估算的字节数（width*height*4，左右眼之和），用于 LRU 按字节淘汰。
  final int bytesApprox;

  const StereoImage({
    required this.left,
    required this.right,
    required this.bytesApprox,
  });

  /// 按 RGBA8888 估算双眼总字节数。
  static int bytesFromDimensions(int leftW, int leftH, int rightW, int rightH) {
    return (leftW * leftH + rightW * rightH) * 4;
  }

  /// 释放图片资源
  void dispose() {
    left.dispose();
    right.dispose();
  }
}

/// 在 Isolate 中裁剪图片，返回左右眼的 JPEG 字节
/// 使用 JPEG 代替 PNG 可以：
/// 1. 减少内存使用（JPEG 压缩率更高）
/// 2. 加快 Flutter 的 ui.decodeImageFromList 处理速度
/// 3. 避免某些 PNG 解码问题
(Uint8List, Uint8List) _cropImageIsolate(String imagePath) {
  final bytes = File(imagePath).readAsBytesSync();
  final image = img.decodeImage(bytes)!;
  final halfWidth = image.width ~/ 2;

  final left = img.copyCrop(
    image,
    x: 0,
    y: 0,
    width: halfWidth,
    height: image.height,
  );
  final right = img.copyCrop(
    image,
    x: halfWidth,
    y: 0,
    width: halfWidth,
    height: image.height,
  );

  return (img.encodeJpg(left, quality: 90), img.encodeJpg(right, quality: 90));
}

/// 裁剪图片并返回 StereoImage（带超时重试）
Future<StereoImage> cropAndLoadImage(
  String imagePath, {
  int maxRetries = 3,
}) async {
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      // 在 Isolate 中执行裁剪
      final (leftBytes, rightBytes) = await Isolate.run(
        () => _cropImageIsolate(imagePath),
      );

      // 解码为 ui.Image（带超时）
      final leftCompleter = Completer<ui.Image>();
      final rightCompleter = Completer<ui.Image>();

      ui.decodeImageFromList(leftBytes, (image) {
        if (!leftCompleter.isCompleted) leftCompleter.complete(image);
      });
      ui.decodeImageFromList(rightBytes, (image) {
        if (!rightCompleter.isCompleted) rightCompleter.complete(image);
      });

      // 10 秒超时
      final results = await Future.wait([
        leftCompleter.future.timeout(Duration(seconds: 10)),
        rightCompleter.future.timeout(Duration(seconds: 10)),
      ]);

      return StereoImage(
        left: results[0],
        right: results[1],
        bytesApprox: StereoImage.bytesFromDimensions(
          results[0].width,
          results[0].height,
          results[1].width,
          results[1].height,
        ),
      );
    } catch (e) {
      if (attempt == maxRetries) rethrow;
      if (!_isRetryableError(e)) rethrow; // 文件错误不重试
      debugPrint('图片加载失败，重试 $attempt/$maxRetries: $imagePath - $e');
      // 指数退避：100ms / 200ms / 400ms
      await Future.delayed(Duration(milliseconds: 100 * (1 << attempt)));
    }
  }
  throw StateError('图片加载失败: $imagePath');
}

/// 信号量，控制并发数量
class _Semaphore {
  int _count;
  final Queue<Completer<void>> _queue = Queue();

  _Semaphore(int max) : _count = max;

  /// 获取许可
  Future<void> acquire() async {
    if (_count > 0) {
      _count--;
      return;
    }
    final completer = Completer<void>();
    _queue.add(completer);
    await completer.future;
  }

  /// 释放许可
  void release() {
    if (_queue.isNotEmpty) {
      _queue.removeFirst().complete();
    } else {
      _count++;
    }
  }
}

/// 判断错误是否值得重试。
bool _isRetryableError(Object e) {
  // 文件不存在、IO 错误直接抛出；解码等瞬时异常允许重试。
  if (e is FileSystemException) return false;
  return true;
}

/// LRU 缓存，支持按字节数淘汰、Completer 通知和并发控制
class StereoImageCache {
  /// 最大字节数（如 200MB）
  final int maxBytes;
  final int maxConcurrent;
  final LinkedHashMap<String, StereoImage> _cache = LinkedHashMap();
  final Map<String, int> _bytesByKey = {}; // 每个键的字节数
  final Map<String, Completer<StereoImage>> _pending = {};
  late final _Semaphore _semaphore;
  int _currentBytes = 0;

  StereoImageCache({
    this.maxBytes = 200 * 1024 * 1024,
    this.maxConcurrent = 2,
  }) {
    _semaphore = _Semaphore(maxConcurrent);
  }

  /// 当前缓存总字节数
  int get currentBytes => _currentBytes;

  /// 获取缓存，命中则移到最近使用位置
  StereoImage? get(String path) {
    final image = _cache.remove(path);
    if (image != null) {
      _cache[path] = image; // 移到末尾（最近使用）
    }
    return image;
  }

  /// 放入缓存，超容量时按字节数淘汰最久未用的
  void put(String path, StereoImage image) {
    final existing = _cache.remove(path);
    if (existing != null) {
      _currentBytes -= _bytesByKey.remove(path) ?? 0;
      existing.dispose();
    }

    _evictUntilFits(image.bytesApprox);

    _cache[path] = image;
    _bytesByKey[path] = image.bytesApprox;
    _currentBytes += image.bytesApprox;
  }

  /// 淘汰最旧条目直到能容纳 needed 字节
  void _evictUntilFits(int needed) {
    while (_currentBytes + needed > maxBytes && _cache.isNotEmpty) {
      final oldestKey = _cache.keys.first;
      final oldestImage = _cache.remove(oldestKey);
      final oldestBytes = _bytesByKey.remove(oldestKey) ?? 0;
      oldestImage?.dispose();
      _currentBytes -= oldestBytes;
    }
  }

  /// 检查缓存中是否包含指定路径
  bool contains(String path) => _cache.containsKey(path);

  /// 清空缓存
  void clear() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
    _bytesByKey.clear();
    _currentBytes = 0;

    // 取消所有等待中的 Completer
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Cache cleared'));
      }
    }
    _pending.clear();
  }

  /// 当前缓存数量
  int get length => _cache.length;

  /// 获取图片或等待预加载完成（Completer 通知，零延迟）
  Future<StereoImage> getOrWait(String path) async {
    // 1. 先检查缓存
    final cached = get(path);
    if (cached != null) return cached;

    // 2. 如果有正在加载的，等待它完成
    if (_pending.containsKey(path)) {
      return await _pending[path]!.future;
    }

    // 3. 没有预加载，自行加载
    _pending[path] = Completer<StereoImage>();
    try {
      final image = await cropAndLoadImage(path);
      put(path, image);
      _pending[path]?.complete(image);
      return image;
    } catch (e) {
      _pending[path]?.completeError(e);
      rethrow;
    } finally {
      _pending.remove(path);
    }
  }

  /// 预加载指定路径列表（跳过已缓存的，使用信号量控制并发）
  Future<void> preload(List<String> paths) async {
    final toLoad = paths
        .where((p) => !contains(p) && !_pending.containsKey(p))
        .toList();

    for (final path in toLoad) {
      // 创建 Completer 供等待方使用
      _pending[path] = Completer<StereoImage>();

      // 获取信号量许可后开始加载
      _semaphore.acquire().then((_) async {
        try {
          final image = await cropAndLoadImage(path);
          put(path, image);
          _pending[path]?.complete(image);
        } catch (e) {
          _pending[path]?.completeError(e);
        } finally {
          _pending.remove(path);
          _semaphore.release();
        }
      });
    }
  }
}
