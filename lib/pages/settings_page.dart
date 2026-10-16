import 'package:flutter/material.dart';
import '../services/vr_menu_preferences.dart';
import '../app_info.dart';

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
    appBar: AppBar(title: const Text('Settings')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Open-source licenses'),
          subtitle: const Text('Apache-2.0 and third-party notices'),
          onTap: () => showLicensePage(
            context: context,
            applicationName: appDisplayName,
            applicationVersion: appVersion,
            applicationLegalese:
                'Licensed under Apache-2.0. Third-party components retain their own licenses.',
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'VR menu',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text('双栏菜单大小：${(_scale * 100).round()}%'),
        Slider(
          value: _scale,
          min: 0.5,
          max: 1.0,
          divisions: 10,
          label: '${(_scale * 100).round()}%',
          onChanged: _setScale,
        ),
        const Text(
          '仅影响 VR 横屏下的左右双栏菜单，手机竖屏和查看器画面不受影响。',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 28),
        const Text(
          'SBS viewer',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text('Viewer Scale：${(_viewerScale * 100).round()}%'),
        Slider(
          value: _viewerScale,
          min: 0.5,
          max: 1.0,
          divisions: 10,
          onChanged: (v) => _setViewer(scale: v),
        ),
        Text('Zoom：${_zoom.toStringAsFixed(1)}x'),
        Slider(
          value: _zoom,
          min: 0.5,
          max: 3.0,
          divisions: 50,
          onChanged: (v) => _setViewer(zoom: v),
        ),
        Text('IPD：${_ipd.toStringAsFixed(0)} px'),
        Slider(
          value: _ipd,
          min: -50,
          max: 50,
          divisions: 20,
          onChanged: (v) => _setViewer(ipd: v),
        ),
        SwitchListTile(
          title: const Text('显示 RB 提示 UI'),
          value: _showUi,
          onChanged: (v) => _setViewer(showUi: v),
        ),
      ],
    ),
  );
}
