import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_info.dart';
import 'l10n/app_language.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/home_menu_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await AppLanguage.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLanguage.instance,
      builder: (context, child) => MaterialApp(
        locale: AppLanguage.instance.locale,
        supportedLocales: const [Locale('en'), Locale('zh')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        title: appDisplayName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
        home: const HomeMenuPage(),
      ),
    );
  }
}
