import 'package:flutter_test/flutter_test.dart';
import 'package:sidebyvr/services/gamepad_events.dart';

void main() {
  group('MenuGamepadDecoder', () {
    test('supports D-Pad delivered as a key event', () {
      final decoder = MenuGamepadDecoder();
      expect(decoder.decode({'dpad': 'down'}), MenuGamepadIntent.down);
    });

    test('supports D-Pad delivered as HAT axes and waits for release', () {
      final decoder = MenuGamepadDecoder();
      expect(decoder.decode({'hatY': 1.0}), MenuGamepadIntent.down);
      expect(decoder.decode({'hatY': 1.0}), isNull);
      expect(decoder.decode({'hatY': 0.0}), isNull);
      expect(decoder.decode({'hatY': -1.0}), MenuGamepadIntent.up);
    });

    test('falls back to the left stick for menu navigation', () {
      final decoder = MenuGamepadDecoder();
      expect(decoder.decode({'leftY': -0.8}), MenuGamepadIntent.up);
    });

    test('recognizes LB display-mode toggle', () {
      final decoder = MenuGamepadDecoder();
      expect(
        decoder.decode({'button': 'lb'}),
        MenuGamepadIntent.toggleDisplayMode,
      );
    });
  });
}
