import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/media_item.dart';
import '../services/gamepad_events.dart';
import '../services/vr_menu_preferences.dart';
import '../widgets/boundary_toast.dart';
import '../widgets/debug_overlay.dart';
import '../widgets/image_source.dart';
import '../widgets/stereo_gif_view.dart';
import '../widgets/stereo_image_cache.dart';
import '../widgets/stereo_video_view.dart';
import '../widgets/stereo_view.dart';

class ViewerPage extends StatefulWidget {
  final List<MediaItem> initialMediaItems;
  final int initialIndex;
  final Future<List<MediaItem>?> Function(int direction)? onChangeGallery;

  const ViewerPage({
    super.key,
    required this.initialMediaItems,
    this.initialIndex = 0,
    this.onChangeGallery,
  });

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> with WidgetsBindingObserver {
  late final List<MediaItem> _mediaItems;
  int _currentIndex = -1;
  double _zoom = VrMenuPreferences.defaultZoom;
  double _ipdOffset = 0;
  double _scale = VrMenuPreferences.defaultScale;
  double _panX = 0;
  double _panY = 0;
  double _videoVolume = 0.7;
  SbsVideoController? _videoController;
  SbsGifController? _gifController;
  bool _showUI = VrMenuPreferences.defaultShowUi;
  final _viewerPreferences = const VrMenuPreferences();

  String? _boundaryToast;
  int? _boundaryDirection;
  bool _boundaryConfirm = false;
  Timer? _boundaryToastTimer;

  late final StereoImageCache _cache;
  final FocusNode _focusNode = FocusNode();

  StreamSubscription? _gamepadSubscription;
  Timer? _gamepadTimer;
  DateTime _lastStickSelect = DateTime.fromMillisecondsSinceEpoch(0);
  double _leftStickX = 0;
  double _leftStickY = 0;
  double _rightStickX = 0;
  double _rightStickY = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.addObserver(this);
    _cache = StereoImageCache(maxBytes: 200 * 1024 * 1024, maxConcurrent: 2);
    _mediaItems = List.of(widget.initialMediaItems);
    _currentIndex = _mediaItems.isEmpty
        ? -1
        : widget.initialIndex.clamp(0, _mediaItems.length - 1).toInt();
    _createControllerForCurrent();
    unawaited(_loadViewerPreferences());
    _loadSavedVolume();
    _initGamepadListener();
    _requestInputFocus();
    _prefetchImages();
  }

  Future<void> _loadViewerPreferences() async {
    final saved = await _viewerPreferences.loadViewer();
    if (!mounted) return;
    setState(() {
      _scale = saved['scale']! as double;
      _zoom = saved['zoom']! as double;
      _ipdOffset = saved['ipd']! as double;
      _showUI = saved['showUi']! as bool;
    });
  }

  void _createControllerForCurrent() {
    if (_currentIndex < 0 || _currentIndex >= _mediaItems.length) return;
    final item = _mediaItems[_currentIndex];
    _videoController = item.isVideo ? SbsVideoController() : null;
    _gifController = item.kind == MediaKind.gif ? SbsGifController() : null;
  }

