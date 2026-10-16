import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'image_source.dart';
import 'stereo_image_cache.dart';

class StereoView extends StatefulWidget {
  final ImageSource imageSource;
  final StereoImageCache cache;
  final double zoom;
  final double ipdOffset;
  final double panX;
  final double panY;
  final double separation;

  /// Scales each eye's viewport around its own center to leave peripheral UI visible.
  final double scale;
  final bool showDebugInfo;
  final Function(String)? onError;

  const StereoView({
    super.key,
    required this.imageSource,
    required this.cache,
    this.zoom = 1.0,
    this.ipdOffset = 0.0,
    this.panX = 0.0,
    this.panY = 0.0,
    this.separation = 0.5,
    this.scale = 0.8,
    this.showDebugInfo = false,
    this.onError,
  });

  @override
  State<StereoView> createState() => _StereoViewState();
}

class _StereoViewState extends State<StereoView> {
  ui.Image? _leftImage;
  ui.Image? _rightImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFromCache();
  }

  @override
  void didUpdateWidget(StereoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageSource != widget.imageSource) {
      _loadFromCache();
    }
  }

  Future<void> _loadFromCache() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stereoImage = await widget.imageSource.load(widget.cache);
      if (mounted) {
        setState(() {
          _leftImage = stereoImage.left;
          _rightImage = stereoImage.right;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        widget.onError?.call(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final halfWidth = screenWidth / 2;

        if (_isLoading || _leftImage == null || _rightImage == null) {
          // 左右分屏显示 loading
          return Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    '加载中',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '加载中',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ),
              ),
            ],
          );
        }

        // 平移范围：放大后按比例让照片角落移到中心；未放大时也给一定活动空间
        // 注：zoom ≤ 1 时图片完整可见，但仍允许平移（用于 VR 双眼对齐等微调）
        final effectiveZoom = widget.zoom.clamp(0.5, 3.0);
        final maxPanX = effectiveZoom > 1.0
            ? effectiveZoom * halfWidth / 2
            : halfWidth * 0.2;
        final maxPanY = effectiveZoom > 1.0
            ? effectiveZoom * screenHeight / 2
            : screenHeight * 0.2;
        final clampedPanX = widget.panX.clamp(-maxPanX, maxPanX);
        final clampedPanY = widget.panY.clamp(-maxPanY, maxPanY);

        return Stack(
          children: [
            // 左眼视图
            Positioned(
              left: 0,
              top: 0,
              width: halfWidth,
              height: screenHeight,
              child: ClipRect(
                child: Transform.scale(
                  scale: widget.scale.clamp(0.1, 1.0),
                  child: Transform.translate(
                    offset: Offset(widget.ipdOffset + clampedPanX, clampedPanY),
                    child: Transform.scale(
                      scale: effectiveZoom,
                      child: SizedBox(
                        width: halfWidth,
                        height: screenHeight,
                        child: RawImage(
                          image: _leftImage,
                          fit: BoxFit.contain,
                          width: halfWidth,
                          height: screenHeight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 右眼视图
            Positioned(
              left: halfWidth,
              top: 0,
              width: halfWidth,
              height: screenHeight,
              child: ClipRect(
                child: Transform.scale(
                  scale: widget.scale.clamp(0.1, 1.0),
                  child: Transform.translate(
                    offset: Offset(
                      -widget.ipdOffset + clampedPanX,
                      clampedPanY,
                    ),
                    child: Transform.scale(
                      scale: effectiveZoom,
                      child: SizedBox(
                        width: halfWidth,
                        height: screenHeight,
                        child: RawImage(
                          image: _rightImage,
                          fit: BoxFit.contain,
                          width: halfWidth,
                          height: screenHeight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 中间分隔线
            Positioned(
              left: halfWidth - 1,
              top: 0,
              width: 2,
              height: screenHeight,
              child: Container(color: Colors.white30),
            ),
          ],
        );
      },
    );
  }
}
