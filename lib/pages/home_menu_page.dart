import '../l10n/app_language.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/gamepad_events.dart';
import '../services/local_library_preferences.dart';
import '../services/saf_storage_service.dart';
import '../widgets/mirror_split_view.dart';
import '../widgets/stereo_menu_row.dart';
import 'saf_browser_page.dart';
import 'settings_page.dart';
import 'about_page.dart';
import 'help_page.dart';
import 'faq_page.dart';
import '../services/vr_menu_preferences.dart';

class HomeMenuPage extends StatefulWidget {
  const HomeMenuPage({super.key});

  @override
  State<HomeMenuPage> createState() => _HomeMenuPageState();
}

class _HomeMenuPageState extends State<HomeMenuPage> {
  final _storage = const SafStorageService();
  final _preferences = const LocalLibraryPreferences();
  final _vrMenuPreferences = const VrMenuPreferences();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final _itemKeys = List<GlobalKey>.generate(7, (_) => GlobalKey());
  final _gamepadDecoder = MenuGamepadDecoder();
  StreamSubscription? _gamepadSubscription;
  bool _acceptGamepadEvents = true;

  LocalLibraryLocation? _location;
  bool _hasPreviousFolder = false;
  bool _busy = true;
  String _busyMessage = 'Loading library…';
  int _selectedIndex = 0;
  bool _isVrMode = false;
  double _vrMenuScale = VrMenuPreferences.defaultScale;

