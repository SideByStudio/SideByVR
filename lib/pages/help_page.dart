import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final sections = zh ? _zh : _en;
    return Scaffold(
      appBar: AppBar(title: Text(zh ? 'SideByVR 使用帮助' : 'SideByVR Help')),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            for (final section in sections) _section(context, section),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, _HelpSection section) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          for (final paragraph in section.paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(paragraph),
            ),
        ],
      ),
    ),
  );
}

class _HelpSection {
  final String title;
  final List<String> paragraphs;
  const _HelpSection(this.title, this.paragraphs);
}

const _en = [
  _HelpSection('What SideByVR does', [
    'SideByVR displays prepared side-by-side (SBS) stereoscopic images and videos through a phone VR viewer. It reads only the folder you explicitly choose with the Android system picker.',
  ]),
  _HelpSection('Minimum hardware', [
    'You need an Android phone, a compatible phone VR viewer, and a Bluetooth gamepad. A gamepad with two analog sticks, A/B/X/Y and a D-Pad is recommended.',
  ]),
  _HelpSection('Supported files and naming', [
    'Files ending in .sbs.jpg, .sbs.jpeg, .sbs.png or .sbs.mp4 are included by default. Ordinary image names can be enabled with Images as SBS in the browser.',
    'ZIP archives are supported when they are not encrypted or split. Media inside ZIP files follows the same filters.',
  ]),
  _HelpSection('First use', [
    '1. Pair your Bluetooth gamepad in Android Settings.\n2. Choose Select local folder.\n3. Grant access with the Android folder picker.\n4. Open a media group, subfolder or ZIP archive.',
  ]),
  _HelpSection('Gamepad controls', [
    'Browser: ↑/↓ select, A or Enter open, B or Esc return, and RB switches ordinary-image SBS mode.\nViewer: left stick switches and zooms, right stick pans, A/X adjust eye separation, Y resets, and B returns.',
  ]),
  _HelpSection('Troubleshooting', [
    'Nothing appears: check the filename suffix and the Images as SBS setting. If a previous folder no longer opens, choose it again because Android may revoke access after storage changes. Reconnect an unresponsive gamepad and reopen the viewer.',
  ]),
];

const _zh = [
  _HelpSection('应用用途', [
    'SideByVR 通过手机 VR 眼镜显示已经准备好的左右并排（SBS）立体图片和视频。应用只读取你通过 Android 系统选择器明确授权的目录。',
  ]),
  _HelpSection('最低硬件要求', [
    '需要一台 Android 手机、兼容的手机 VR 盒子和蓝牙游戏手柄。建议手柄包含双摇杆、A/B/X/Y 和十字键。',
  ]),
  _HelpSection('文件格式和命名', [
    '文件名以 .sbs.jpg、.sbs.jpeg、.sbs.png 或 .sbs.mp4 结尾的媒体会默认显示。普通图片文件名可以在浏览器中开启“普通图片 SBS”模式。',
    '支持未加密、非分卷 ZIP，ZIP 内媒体使用相同的过滤规则。',
  ]),
  _HelpSection('首次使用', [
    '1. 在 Android 设置中配对蓝牙手柄。\n2. 选择“选择本地目录”。\n3. 使用 Android 目录选择器授权。\n4. 打开媒体组、子目录或 ZIP。',
  ]),
  _HelpSection('手柄操作', [
    '浏览：↑/↓ 选择，A 或 Enter 打开，B 或 Esc 返回，RB 切换普通图片 SBS 模式。\n查看器：左摇杆切图和缩放，右摇杆平移，A/X 调整瞳距，Y 重置，B 返回。',
  ]),
  _HelpSection('常见问题', [
    '没有显示媒体：检查文件名后缀和“普通图片 SBS”设置。上次目录无法打开时请重新选择，Android 可能在存储变化后撤销授权。手柄无响应时重新连接蓝牙并重新进入查看器。',
  ]),
];