  void _requestInputFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNode.canRequestFocus) _focusNode.requestFocus();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _requestInputFocus();
  }

  Future<void> _loadSavedVolume() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final savedVolume = prefs.getDouble('video_volume') ?? 0.7;
    if (_videoVolume != savedVolume) {
      setState(() => _videoVolume = savedVolume);
    }
  }

  void _initGamepadListener() {
    try {
      _gamepadSubscription = GamepadEvents.stream.listen(
        (event) {
          if (event is! Map) return;
          final dpad = event['dpad'];
          if (dpad is String) {
            _handleDpad(dpad);
            return;
          }
          _leftStickX = (event['leftX'] as num?)?.toDouble() ?? 0;
          _leftStickY = (event['leftY'] as num?)?.toDouble() ?? 0;
          _rightStickX = (event['rightX'] as num?)?.toDouble() ?? 0;
          _rightStickY = (event['rightY'] as num?)?.toDouble() ?? 0;
          _handleGamepadInput();
        },
        onError: (error) {
          debugPrint('Gamepad EventChannel error: $error');
        },
      );

      _gamepadTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        if (!mounted) return;
        const sensitivity = 5.0;
        final dx = -_rightStickX * sensitivity;
        final dy = -_rightStickY * sensitivity;
        if (dx == 0 && dy == 0) return;
        setState(() {
          _panX += dx;
          _panY += dy;
        });
      });
    } catch (error) {
      debugPrint('Gamepad listener init failed: $error');
    }
  }

  void _showBoundaryToast(String text) {
    _boundaryToastTimer?.cancel();
    setState(() => _boundaryToast = text);
    _boundaryToastTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _boundaryToast = null);
    });
  }

  void _handleBoundary(int direction) {
    if (_boundaryDirection == direction && !_boundaryConfirm) {
      _boundaryConfirm = true;
      _showBoundaryToast(
        'Enter ${direction < 0 ? 'previous' : 'next'} collection? Y/B',
      );
      return;
    }
    _boundaryDirection = direction;
    _boundaryConfirm = false;
    _showBoundaryToast(
      direction < 0 ? 'This is the first image' : 'This is the last image',
    );
  }

  Future<void> _changeGallery() async {
    final direction = _boundaryDirection;
    final callback = widget.onChangeGallery;
    if (direction == null || callback == null) return;
    final items = await callback(direction);
    if (items != null && items.isNotEmpty && mounted) {
      setState(() {
        _mediaItems
          ..clear()
          ..addAll(items);
        _currentIndex = direction < 0 ? _mediaItems.length - 1 : 0;
        _panX = 0;
        _panY = 0;
        _boundaryToast = null;
        _boundaryDirection = null;
        _boundaryConfirm = false;
      });
      _createControllerForCurrent();
      _prefetchImages();
    }
  }

  void _handleGamepadInput() {
    final now = DateTime.now();
    if (now.difference(_lastStickSelect).inMilliseconds < 200) return;

    final action = swipeActionFor(
      currentIndex: _currentIndex,
      total: _mediaItems.length,
      stickX: _leftStickX,
    );
    if (action != SwipeAction.none) {
      _lastStickSelect = now;
      switch (action) {
        case SwipeAction.navigatePrevious:
          _requestSelectMedia(_currentIndex - 1);
        case SwipeAction.navigateNext:
          _requestSelectMedia(_currentIndex + 1);
        case SwipeAction.showFirstBoundary:
          _handleBoundary(-1);
        case SwipeAction.showLastBoundary:
          _handleBoundary(1);
        case SwipeAction.none:
          break;
      }
      return;
    }

    if (_leftStickY < -0.3) {
      _lastStickSelect = now;
      setState(() => _zoom = (_zoom + 0.2).clamp(0.5, 3.0));
    } else if (_leftStickY > 0.3) {
      _lastStickSelect = now;
      setState(() {
        _zoom = (_zoom - 0.2).clamp(0.5, 3.0);
        if (_zoom <= 1) {
          _panX = 0;
          _panY = 0;
        }
      });
    }
  }

  void _handleDpad(String direction) {
    if (_currentIndex < 0 || _currentIndex >= _mediaItems.length) return;
    final current = _mediaItems[_currentIndex];
    if (current.isVideo) {
      switch (direction) {
        case 'left':
          unawaited(
            _videoController?.seekBySeconds(-5) ?? Future<void>.value(),
          );
        case 'right':
          unawaited(_videoController?.seekBySeconds(5) ?? Future<void>.value());
        case 'up':
          _changeVideoVolume(0.1);
        case 'down':
          _changeVideoVolume(-0.1);
      }
      return;
    }
    if (direction == 'left') {
      _requestSelectMedia(_currentIndex - 1);
    } else if (direction == 'right') {
      _requestSelectMedia(_currentIndex + 1);
    }
  }

  void _prefetchImages() {
    if (_mediaItems.isEmpty || _currentIndex < 0) return;
    final sources = <ImageSource>[];
    for (var offset = -2; offset <= 2; offset++) {
      final index = _currentIndex + offset;
      if (index < 0 || index >= _mediaItems.length || offset == 0) continue;
      final item = _mediaItems[index];
      if (item.isImageLike) sources.add(_imageSourceFor(item));
    }
    for (final source in sources) {
      if (_cache.contains(source.cacheKey)) continue;
      unawaited(
        source.load(_cache).then<void>((_) {}).catchError((Object error) {
          debugPrint('Prefetch failed: ${source.cacheKey} - $error');
        }),
      );
    }
  }

  ImageSource _imageSourceFor(MediaItem item) {
    if (!item.isImageLike) {
      throw StateError('Video cannot use the image cache: ${item.name}');
    }
    return LocalImageSource(item.localPath);
  }

  void _requestSelectMedia(int index) {
    if (index < 0) {
      _handleBoundary(-1);
      return;
    }
    if (index >= _mediaItems.length) {
      _handleBoundary(1);
      return;
    }
    unawaited(_selectMedia(index));
  }

  Future<void> _selectMedia(int index) async {
    final item = _mediaItems[index];
    if (!mounted) return;
    unawaited(_videoController?.pause() ?? Future<void>.value());
    _gifController?.pause();
    setState(() {
      _currentIndex = index;
      _videoController = item.isVideo ? SbsVideoController() : null;
      _gifController = item.kind == MediaKind.gif ? SbsGifController() : null;
      _panX = 0;
      _panY = 0;
    });
    _prefetchImages();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.gameButtonRight1) {
      setState(() => _showUI = !_showUI);
      unawaited(_viewerPreferences.saveViewer(showUi: _showUI));
      return KeyEventResult.handled;
    }
    return _handleViewerKey(event);
  }

  KeyEventResult _handleViewerKey(KeyEvent event) {
    if (_currentIndex < 0 || _currentIndex >= _mediaItems.length) {
      return KeyEventResult.ignored;
    }
    final current = _mediaItems[_currentIndex];
    if (_boundaryConfirm &&
        event.logicalKey == LogicalKeyboardKey.gameButtonY) {
      unawaited(_changeGallery());
      return KeyEventResult.handled;
    }
    if (_boundaryConfirm &&
        event.logicalKey == LogicalKeyboardKey.gameButtonB) {
      setState(() {
        _boundaryToast = null;
        _boundaryDirection = null;
        _boundaryConfirm = false;
      });
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (current.isVideo) {
        unawaited(_videoController?.seekBySeconds(-5) ?? Future<void>.value());
      } else {
        _requestSelectMedia(_currentIndex - 1);
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (current.isVideo) {
        unawaited(_videoController?.seekBySeconds(5) ?? Future<void>.value());
      } else {
        _requestSelectMedia(_currentIndex + 1);
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp && current.isVideo) {
      _changeVideoVolume(0.1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown && current.isVideo) {
      _changeVideoVolume(-0.1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.gameButtonY && current.isVideo) {
      unawaited(_videoController?.togglePlayback() ?? Future<void>.value());
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.gameButtonY &&
        current.kind == MediaKind.gif) {
      _gifController?.togglePlayback();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      setState(() {
        _ipdOffset = (_ipdOffset - 5).clamp(-50.0, 50.0);
      });
      unawaited(_viewerPreferences.saveViewer(ipd: _ipdOffset));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.gameButtonX) {
      setState(() {
        _ipdOffset = (_ipdOffset + 5).clamp(-50.0, 50.0);
      });
      unawaited(_viewerPreferences.saveViewer(ipd: _ipdOffset));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.gameButtonY) {
      setState(() {
        _zoom = VrMenuPreferences.defaultZoom;
        _ipdOffset = 0;
        _panX = 0;
        _panY = 0;
      });
      unawaited(_viewerPreferences.saveViewer(zoom: _zoom, ipd: _ipdOffset));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.gameButtonB ||
        event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.escape) {
      unawaited(_videoController?.pause() ?? Future<void>.value());
      _gifController?.pause();
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _changeVideoVolume(double delta) {
    final next = (_videoVolume + delta).clamp(0.0, 1.0).toDouble();
    setState(() => _videoVolume = next);
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setDouble('video_volume', next),
    );
    unawaited(_videoController?.setVolume(next) ?? Future<void>.value());
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _mediaItems.isEmpty ? _buildEmptyState() : _buildViewer(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo_library_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('No SBS media found'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildViewer() {
    final item = _mediaItems[_currentIndex];
    final name = item.name;
    final mediaView = item.isVideo
        ? StereoVideoView(
            key: ValueKey(item.cacheKey),
            item: item,
            playbackController: _videoController ??= SbsVideoController(),
            volume: _videoVolume,
            zoom: _zoom,
            scale: _scale,
            ipdOffset: _ipdOffset,
            panX: _panX,
            panY: _panY,
            onError: (error) => debugPrint('Video failed $name: $error'),
          )
        : item.kind == MediaKind.gif
        ? StereoGifView(
            key: ValueKey(item.cacheKey),
            item: item,
            playbackController: _gifController ??= SbsGifController(),
            zoom: _zoom,
            scale: _scale,
            ipdOffset: _ipdOffset,
            panX: _panX,
            panY: _panY,
            onError: (error) => debugPrint('GIF failed $name: $error'),
          )
        : StereoView(
            imageSource: _imageSourceFor(item),
            cache: _cache,
            zoom: _zoom,
            scale: _scale,
            ipdOffset: _ipdOffset,
            panX: _panX,
            panY: _panY,
          );

    return Stack(
      children: [
        mediaView,
        if (_showUI)
          Row(
            children: [
              Expanded(child: _buildInfoPanel(item)),
              Expanded(child: _buildInfoPanel(item)),
            ],
          ),
        if (_boundaryToast != null)
          Row(
            children: [
              Expanded(
                child: Center(child: BoundaryToast(text: _boundaryToast!)),
              ),
              Expanded(
                child: Center(child: BoundaryToast(text: _boundaryToast!)),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildInfoPanel(MediaItem item) {
    return Align(
      alignment: Alignment.center,
      child: ViewerInfoPanel(
        zoom: _zoom,
        ipdOffset: _ipdOffset,
        index: _currentIndex + 1,
        total: _mediaItems.length,
        mode: item.isVideo
            ? ViewerInfoMode.video
            : item.kind == MediaKind.gif
            ? ViewerInfoMode.gif
            : ViewerInfoMode.image,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gamepadSubscription?.cancel();
    _gamepadTimer?.cancel();
    _boundaryToastTimer?.cancel();
    _cache.clear();
    _focusNode.dispose();
    super.dispose();
  }
}