  List<_MenuAction> get _actions => [
    _MenuAction(
      icon: Icons.folder_open,
      title: tr(context, 'Select local folder'),
      subtitle: tr(context, 'Open SBS images, videos and ZIP archives'),
      onOpen: _chooseFolder,
    ),
    _MenuAction(
      icon: Icons.history,
      title: tr(context, 'Continue last folder'),
      subtitle: _hasPreviousFolder
          ? (_location?.currentName ?? tr(context, 'Previous location'))
          : tr(context, 'Select a folder first'),
      enabled: _hasPreviousFolder,
      onOpen: _continueLastFolder,
    ),
    _MenuAction(
      icon: Icons.settings_outlined,
      title: tr(context, 'Settings'),
      subtitle: tr(context, 'VR menu size and viewer preferences'),
      onOpen: _openSettings,
    ),
    _MenuAction(
      icon: Icons.info_outline,
      title: tr(context, 'About'),
      subtitle: tr(context, 'Links, videos and app information'),
      onOpen: _openAbout,
    ),
    _MenuAction(
      icon: Icons.help_outline,
      title: tr(context, 'Help'),
      subtitle: tr(context, 'Hardware, files and controls'),
      onOpen: _openHelp,
    ),
    _MenuAction(
      icon: Icons.quiz_outlined,
      title: tr(context, 'FAQ'),
      subtitle: tr(context, 'Common questions and answers'),
      onOpen: _openFaq,
    ),
    _MenuAction(
      icon: Icons.exit_to_app,
      title: tr(context, 'Exit'),
      subtitle: tr(context, 'Close SideByVR Viewer'),
      onOpen: _exitApp,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _gamepadSubscription = GamepadEvents.stream.listen(_handleGamepadEvent);
    unawaited(_applyDisplayMode());
    _loadPreviousFolder();
    _loadVrMenuScale();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
    });
  }

  Future<void> _loadVrMenuScale() async {
    final value = await _vrMenuPreferences.loadScale();
    if (mounted) setState(() => _vrMenuScale = value);
  }

  Future<void> _applyDisplayMode() async {
    await SystemChrome.setPreferredOrientations(
      _isVrMode
          ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
          : [DeviceOrientation.portraitUp],
    );
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _restoreMenuInput() async {
    await _applyDisplayMode();
    if (mounted) _focusNode.requestFocus();
  }

  void _toggleDisplayMode() {
    setState(() => _isVrMode = !_isVrMode);
    unawaited(_restoreMenuInput().whenComplete(_revealSelection));
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
    final next = (_selectedIndex + delta).clamp(0, _actions.length - 1);
    if (next != _selectedIndex) {
      setState(() => _selectedIndex = next);
      _revealSelection();
    }
  }

  void _revealSelection() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted || _selectedIndex >= _itemKeys.length) return;
    final target = _itemKeys[_selectedIndex].currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 180),
        alignment: 0.25,
      );
    }
  });

  Future<void> _loadPreviousFolder() async {
    final location = await _preferences.load();
    var hasAccess = false;
    if (location != null) {
      try {
        hasAccess = await _storage.hasPersistedAccess(location.rootUri);
      } catch (_) {
        hasAccess = false;
      }
    }
    if (!mounted) return;
    setState(() {
      _location = location;
      _hasPreviousFolder = hasAccess;
      _busy = false;
      _busyMessage = '';
    });
  }

  Future<void> _chooseFolder() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _busyMessage = 'Opening Android folder picker…';
    });
    try {
      final selected = await _storage.pickDirectory(
        initialUri: _location?.rootUri,
      );
      if (selected == null || !mounted) return;
      await _preferences.saveRoot(
        rootUri: selected.uri,
        rootName: selected.name,
      );
      final location = LocalLibraryLocation(
        rootUri: selected.uri,
        rootName: selected.name,
        currentUri: selected.uri,
        currentName: selected.name,
        breadcrumbUris: [selected.uri],
        breadcrumbNames: [selected.name],
      );
      setState(() {
        _location = location;
        _hasPreviousFolder = true;
      });
      await _openBrowser(location);
    } on PlatformException {
      if (mounted) _showError(tr(context, 'Unable to select folder'));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyMessage = '';
        });
        _focusNode.requestFocus();
      }
    }
  }

  Future<void> _continueLastFolder() async {
    final location = _location;
    if (location == null || !_hasPreviousFolder) return;
    await _openBrowser(location);
  }

  Future<void> _openBrowser(LocalLibraryLocation location) async {
    _acceptGamepadEvents = false;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              SafBrowserPage(location: location, initialVrMode: _isVrMode),
        ),
      );
      await _loadPreviousFolder();
    } finally {
      _acceptGamepadEvents = true;
      await _restoreMenuInput();
    }
  }

  Future<void> _openSettings() async {
    _acceptGamepadEvents = false;
    try {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
      await _loadVrMenuScale();
    } finally {
      _acceptGamepadEvents = true;
      if (mounted) await _restoreMenuInput();
    }
  }

  Future<void> _openAbout() async {
    _acceptGamepadEvents = false;
    try {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AboutPage()));
    } finally {
      _acceptGamepadEvents = true;
      if (mounted) await _restoreMenuInput();
    }
  }

  Future<void> _openHelp() => _openInfoPage(const HelpPage());

  Future<void> _openFaq() => _openInfoPage(const FaqPage());

  Future<void> _openInfoPage(Widget page) async {
    _acceptGamepadEvents = false;
    try {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    } finally {
      _acceptGamepadEvents = true;
      if (mounted) await _restoreMenuInput();
    }
  }

  Future<void> _exitApp() => SystemNavigator.pop();

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
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
      _openAction(_selectedIndex);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.gameButtonB ||
        event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack) {
      SystemNavigator.pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _openAction(int index) {
    if (_busy || index < 0 || index >= _actions.length) return;
    final action = _actions[index];
    if (action.enabled) action.onOpen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focusNode,
        onKeyEvent: _handleKey,
        child: Stack(
          children: [
            _buildMenu(),
            if (_busy)
              ColoredBox(
                color: const Color(0x88000000),
                child: _isVrMode
                    ? MirrorSplitView(builder: (_) => _buildBusyPanel())
                    : _buildBusyPanel(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusyPanel() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(tr(context, _busyMessage), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu() {
    final actions = _actions;
    return SafeArea(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: actions.length + 2,
        itemBuilder: (context, row) {
          if (row == 0) return _logicalRow((_) => _buildHeader());
          if (row == actions.length + 1) {
            return _logicalRow(
              (_) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '↑↓ ${tr(context, 'Select')}  •  A/Y ${tr(context, 'Open')}  •  LB ${_isVrMode ? tr(context, 'Phone') : 'VR'}  •  B ${tr(context, 'Exit')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ),
            );
          }
          final index = row - 1;
          return Container(
            key: _itemKeys[index],
            child: _logicalRow((_) => _buildAction(actions[index], index)),
          );
        },
      ),
    );
  }

  Widget _logicalRow(Widget Function(BuildContext) builder) => _isVrMode
      ? StereoMenuRow(
          scale: _vrMenuScale,
          builder: (context, _) => builder(context),
        )
      : builder(context);

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      children: [
        Image.asset(
          'brand/sideby-vr-icon.png',
          width: 64,
          height: 64,
          semanticLabel: 'SideByVR',
        ),
        const SizedBox(height: 4),
        const Text(
          'SideByVR Viewer',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          tr(context, 'View your local SBS images and videos.'),
          maxLines: 2,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.lightBlueAccent,
            fontSize: 11,
            fontFamily: 'serif',
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    ),
  );

  Widget _buildAction(_MenuAction action, int index) {
    final selected = index == _selectedIndex;
    return Card(
      color: !action.enabled
          ? Colors.grey.shade900
          : selected
          ? Colors.blue.shade700
          : Colors.grey.shade900,
      child: ListTile(
        dense: true,
        enabled: action.enabled,
        leading: Icon(action.icon),
        title: Text(
          action.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          action.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          setState(() => _selectedIndex = index);
          _openAction(index);
        },
      ),
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

class _MenuAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final Future<void> Function() onOpen;

  _MenuAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.enabled = true,
    required this.onOpen,
  });
}
