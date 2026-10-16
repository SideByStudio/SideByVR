import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidebyvr/main.dart';
import 'package:sidebyvr/pages/saf_browser_page.dart';
import 'package:sidebyvr/pages/viewer_page.dart';
import 'package:sidebyvr/widgets/stereo_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = MethodChannel('com.sidebyvr.viewer/storage');
  const gamepad = MethodChannel('com.sidebyvr.viewer/gamepad_events');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  testWidgets(
    'local folder opens an SBS image and returns without an account',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final temporary = Directory.systemTemp.createTempSync('sidebyvr_flow_');
      addTearDown(() => temporary.deleteSync(recursive: true));
      final file = File('${temporary.path}/sample.sbs.jpg');
      file.writeAsBytesSync(img.encodeJpg(img.Image(width: 32, height: 16)));
      final calls = <String>[];
      messenger.setMockMethodCallHandler(gamepad, (_) async => null);
      messenger.setMockMethodCallHandler(storage, (call) async {
        calls.add(call.method);
        switch (call.method) {
          case 'pickDirectory':
            return {
              'uri': 'content://test/root',
              'name': 'Local album',
              'isDirectory': true,
            };
          case 'listChildren':
            return [
              {
                'uri': 'content://test/root/image',
                'name': 'sample.sbs.jpg',
                'isDirectory': false,
              },
            ];
          case 'copyDocumentToCache':
            return file.path;
          case 'hasPersistedAccess':
            return true;
          default:
            throw StateError('Unexpected platform method: ${call.method}');
        }
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(storage, null);
        messenger.setMockMethodCallHandler(gamepad, null);
      });

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(find.text('Select local folder'), findsOneWidget);
      expect(find.textContaining('Account'), findsNothing);
      await tester.tap(find.text('Select local folder'));
      await tester.pumpAndSettle();
      expect(find.byType(SafBrowserPage), findsOneWidget);
      // Start image decoding in the real async zone.
      await tester.runAsync(() async {
        await tester.tap(find.text('SBS media in this folder'));
        await tester.pumpAndSettle();
        final viewer = tester.widget<StereoView>(find.byType(StereoView));
        await viewer.imageSource
            .load(viewer.cache)
            .timeout(const Duration(seconds: 10));
      });
      await tester.pumpAndSettle();
      expect(find.byType(ViewerPage), findsOneWidget);
      expect(find.text('加载中'), findsNothing);
      expect(
        calls,
        containsAllInOrder([
          'pickDirectory',
          'listChildren',
          'copyDocumentToCache',
        ]),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(SafBrowserPage), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Continue last folder'), findsOneWidget);
      expect(calls, contains('hasPersistedAccess'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
