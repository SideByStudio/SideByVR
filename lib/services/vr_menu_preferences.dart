import 'package:shared_preferences/shared_preferences.dart';

class VrMenuPreferences {
  static const key = 'vr_menu_scale';
  static const defaultScale = 0.8;
  static const defaultZoom = 0.8;
  static const defaultIpd = 0.0;
  static const defaultShowUi = true;

  const VrMenuPreferences();

  Future<double> loadScale() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getDouble(key) ?? defaultScale;
    return value.clamp(0.5, 1.0);
  }

  Future<void> saveScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value.clamp(0.5, 1.0));
  }

  Future<Map<String, Object>> loadViewer() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'scale': (prefs.getDouble('sbs_viewer_scale') ?? defaultScale).clamp(
        0.5,
        1.0,
      ),
      'zoom': (prefs.getDouble('sbs_viewer_zoom') ?? defaultZoom).clamp(
        0.5,
        3.0,
      ),
      'ipd': (prefs.getDouble('sbs_viewer_ipd') ?? defaultIpd).clamp(
        -50.0,
        50.0,
      ),
      'showUi': prefs.getBool('sbs_viewer_show_ui') ?? defaultShowUi,
    };
  }

  Future<void> saveViewer({
    double? scale,
    double? zoom,
    double? ipd,
    bool? showUi,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (scale != null) {
      await prefs.setDouble('sbs_viewer_scale', scale.clamp(0.5, 1.0));
    }
    if (zoom != null) {
      await prefs.setDouble('sbs_viewer_zoom', zoom.clamp(0.5, 3.0));
    }
    if (ipd != null) {
      await prefs.setDouble('sbs_viewer_ipd', ipd.clamp(-50.0, 50.0));
    }
    if (showUi != null) await prefs.setBool('sbs_viewer_show_ui', showUi);
  }
}
