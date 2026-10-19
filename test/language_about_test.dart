import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidebyvr/main.dart';
import 'package:sidebyvr/l10n/app_language.dart';
import 'package:sidebyvr/pages/about_page.dart';
import 'package:sidebyvr/pages/settings_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({'app_language': 'en'});
    await AppLanguage.instance.load();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.sidebyvr.viewer/gamepad_events'),
          (_) async => null,
        );
  });
  testWidgets(
    'settings switches the entire app, persists language and disables licenses',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      final tile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Open-source licenses'),
          matching: find.byType(ListTile),
        ),
      );
      expect(tile.enabled, false);
      expect(tile.onTap, isNull);
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('简体中文').last);
      await tester.pumpAndSettle();
      expect(find.text('设置'), findsOneWidget);
      expect(find.textContaining('双栏菜单大小'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getString('app_language'),
        'zh',
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('选择本地文件夹'), findsOneWidget);
      await tester.ensureVisible(find.text('关于'));
      await tester.tap(find.text('关于'));
      await tester.pumpAndSettle();
      expect(find.byType(AboutPage), findsOneWidget);
      expect(find.text('官方网站'), findsOneWidget);
      await AppLanguage.instance.load();
      expect(AppLanguage.instance.locale.languageCode, 'zh');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    },
  );
  testWidgets('About opens each official link and handles unavailable browsers', (
    tester,
  ) async {
    final urls = <String>[];
    var fail = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.sidebyvr.viewer/storage'),
          (call) async {
            expect(call.method, 'openExternalUrl');
            if (fail) throw PlatformException(code: 'unavailable');
            urls.add(call.arguments['url'] as String);
            return true;
          },
        );
    await tester.pumpWidget(const MaterialApp(home: AboutPage()));
    for (final label in [
      'Get SideByVR on Google Play',
      'Official website',
      'YouTube · @SideByVR',
      'Video guide',
      'Shorts preview',
    ]) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    expect(urls, [
      'https://play.google.com/store/apps/details?id=com.sidebyvr.player&hl=en',
      'https://sideby.cc.cd/',
      'https://www.youtube.com/channel/UCjAYWJyr2qykGEuMqm6Fsjw',
      'https://www.youtube.com/watch?v=qj0_QTt65IU',
      'https://www.youtube.com/shorts/0pdG-4gmOvk',
    ]);
    fail = true;
    await tester.tap(find.text('Shorts preview'));
    await tester.pump();
    expect(
      find.text('Unable to open link. Please install a browser or try again.'),
      findsOneWidget,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.sidebyvr.viewer/storage'),
          null,
        );
  });
}
