import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage extends ChangeNotifier {
  AppLanguage._();
  static final instance = AppLanguage._();
  static const preferenceKey = 'app_language';
  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(preferenceKey);
    final system =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    _locale = Locale(
      saved == 'zh' || (saved == null && system == 'zh') ? 'zh' : 'en',
    );
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (code != 'zh' && code != 'en') return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(preferenceKey, code);
    _locale = Locale(code);
    notifyListeners();
  }
}

String tr(BuildContext context, String english) {
  final zh = Localizations.localeOf(context).languageCode == 'zh';
  return zh ? (_chinese[english] ?? english) : english;
}

const _chinese = <String, String>{
  "Select local folder": "选择本地文件夹",
  "Open SBS images, videos and ZIP archives": "打开 SBS 图片、视频和 ZIP 压缩包",
  "Continue last folder": "继续浏览上次文件夹",
  "Previous location": "上次位置",
  "Select a folder first": "请先选择文件夹",
  "Settings": "设置",
  "VR menu size and viewer preferences": "语言、VR 菜单大小与查看偏好",
  "Exit": "退出",
  "Close SideByVR Viewer": "关闭 SideByVR Viewer",
  "Loading library…": "正在加载媒体库…",
  "Opening Android folder picker…": "正在打开 Android 文件夹选择器…",
  "Unable to select folder": "无法选择文件夹",
  "View your local SBS images and videos.": "查看本地 SBS 图片和视频。",
  "About": "关于",
  "Help": "帮助",
  "FAQ": "常见问题",
  "Hardware, files and controls": "硬件、文件与操作",
  "Common questions and answers": "常见问题与解答",
  "Links, videos and app information": "官网、视频与应用信息",
  "Open-source licenses": "开源许可证",
  "Apache-2.0 and third-party notices": "Apache-2.0 与第三方许可声明",
  "VR menu": "VR 菜单",
  "SBS viewer": "SBS 查看器",
  "Menu size": "双栏菜单大小",
  "Viewer scale": "查看器大小",
  "Zoom": "缩放",
  "Eye separation": "眼间距",
  "Show controller hints (RB)": "显示手柄操作提示（RB）",
  "Only affects the VR split menus, not the phone menu or viewer image.":
      "仅影响 VR 横屏双栏菜单，不影响手机菜单或查看器画面。",
  "Language": "语言",
  "Retry": "重试",
  "Back": "返回",
  "Parent folder": "上级文件夹",
  "Ordinary images as SBS: ON — R to switch": "普通图片 SBS 模式：已开启 — R 切换",
  "Include ordinary images as SBS — R": "将普通图片作为 SBS 显示 — R",
  "View folder media as SBS": "以 SBS 查看文件夹媒体",
  "SBS media in this folder": "此文件夹中的 SBS 媒体",
  "No subfolders, ZIP archives,\nor matching media found.":
      "未找到子文件夹、ZIP 压缩包\n或符合条件的媒体。",
  "No SBS media found": "未找到 SBS 媒体",
  "This is the first image": "已经是第一张图片",
  "This is the last image": "已经是最后一张图片",
  "Loading": "加载中",
  "Video failed to load": "视频加载失败",
  "GIF failed to load": "GIF 加载失败",
  "Unable to open the selected folder.": "无法打开所选文件夹。",
  "Unable to open folder.": "无法打开文件夹。",
  "Unable to open media.": "无法打开媒体。",
  "Unable to open parent folder.": "无法打开上级文件夹。",
  "Phone": "手机",
  "Select": "选择",
  "Open": "打开",
  "Parent": "上级",
  "Images as SBS": "普通图片 SBS",
  "Menu": "菜单",
  "items": "项",
  "VIDEO": "视频",
  "Get SideByVR on Google Play": "在 Google Play 下载 SideByVR",
  "Official website": "官方网站",
  "Video guide": "视频使用指南",
  "Shorts preview": "竖屏宣传短片",
  "Unable to open link. Please install a browser or try again.":
      "无法打开链接，请安装浏览器或稍后重试。",
  "Open-source Viewer APK available on GitHub · SideByVR is available on Google Play":
      "开源 Viewer APK 已在 GitHub 发布 · SideByVR 已上架 Google Play",
  "Enter previous collection? Y/B": "进入上一个图集？Y 确认 / B 取消",
  "Enter next collection? Y/B": "进入下一个图集？Y 确认 / B 取消",
  "LStick↑↓: Zoom  •  LStick←→: Switch  •  RStick: Pan  •  A/X: IPD  •  Y: Reset  •  B: Back  •  RB: UI":
      "左摇杆↑↓：缩放  •  左摇杆←→：切图  •  右摇杆：平移  •  A/X：眼间距  •  Y：重置  •  B：返回  •  RB：提示",
  "LStick↑↓: Zoom  •  LStick←→: Switch  •  RStick: Pan  •  A/X: IPD  •  Y: Play/Pause  •  B: Back  •  RB: UI":
      "左摇杆↑↓：缩放  •  左摇杆←→：切图  •  右摇杆：平移  •  A/X：眼间距  •  Y：播放/暂停  •  B：返回  •  RB：提示",
  "DPad←/→: Seek ±5s  •  DPad↑/↓: Volume  •  LStick↑↓: Zoom  •  RStick: Pan  •  A/X: IPD  •  Y: Play/Pause  •  B: Back  •  RB: UI":
      "方向键←/→：快退/进 5 秒  •  方向键↑/↓：音量  •  左摇杆↑↓：缩放  •  右摇杆：平移  •  A/X：眼间距  •  Y：播放/暂停  •  B：返回  •  RB：提示",
};
