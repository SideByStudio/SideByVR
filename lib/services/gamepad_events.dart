import 'package:flutter/services.dart';

enum MenuGamepadIntent { up, down, left, right, toggleDisplayMode }

/// All pages share one platform event stream so pushing a new route does not
/// replace the native EventChannel listener owned by the previous route.
class GamepadEvents {
  GamepadEvents._();

  static const _channel = EventChannel('com.sidebyvr.viewer/gamepad_events');
  static final Stream<dynamic> stream = _channel
      .receiveBroadcastStream()
      .asBroadcastStream();
}

/// Converts continuous joystick/HAT values into one menu action per press.
class MenuGamepadDecoder {
  bool _verticalPressed = false;
  bool _horizontalPressed = false;

  MenuGamepadIntent? decode(Map<dynamic, dynamic> event) {
    if (event['button'] == 'lb') {
      return MenuGamepadIntent.toggleDisplayMode;
    }

    final dpad = event['dpad'];
    if (dpad is String) return _direction(dpad);

    final vertical = _preferredAxis(event['hatY'], event['leftY']);
    final horizontal = _preferredAxis(event['hatX'], event['leftX']);

    if (vertical.abs() < 0.25) _verticalPressed = false;
    if (horizontal.abs() < 0.25) _horizontalPressed = false;

    if (!_verticalPressed && vertical.abs() >= 0.55) {
      _verticalPressed = true;
      return vertical < 0 ? MenuGamepadIntent.up : MenuGamepadIntent.down;
    }
    if (!_horizontalPressed && horizontal.abs() >= 0.55) {
      _horizontalPressed = true;
      return horizontal < 0 ? MenuGamepadIntent.left : MenuGamepadIntent.right;
    }
    return null;
  }

  double _preferredAxis(Object? hat, Object? stick) {
    final hatValue = (hat as num?)?.toDouble() ?? 0;
    if (hatValue.abs() >= 0.25) return hatValue;
    return (stick as num?)?.toDouble() ?? 0;
  }

  MenuGamepadIntent? _direction(String direction) => switch (direction) {
    'up' => MenuGamepadIntent.up,
    'down' => MenuGamepadIntent.down,
    'left' => MenuGamepadIntent.left,
    'right' => MenuGamepadIntent.right,
    _ => null,
  };
}
