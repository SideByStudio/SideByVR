import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/media_item.dart';
import '../services/local_library_preferences.dart';
import '../services/gamepad_events.dart';
import '../services/saf_storage_service.dart';
import '../services/vr_menu_preferences.dart';
import '../widgets/stereo_menu_row.dart';
import '../widgets/zip_extractor.dart';
import 'viewer_page.dart';

enum _BrowserEntryType { currentMedia, directory, zip }

class _BrowserEntry {
  final _BrowserEntryType type;
  final String name;
  final SafDocument? document;
  final int? count;

  const _BrowserEntry({
    required this.type,
    required this.name,
    this.document,
    this.count,
  });
}

class SafBrowserPage extends StatefulWidget {
  final LocalLibraryLocation location;
  final bool initialVrMode;

  const SafBrowserPage({
    super.key,
    required this.location,
    this.initialVrMode = false,
  });

  @override
  State<SafBrowserPage> createState() => _SafBrowserPageState();
}

class _SafBrowserPageState extends State<SafBrowserPage> {
  final _storage = const SafStorageService();
  final _preferences = const LocalLibraryPreferences();
  final _vrMenuPreferences = const VrMenuPreferences();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final _itemKeys = <GlobalKey>[];
  final _gamepadDecoder = MenuGamepadDecoder();
  StreamSubscription? _gamepadSubscription;
  bool _acceptGamepadEvents = true;

  late String _currentUri;
  late String _currentName;
  late List<String> _breadcrumbUris;
  late List<String> _breadcrumbNames;
  List<_BrowserEntry> _entries = const [];
  List<SafDocument> _currentMedia = const [];
  int _selectedIndex = 0;
  bool _loading = true;
  bool _includeUnmarkedImages = false;
  String? _error;
  late bool _isVrMode;
  double _vrMenuScale = VrMenuPreferences.defaultScale;

