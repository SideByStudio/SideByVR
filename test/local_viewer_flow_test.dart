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

  for (final filename in ['sample.sbs.jpg', 'ordinary.JPEG', 'ordinary.PNG']) {
    testWidgets(
      'local folder opens $filename with explicit opt-in when needed',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final temporary = Directory.systemTemp.createTempSync('sidebyvr_flow_');
        addTearDown(() => temporary.deleteSync(recursive: true));
        final file = File('${temporary.path}/$filename');
        final pixels = img.Image(width: 32, height: 16);
        for (var y = 0; y < 16; y++) {
          for (var x = 0; x < 32; x++) {
            pixels.setPixelRgb(x, y, x < 16 ? 255 : 0, 0, x < 16 ? 0 : 255);
          }
        }
        file.writeAsBytesSync(
          filename.endsWith('PNG')
              ? img.encodePng(pixels)
              : img.encodeJpg(pixels),
        );
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
                  'name': filename,
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
        final ordinary = filename.startsWith('ordinary');
        if (ordinary) {
          expect(find.text('SBS media in this folder'), findsNothing);
          expect(calls, isNot(contains('copyDocumentToCache')));
          await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
          await tester.pumpAndSettle();
          expect(find.text('View folder media as SBS'), findsOneWidget);
        }
        // Start image decoding in the real async zone.
        await tester.runAsync(() async {
          await tester.tap(
            find.text(
              ordinary
                  ? 'View folder media as SBS'
                  : 'SBS media in this folder',
            ),
          );
          await tester.pumpAndSettle();
          final viewer = tester.widget<StereoView>(find.byType(StereoView));
          final stereo = await viewer.imageSource
              .load(viewer.cache)
              .timeout(const Duration(seconds: 10));
          expect(stereo.left.width, 16);
          expect(stereo.right.width, 16);
          expect(stereo.left.height, 16);
          final left = await stereo.left.toByteData();
          final right = await stereo.right.toByteData();
          expect(left!.getUint8(0), greaterThan(200));
          expect(left.getUint8(2), lessThan(30));
          expect(right!.getUint8(2), greaterThan(200));
          expect(right.getUint8(0), lessThan(30));
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
        await tester.runAsync(() async {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
        });
        await tester.pumpAndSettle();
        expect(find.byType(SafBrowserPage), findsOneWidget);
        if (ordinary) {
          await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonRight1);
          await tester.pumpAndSettle();
          expect(find.text('View folder media as SBS'), findsNothing);
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('Continue last folder'), findsOneWidget);
        expect(calls, contains('hasPersistedAccess'));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
