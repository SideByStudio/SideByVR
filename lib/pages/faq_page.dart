import 'package:flutter/material.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final items = zh ? _zh : _en;
    return Scaffold(
      appBar: AppBar(title: Text(zh ? 'SideByVR 常见问题' : 'SideByVR FAQ')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [for (final item in items) _card(context, item)],
      ),
    );
  }

  Widget _card(BuildContext context, _FaqItem item) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.question, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(item.answer),
        ],
      ),
    ),
  );
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
}

const _en = [
  _FaqItem(
    'What equipment do I need?',
    'An Android phone, a Bluetooth gamepad and a compatible phone VR viewer. Pair the gamepad before opening the app.',
  ),
  _FaqItem(
    'Do I need an expensive VR headset?',
    'No. SideByVR is designed for a low-cost phone VR viewer. Comfort and image quality depend on your phone and lenses.',
  ),
  _FaqItem(
    'Which files can I view?',
    'SBS images and videos with supported extensions are shown. ZIP archives must be unencrypted and not split. Ordinary images require the Images as SBS option.',
  ),
  _FaqItem(
    'Why is no media shown?',
    'Check that the file is selected by the current filter and that Android still grants access to the folder. For ordinary images, enable Images as SBS.',
  ),
  _FaqItem(
    'Does the app upload my files?',
    'No. This open-source viewer works locally and does not require an account, cloud API or paid credits.',
  ),
];

const _zh = [
  _FaqItem('需要哪些设备？', '需要 Android 手机、蓝牙游戏手柄和兼容的手机 VR 盒子。请先配对手柄再打开应用。'),
  _FaqItem('需要昂贵的 VR 头显吗？', '不需要。SideByVR 面向低价手机 VR 盒子设计，舒适度和画质取决于手机和镜片。'),
  _FaqItem(
    '可以查看哪些文件？',
    '支持符合扩展名规则的 SBS 图片和视频。ZIP 必须未加密且不是分卷包。普通图片需要开启“普通图片 SBS”。',
  ),
  _FaqItem('为什么没有显示媒体？', '检查当前过滤规则和 Android 目录授权是否仍然有效。查看普通图片时请开启“普通图片 SBS”。'),
  _FaqItem('应用会上传我的文件吗？', '不会。这个开源查看器在本地运行，不需要账号、云端 API 或付费积分。'),
];