  @override
  void initState() {
    super.initState();
    _isVrMode = widget.initialVrMode;
    _gamepadSubscription = GamepadEvents.stream.listen(_handleGamepadEvent);
    unawaited(_applyDisplayMode());
    unawaited(_loadVrMenuScale());
    _currentUri = widget.location.currentUri;
    _currentName = widget.location.currentName;
    _breadcrumbUris = List.of(widget.location.breadcrumbUris);
    _breadcrumbNames = List.of(widget.location.breadcrumbNames);
    _loadCurrent(fallbackToRoot: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  Future<void> _loadVrMenuScale() async {
    final value = await _vrMenuPreferences.loadScale();
    if (mounted) setState(() => _vrMenuScale = value);
  }

  Future<void> _applyDisplayMode() async {
    await SystemChrome.setPreferredOrientations(
      _isVrMode
          ? const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [DeviceOrientation.portraitUp],
    );
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _restoreBrowserInput() async {
    await _applyDisplayMode();
    if (mounted) _focusNode.requestFocus();
  }

  Future<void> _toggleImageMode() async {
    if (_loading || !_acceptGamepadEvents) return;
    setState(() => _includeUnmarkedImages = !_includeUnmarkedImages);
    await _loadCurrent();
    if (mounted) _focusNode.requestFocus();
  }

  Widget _buildImageModeButton() => TextButton(
    onPressed: _loading ? null : _toggleImageMode,
    child: Text(
      _includeUnmarkedImages
          ? 'Ordinary images as SBS: ON — R to switch'
          : 'Include ordinary images as SBS — R',
    ),
  );

  void _toggleDisplayMode() {
    setState(() => _isVrMode = !_isVrMode);
    unawaited(_restoreBrowserInput().whenComplete(_revealSelection));
  }

  void _handleGamepadEvent(dynamic rawEvent) {
    if (!mounted || !_acceptGamepadEvents || rawEvent is! Map) return;
    final intent = _gamepadDecoder.decode(rawEvent);
    switch (intent) {
      case MenuGamepadIntent.up:
        _moveSelection(-1);
      case MenuGamepadIntent.down:
        _moveSelection(1);
      case MenuGamepadIntent.toggleDisplayMode:
        _toggleDisplayMode();
      case MenuGamepadIntent.left:
      case MenuGamepadIntent.right:
      case null:
        break;
    }
  }

  void _moveSelection(int delta) {
    if (_entries.isEmpty) return;
    final next = (_selectedIndex + delta).clamp(0, _entries.length - 1);
    if (next != _selectedIndex) {
      setState(() => _selectedIndex = next);
      _revealSelection();
    }
  }

  void _revealSelection() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted || _selectedIndex < 0 || _selectedIndex >= _itemKeys.length) {
      return;
    }
    final target = _itemKeys[_selectedIndex].currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 180),
        alignment: 0.25,
      );
    }
  });

  List<GlobalKey> _resetKeys(int count) {
    if (_itemKeys.length != count) {
      _itemKeys
        ..clear()
        ..addAll(List.generate(count, (_) => GlobalKey()));
    }
    return _itemKeys;
  }

  Future<void> _loadCurrent({bool fallbackToRoot = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _loadDirectory(_currentUri, _currentName);
    } catch (error) {
      var failure = error;
      if (fallbackToRoot && _currentUri != widget.location.rootUri) {
        _currentUri = widget.location.rootUri;
        _currentName = widget.location.rootName;
        _breadcrumbUris = [widget.location.rootUri];
        _breadcrumbNames = [widget.location.rootName];
        try {
          await _loadDirectory(_currentUri, _currentName);
          return;
        } catch (rootError) {
          failure = rootError;
        }
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to open the selected folder.\n$failure';
      });
    }
  }

  Future<void> _loadDirectory(String uri, String name) async {
    final children = await _storage.listChildren(uri);
    final directories = children.where((item) => item.isDirectory).toList()
      ..sort(
        (left, right) =>
            left.name.toLowerCase().compareTo(right.name.toLowerCase()),
      );
    final zips =
        children
            .where(
              (item) =>
                  !item.isDirectory && item.name.toLowerCase().endsWith('.zip'),
            )
            .toList()
          ..sort(
            (left, right) =>
                left.name.toLowerCase().compareTo(right.name.toLowerCase()),
          );
    final media =
        children
            .where(
              (item) =>
                  !item.isDirectory &&
                  isViewableMediaName(
                    item.name,
                    includeUnmarkedImages: _includeUnmarkedImages,
                  ),
            )
            .toList()
          ..sort(
            (left, right) =>
                left.name.toLowerCase().compareTo(right.name.toLowerCase()),
          );

    final entries = <_BrowserEntry>[
      if (media.isNotEmpty)
        _BrowserEntry(
          type: _BrowserEntryType.currentMedia,
          name: _includeUnmarkedImages
              ? 'View folder media as SBS'
              : 'SBS media in this folder',
          count: media.length,
        ),
      ...directories.map(
        (item) => _BrowserEntry(
          type: _BrowserEntryType.directory,
          name: item.name,
          document: item,
        ),
      ),
      ...zips.map(
        (item) => _BrowserEntry(
          type: _BrowserEntryType.zip,
          name: item.name,
          document: item,
        ),
      ),
    ];

    if (!mounted) return;
    setState(() {
      _currentUri = uri;
      _currentName = name;
      _currentMedia = media;
      _entries = entries;
      _selectedIndex = entries.isEmpty ? -1 : 0;
      _loading = false;
      _error = null;
    });
    await _preferences.saveCurrent(
      currentUri: uri,
      currentName: name,
      breadcrumbUris: List.unmodifiable(_breadcrumbUris),
      breadcrumbNames: List.unmodifiable(_breadcrumbNames),
    );
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!_acceptGamepadEvents || _loading) return KeyEventResult.handled;
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.keyR ||
            event.logicalKey == LogicalKeyboardKey.gameButtonRight1)) {
      unawaited(_toggleImageMode());
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveSelection(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveSelection(1);
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.gameButtonLeft1) {
      _toggleDisplayMode();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA ||
        event.logicalKey == LogicalKeyboardKey.gameButtonY) {
      _openSelected();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.gameButtonX ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      _goToParent();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.gameButtonB ||
        event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _openSelected() async {
    if (_selectedIndex < 0 || _selectedIndex >= _entries.length) return;
    await _openEntry(_entries[_selectedIndex]);
  }

  Future<void> _openEntry(_BrowserEntry entry) async {
    if (_loading || !_acceptGamepadEvents) return;
    switch (entry.type) {
      case _BrowserEntryType.currentMedia:
        await _openCurrentMedia();
      case _BrowserEntryType.directory:
        final directory = entry.document!;
        setState(() {
          _loading = true;
          _error = null;
        });
        _breadcrumbUris.add(directory.uri);
        _breadcrumbNames.add(directory.name);
        try {
          await _loadDirectory(directory.uri, directory.name);
        } catch (error) {
          _breadcrumbUris.removeLast();
          _breadcrumbNames.removeLast();
          if (!mounted) return;
          setState(() {
            _loading = false;
            _error = 'Unable to open folder.\n$error';
          });
        }
      case _BrowserEntryType.zip:
        await _openZip(entry.document!);
    }
  }

  Future<void> _openCurrentMedia() async {
    await _runMaterialization(
      () async {
        final bucket = 'folder_${_stableId(_currentUri)}';
        final media = <MediaItem>[];
        for (final document in _currentMedia) {
          final path = await _storage.copyDocumentToCache(
            document: document,
            bucket: bucket,
          );
          media.add(
            MediaItem.cached(
              displayName: document.name,
              localPath: path,
              size: document.size,
            ),
          );
        }
        return media;
      },
      gallery: _entries.toList(),
      currentGallery: _entries.indexWhere(
        (e) => e.type == _BrowserEntryType.currentMedia,
      ),
    );
  }

  Future<void> _openZip(SafDocument zip) async {
    await _runMaterialization(
      () async {
        final id = _stableId(
          '${zip.uri}|${zip.size ?? -1}|${zip.lastModified ?? -1}',
        );
        final zipPath = await _storage.copyDocumentToCache(
          document: zip,
          bucket: 'zip_sources',
          fileName: '${id}_${zip.name}',
        );
        final temp = await getTemporaryDirectory();
        final destination = Directory(
          '${temp.path}${Platform.pathSeparator}sideby_zip_cache'
          '${Platform.pathSeparator}$id',
        );
        return ZipExtractor.extract(
          zipPath: zipPath,
          includeUnmarkedImages: _includeUnmarkedImages,
          destinationPath: destination.path,
        );
      },
      gallery: _entries.toList(),
      currentGallery: _entries.indexWhere(
        (e) => e.type == _BrowserEntryType.zip && e.document?.uri == zip.uri,
      ),
    );
  }

  Future<void> _runMaterialization(
    Future<List<MediaItem>> Function() action, {
    List<_BrowserEntry>? gallery,
    int? currentGallery,
  }) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    _acceptGamepadEvents = false;
    try {
      final media = await action();
      if (!mounted) return;
      setState(() => _loading = false);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ViewerPage(
            initialMediaItems: media,
            onChangeGallery: gallery == null || currentGallery == null
                ? null
                : (direction) async {
                    final next = currentGallery + direction;
                    if (next < 0 || next >= gallery.length) return null;
                    return _materializeEntry(gallery[next]);
                  },
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to open media.\n$error';
      });
    } finally {
      _acceptGamepadEvents = true;
      await _restoreBrowserInput();
    }
  }

  Future<List<MediaItem>> _materializeEntry(_BrowserEntry entry) async {
    if (entry.type == _BrowserEntryType.zip) {
      final zip = entry.document!;
      final id = _stableId(
        '${zip.uri}|${zip.size ?? -1}|${zip.lastModified ?? -1}',
      );
      final zipPath = await _storage.copyDocumentToCache(
        document: zip,
        bucket: 'zip_sources',
        fileName: '${id}_${zip.name}',
      );
      final temp = await getTemporaryDirectory();
      return ZipExtractor.extract(
        zipPath: zipPath,
        includeUnmarkedImages: _includeUnmarkedImages,
        destinationPath:
            '${temp.path}${Platform.pathSeparator}sideby_zip_cache${Platform.pathSeparator}$id',
      );
    }
    final docs = entry.type == _BrowserEntryType.directory
        ? (await _storage.listChildren(entry.document!.uri))
              .where(
                (d) =>
                    !d.isDirectory &&
                    isViewableMediaName(
                      d.name,
                      includeUnmarkedImages: _includeUnmarkedImages,
                    ),
              )
              .toList()
        : _currentMedia;
    final media = <MediaItem>[];
    for (final document in docs) {
      final path = await _storage.copyDocumentToCache(
        document: document,
        bucket: 'folder_${_stableId(entry.document?.uri ?? _currentUri)}',
      );
      media.add(
        MediaItem.cached(
          displayName: document.name,
          localPath: path,
          size: document.size,
        ),
      );
    }
    return media;
  }

  Future<void> _goToParent() async {
    try {
      if (_breadcrumbUris.length > 1 && _breadcrumbNames.length > 1) {
        final removedUri = _breadcrumbUris.removeLast();
        final removedName = _breadcrumbNames.removeLast();
        try {
          await _loadDirectory(_breadcrumbUris.last, _breadcrumbNames.last);
        } catch (_) {
          _breadcrumbUris.add(removedUri);
          _breadcrumbNames.add(removedName);
          rethrow;
        }
        return;
      }
      final parent = await _storage.getParentDirectory(
        rootUri: widget.location.rootUri,
        currentUri: _currentUri,
      );
      if (parent == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      _breadcrumbUris = [widget.location.rootUri, parent.uri];
      _breadcrumbNames = [widget.location.rootName, parent.name];
      await _loadDirectory(parent.uri, parent.name);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Unable to open parent folder.\n$error');
    }
  }

  String _stableId(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          focusNode: _focusNode,
          onKeyEvent: _handleKey,
          child: _isVrMode ? _buildVrPage() : _buildEye(),
        ),
      ),
    );
  }

  Widget _buildEye() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _goToParent,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Parent folder',
                ),
                Expanded(
                  child: Text(
                    _currentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            _buildImageModeButton(),
            const Divider(height: 1),
            Expanded(child: _buildContent()),
            Text(
              '↑↓ Select  •  A/Y Open  •  X Parent  •  RB Images as SBS  •  LB ${_isVrMode ? 'Phone' : 'VR'}  •  B Menu',
              style: TextStyle(color: Colors.white54, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVrPage() {
    final keys = _resetKeys(_entries.length);
    return SafeArea(
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        children: [
          _stereo(
            () => Row(
              children: [
                IconButton(
                  onPressed: _goToParent,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Parent folder',
                ),
                Expanded(
                  child: Text(
                    _currentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _stereo(_buildImageModeButton),
          _stereo(() => const Divider(height: 1)),
          if (_loading)
            _stereo(
              () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_error != null)
            _stereo(() => _buildErrorPanel())
          else if (_entries.isEmpty)
            _stereo(
              () => const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No subfolders, ZIP archives,\nor matching media found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            )
          else
            for (var index = 0; index < _entries.length; index++)
              Container(
                key: keys[index],
                child: _stereo(() => _buildEntryCard(_entries[index], index)),
              ),
          _stereo(
            () => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '↑↓ Select  •  A/Y Open  •  X Parent  •  RB Images as SBS  •  LB Phone  •  B Menu',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stereo(Widget Function() builder) =>
      StereoMenuRow(scale: _vrMenuScale, builder: (_, _) => builder());

  Widget _buildErrorPanel() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
      const SizedBox(height: 8),
      Text(
        _error!,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
      const SizedBox(height: 12),
      FilledButton(onPressed: _loadCurrent, child: const Text('Retry')),
    ],
  );

  Widget _buildEntryCard(_BrowserEntry entry, int index) {
    final selected = index == _selectedIndex;
    final icon = switch (entry.type) {
      _BrowserEntryType.currentMedia => Icons.photo_library_outlined,
      _BrowserEntryType.directory => Icons.folder_outlined,
      _BrowserEntryType.zip => Icons.archive_outlined,
    };
    return Card(
      color: selected ? Colors.blue.shade700 : Colors.grey.shade900,
      child: ListTile(
        dense: true,
        selected: selected,
        leading: Icon(icon, color: selected ? Colors.white : Colors.amber),
        title: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: entry.count == null ? null : Text('${entry.count} items'),
        onTap: () {
          setState(() => _selectedIndex = index);
          _openEntry(entry);
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 36,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _loadCurrent, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_entries.isEmpty) {
      return const Center(
        child: Text(
          'No subfolders, ZIP archives,\nor matching media found.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60),
        ),
      );
    }
    return ListView.builder(
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final selected = index == _selectedIndex;
        final icon = switch (entry.type) {
          _BrowserEntryType.currentMedia => Icons.photo_library_outlined,
          _BrowserEntryType.directory => Icons.folder_outlined,
          _BrowserEntryType.zip => Icons.archive_outlined,
        };
        final subtitle = entry.count == null ? null : '${entry.count} items';
        return Card(
          color: selected ? Colors.blue.shade700 : Colors.grey.shade900,
          child: ListTile(
            dense: true,
            selected: selected,
            leading: Icon(icon, color: selected ? Colors.white : Colors.amber),
            title: Text(
              entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: subtitle == null ? null : Text(subtitle),
            onTap: () {
              setState(() => _selectedIndex = index);
              _openEntry(entry);
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _gamepadSubscription?.cancel();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
