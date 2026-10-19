import '../l10n/app_language.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/media_item.dart';

/// 由 ViewerPage 持有，用于把手柄播放/暂停、音量操作交给当前视频 widget。
class SbsVideoController {
  VideoPlayerController? _player;
  final ValueNotifier<bool> _progressVisible = ValueNotifier(false);
  Timer? _progressTimer;

  bool get isReady => _player?.value.isInitialized ?? false;
  bool get isPlaying => _player?.value.isPlaying ?? false;
  ValueNotifier<bool> get progressVisible => _progressVisible;

  Future<void> togglePlayback() async {
    final player = _player;
    if (player == null || !player.value.isInitialized) return;
    if (player.value.isPlaying) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> setVolume(double value) async {
    final player = _player;
    if (player == null || !player.value.isInitialized) return;
    await player.setVolume(value.clamp(0.0, 1.0).toDouble());
  }

  Future<void> pause() async {
    final player = _player;
    if (player != null && player.value.isInitialized) await player.pause();
  }

  Future<void> seekBySeconds(int seconds) async {
    final player = _player;
    if (player == null || !player.value.isInitialized) return;
    final duration = player.value.duration;
    if (duration <= Duration.zero) return;
    final target = Duration(
      milliseconds: (player.value.position.inMilliseconds + seconds * 1000)
          .clamp(0, duration.inMilliseconds)
          .toInt(),
    );
    await player.seekTo(target);
    _showProgress();
  }

  void _showProgress() {
    _progressVisible.value = true;
    _progressTimer?.cancel();
    _progressTimer = Timer(const Duration(seconds: 3), () {
      _progressVisible.value = false;
    });
  }

  void _attach(VideoPlayerController player) => _player = player;
  void _detach(VideoPlayerController player) {
    if (identical(_player, player)) _player = null;
    _progressTimer?.cancel();
    _progressVisible.value = false;
  }
}

class StereoVideoView extends StatefulWidget {
  final MediaItem item;
  final SbsVideoController playbackController;
  final double volume;
  final double zoom;
  final double ipdOffset;
  final double panX;
  final double panY;
  final double scale;
  final ValueChanged<Object> onError;

  const StereoVideoView({
    super.key,
    required this.item,
    required this.playbackController,
    required this.volume,
    required this.zoom,
    required this.ipdOffset,
    required this.panX,
    required this.panY,
    this.scale = 0.8,
    required this.onError,
  });

  @override
  State<StereoVideoView> createState() => _StereoVideoViewState();
}

class _StereoVideoViewState extends State<StereoVideoView> {
  VideoPlayerController? _player;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final player = VideoPlayerController.file(File(widget.item.localPath));
      _player = player;
      await player.initialize();
      await player.setLooping(true);
      await player.setVolume(widget.volume);
      widget.playbackController._attach(player);
      await player.play();
      if (mounted) setState(() {});
    } catch (error) {
      _error = error;
      widget.onError(error);
      if (mounted) setState(() {});
    }
  }

  @override
  void didUpdateWidget(StereoVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.volume != widget.volume) {
      widget.playbackController.setVolume(widget.volume);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = _player;
    if (_error != null) {
      return Center(
        child: Text(
          '${tr(context, 'Video failed to load')}\n${widget.item.name}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    if (player == null || !player.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        _SbsVideoLayout(
          player: player,
          zoom: widget.zoom,
          ipdOffset: widget.ipdOffset,
          panX: widget.panX,
          panY: widget.panY,
          scale: widget.scale,
        ),
        ValueListenableBuilder<bool>(
          valueListenable: widget.playbackController.progressVisible,
          builder: (context, visible, _) => visible
              ? _StereoVideoProgressOverlay(player: player)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    final player = _player;
    if (player != null) {
      widget.playbackController._detach(player);
      player.dispose();
    }
    super.dispose();
  }
}

/// 先将完整 SBS texture 按单眼比例缩放，再严格裁出左右眼。
/// ipdOffset 仅移动左右眼各自的观看窗口，不能改变已编码视频的真实视差。
class _SbsVideoLayout extends StatelessWidget {
  final VideoPlayerController player;
  final double zoom;
  final double ipdOffset;
  final double panX;
  final double panY;
  final double scale;

  const _SbsVideoLayout({
    required this.player,
    required this.zoom,
    required this.ipdOffset,
    required this.panX,
    required this.panY,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final eyeWidth = constraints.maxWidth / 2;
        final eyeHeight = constraints.maxHeight;
        final sourceAspect = player.value.aspectRatio;
        if (sourceAspect <= 0 || eyeWidth <= 0 || eyeHeight <= 0) {
          return const SizedBox.shrink();
        }
        final eyeAspect = sourceAspect / 2;
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
        // 避免微调把其它眼的内容拖入可视区；单位是屏幕像素。
        final safeOffset = ipdOffset
            .clamp(-renderedHalfWidth * 0.1, renderedHalfWidth * 0.1)
            .toDouble();

        Widget eye({required bool left}) {
          return SizedBox(
            width: eyeWidth,
            height: eyeHeight,
            // 外层先按眼睛范围裁切，再作缩放/平移。不能把变换放在 Row 外部，
            // 否则竖版 SBS 的另一眼纹理会重新漏进当前眼。
            child: ClipRect(
              child: Transform.scale(
                scale: scale.clamp(0.1, 1.0),
                child: Transform.translate(
                  offset: Offset(
                    (left ? safeOffset : -safeOffset) + clampedPanX,
                    clampedPanY,
                  ),
                  child: Transform.scale(
                    scale: effectiveZoom,
                    child: Stack(
                      children: [
                        // 这个裁切窗口本身只有单眼宽度。此前裁切的是整个屏幕半幅，竖屏
                        // 视频的右半幅会溢入左眼，导致中间出现多余的第三个人像。
                        Positioned(
                          left: margin,
                          top: y,
                          width: renderedHalfWidth,
                          height: renderedHeight,
                          child: ClipRect(
                            child: OverflowBox(
                              minWidth: renderedHalfWidth * 2,
                              maxWidth: renderedHalfWidth * 2,
                              minHeight: renderedHeight,
                              maxHeight: renderedHeight,
                              alignment: left
                                  ? Alignment.topLeft
                                  : Alignment.topRight,
                              child: VideoPlayer(player),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Row(children: [eye(left: true), eye(left: false)]);
      },
    );
  }
}

/// 左右眼各自显示同一份进度浮窗；由 seek 动作触发，三秒无操作自动隐藏。
class _StereoVideoProgressOverlay extends StatelessWidget {
  final VideoPlayerController player;

  const _StereoVideoProgressOverlay({required this.player});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: player,
      builder: (context, value, _) {
        final duration = value.duration;
        final position = value.position > duration ? duration : value.position;
        final fraction = duration > Duration.zero
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;
        Widget panel() => Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 260,
            margin: const EdgeInsets.only(bottom: 42),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: fraction.clamp(0.0, 1.0)),
                const SizedBox(height: 5),
                Text(
                  '${_formatDuration(position)} / ${_formatDuration(duration)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        );
        return Row(
          children: [
            Expanded(child: panel()),
            Expanded(child: panel()),
          ],
        );
      },
    );
  }
}

String _formatDuration(Duration value) {
  final minutes = value.inMinutes;
  final seconds = value.inSeconds.remainder(60);
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
