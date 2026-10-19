import '../l10n/app_language.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/media_item.dart';

/// 由 ViewerPage 持有，让手柄可以暂停或继续当前 GIF 的画面更新。
class SbsGifController {
  void Function(bool playing)? _setPlaying;
  bool _isPlaying = true;

  bool get isPlaying => _isPlaying;

  void togglePlayback() => _setPlaying?.call(!_isPlaying);

  void pause() => _setPlaying?.call(false);

  void _attach(void Function(bool playing) callback) {
    _setPlaying = callback;
  }

  void _detach() => _setPlaying = null;

  void _updatePlaying(bool playing) => _isPlaying = playing;
}

/// 以同一条 ImageStream 绘制左右眼，确保 SBS GIF 的两个眼睛使用同一动画帧。
class StereoGifView extends StatefulWidget {
  final MediaItem item;
  final SbsGifController playbackController;
  final double zoom;
  final double ipdOffset;
  final double panX;
  final double panY;
  final double scale;
  final ValueChanged<Object>? onError;

  StereoGifView({
    super.key,
    required this.item,
    required this.playbackController,
    required this.zoom,
    required this.ipdOffset,
    required this.panX,
    required this.panY,
    this.onError,
    this.scale = 0.8,
  }) : assert(item.kind == MediaKind.gif);

  @override
  State<StereoGifView> createState() => _StereoGifViewState();
}

class _StereoGifViewState extends State<StereoGifView> {
  late final ImageProvider _provider;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ui.Image? _frame;
  Object? _error;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _provider = FileImage(File(widget.item.localPath));
    _listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (mounted) setState(() => _frame = info.image);
      },
      onError: (Object error, StackTrace? stackTrace) {
        _error = error;
        widget.onError?.call(error);
        if (mounted) setState(() {});
      },
    );
    _stream = _provider.resolve(createLocalImageConfiguration(context));
    _stream!.addListener(_listener!);
    widget.playbackController._attach(_setPlaying);
  }

  void _setPlaying(bool playing) {
    if (_isPlaying == playing) return;
    final stream = _stream;
    final listener = _listener;
    if (stream == null || listener == null) return;
    if (playing) {
      stream.addListener(listener);
    } else {
      stream.removeListener(listener);
    }
    widget.playbackController._updatePlaying(playing);
    if (mounted) setState(() => _isPlaying = playing);
  }

  @override
  void dispose() {
    final listener = _listener;
    if (_stream != null && listener != null) _stream!.removeListener(listener);
    widget.playbackController._detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Text(
          '${tr(context, 'GIF failed to load')}\n${widget.item.name}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    final frame = _frame;
    if (frame == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return CustomPaint(
      painter: _SbsGifPainter(
        frame: frame,
        zoom: widget.zoom,
        ipdOffset: widget.ipdOffset,
        panX: widget.panX,
        panY: widget.panY,
        scale: widget.scale,
      ),
      size: Size.infinite,
    );
  }
}

/// SBS 文件先按中线拆成两个源矩形，再以 contain 方式放入各自的半屏。
/// IPD 仅在各自半屏内平移观看窗口，动画帧和真实左右视差不会被修改。
class _SbsGifPainter extends CustomPainter {
  final ui.Image frame;
  final double zoom;
  final double ipdOffset;
  final double panX;
  final double panY;
  final double scale;

  _SbsGifPainter({
    required this.frame,
    required this.zoom,
    required this.ipdOffset,
    required this.panX,
    required this.panY,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || frame.width < 2 || frame.height <= 0) return;
    final eyeWidth = size.width / 2;
    final eyeHeight = size.height;
    final eyeAspect = frame.width / frame.height / 2;
    final renderedHalfWidth = (eyeHeight * eyeAspect)
        .clamp(0.0, eyeWidth)
        .toDouble();
    final renderedHeight = renderedHalfWidth / eyeAspect;
    final y = (eyeHeight - renderedHeight) / 2;
    final margin = (eyeWidth - renderedHalfWidth) / 2;
    final effectiveZoom = zoom.clamp(0.5, 3.0).toDouble();
    final maxPanX = effectiveZoom > 1.0
        ? effectiveZoom * eyeWidth / 2
        : eyeWidth * 0.2;
    final maxPanY = effectiveZoom > 1.0
        ? effectiveZoom * eyeHeight / 2
        : eyeHeight * 0.2;
    final clampedPanX = panX.clamp(-maxPanX, maxPanX).toDouble();
    final clampedPanY = panY.clamp(-maxPanY, maxPanY).toDouble();
    final safeOffset = ipdOffset
        .clamp(-renderedHalfWidth * 0.1, renderedHalfWidth * 0.1)
        .toDouble();
    final sourceHalfWidth = frame.width / 2;
    final paint = Paint()..filterQuality = FilterQuality.medium;

    void drawEye({required bool left}) {
      final eyeLeft = left ? 0.0 : eyeWidth;
      final source = Rect.fromLTWH(
        left ? 0 : sourceHalfWidth,
        0,
        sourceHalfWidth,
        frame.height.toDouble(),
      );
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(eyeLeft, 0, eyeWidth, eyeHeight));
      // 变换以单眼视窗中心为原点；两眼使用同一缩放/平移，IPD 则反向偏移。
      canvas.translate(
        eyeLeft +
            eyeWidth / 2 +
            (left ? safeOffset : -safeOffset) +
            clampedPanX,
        eyeHeight / 2 + clampedPanY,
      );
      canvas.scale(scale.clamp(0.1, 1.0));
      canvas.scale(effectiveZoom);
      canvas.translate(-eyeWidth / 2, -eyeHeight / 2);
      final destination = Rect.fromLTWH(
        margin,
        y,
        renderedHalfWidth,
        renderedHeight,
      );
      canvas.drawImageRect(frame, source, destination, paint);
      canvas.restore();
    }

    drawEye(left: true);
    drawEye(left: false);
  }

  @override
  bool shouldRepaint(covariant _SbsGifPainter oldDelegate) =>
      !identical(oldDelegate.frame, frame) ||
      oldDelegate.zoom != zoom ||
      oldDelegate.ipdOffset != ipdOffset ||
      oldDelegate.panX != panX ||
      oldDelegate.panY != panY ||
      oldDelegate.scale != scale;
}
