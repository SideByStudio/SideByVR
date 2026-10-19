import 'package:flutter/material.dart';
import '../services/vr_menu_preferences.dart';
import '../l10n/app_language.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _preferences = const VrMenuPreferences();
  double _scale = VrMenuPreferences.defaultScale;
  double _viewerScale = VrMenuPreferences.defaultScale;
  double _zoom = VrMenuPreferences.defaultZoom;
  double _ipd = VrMenuPreferences.defaultIpd;
  bool _showUi = VrMenuPreferences.defaultShowUi;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await _preferences.loadScale();
    final viewer = await _preferences.loadViewer();
    if (mounted) {
      setState(() {
        _scale = value;
        _viewerScale = viewer['scale']! as double;
        _zoom = viewer['zoom']! as double;
        _ipd = viewer['ipd']! as double;
        _showUi = viewer['showUi']! as bool;
      });
    }
  }

  Future<void> _setViewer({
    double? scale,
    double? zoom,
    double? ipd,
    bool? showUi,
  }) async {
    setState(() {
      if (scale != null) _viewerScale = scale;
      if (zoom != null) _zoom = zoom;
      if (ipd != null) _ipd = ipd;
      if (showUi != null) _showUi = showUi;
    });
    await _preferences.saveViewer(
      scale: scale,
      zoom: zoom,
      ipd: ipd,
      showUi: showUi,
    );
  }

  Future<void> _setScale(double value) async {
    setState(() => _scale = value);
    await _preferences.saveScale(value);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr(context, 'Settings'))),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(tr(context, 'Language')),
          trailing: DropdownButton<String>(
            value: Localizations.localeOf(context).languageCode,
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'zh', child: Text('简体中文')),
            ],
            onChanged: (value) {
              if (value != null) AppLanguage.instance.setLanguage(value);
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(tr(context, 'Open-source licenses')),
          subtitle: Text(tr(context, 'Apache-2.0 and third-party notices')),
          enabled: false,
        ),
        const SizedBox(height: 20),
        Text(
          tr(context, 'VR menu'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text('${tr(context, 'Menu size')}: ${(_scale * 100).round()}%'),
        Slider(
          value: _scale,
          min: 0.5,
          max: 1.0,
          divisions: 10,
          label: '${(_scale * 100).round()}%',
          onChanged: _setScale,
        ),
        Text(
          tr(
            context,
            'Only affects the VR split menus, not the phone menu or viewer image.',
          ),
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 28),
        Text(
          tr(context, 'SBS viewer'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          '${tr(context, 'Viewer scale')}: ${(_viewerScale * 100).round()}%',
        ),
        Slider(
          value: _viewerScale,
          min: 0.5,
          max: 1.0,
          divisions: 10,
          onChanged: (v) => _setViewer(scale: v),
        ),
        Text('${tr(context, 'Zoom')}: ${_zoom.toStringAsFixed(1)}x'),
        Slider(
          value: _zoom,
          min: 0.5,
          max: 3.0,
          divisions: 50,
          onChanged: (v) => _setViewer(zoom: v),
        ),
        Text('${tr(context, 'Eye separation')}: ${_ipd.toStringAsFixed(0)} px'),
        Slider(
          value: _ipd,
          min: -50,
          max: 50,
          divisions: 20,
          onChanged: (v) => _setViewer(ipd: v),
        ),
        SwitchListTile(
          title: Text(tr(context, 'Show controller hints (RB)')),
          value: _showUi,
          onChanged: (v) => _setViewer(showUi: v),
        ),
      ],
    ),
  );
}
