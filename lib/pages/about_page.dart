import 'package:flutter/material.dart';
import '../app_info.dart';
import '../l10n/app_language.dart';
import '../services/saf_storage_service.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _open(BuildContext context, String url) async {
    try {
      await const SafStorageService().openExternalUrl(url);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                context,
                'Unable to open link. Please install a browser or try again.',
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    Widget link(String label, String url, IconData icon, Color color) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.all(16),
            ),
            onPressed: () => _open(context, url),
            icon: Icon(icon),
            label: Text(tr(context, label), textAlign: TextAlign.center),
          ),
        );
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'About'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Image.asset(
            'brand/sideby-vr-icon.png',
            height: 88,
            semanticLabel: appDisplayName,
          ),
          const SizedBox(height: 12),
          const Text(
            appDisplayName,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text(appVersion, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(
            tr(
              context,
              'Open-source Viewer APK available on GitHub · SideByVR is available on Google Play',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          link(
            'Get SideByVR on Google Play',
            'https://play.google.com/store/apps/details?id=com.sidebyvr.player&hl=${zh ? 'zh-CN' : 'en'}',
            Icons.shop_outlined,
            const Color(0xff237a42),
          ),
          link(
            'Official website',
            zh ? 'https://sideby.cc.cd/zh/' : 'https://sideby.cc.cd/',
            Icons.language,
            const Color(0xff236a9b),
          ),
          link(
            'YouTube · @SideByVR',
            'https://www.youtube.com/channel/UCjAYWJyr2qykGEuMqm6Fsjw',
            Icons.play_circle_fill,
            const Color(0xffa42c35),
          ),
          link(
            'Video guide',
            'https://www.youtube.com/watch?v=qj0_QTt65IU',
            Icons.ondemand_video,
            const Color(0xff16757a),
          ),
          link(
            'Shorts preview',
            'https://www.youtube.com/shorts/0pdG-4gmOvk',
            Icons.smart_display,
            const Color(0xff7056a5),
          ),
        ],
      ),
    );
  }
}
