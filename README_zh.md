<div align="center">

<img src="brand/sideby-vr-icon-master.svg" alt="SideByVR Logo" width="120" height="120">

# SideByVR Viewer

**在 Android 上，随手打开你的本地 SBS 图片与视频。**

[English](README.md) | 简体中文

<p align="center">
  <a href="VERSION"><img src="https://img.shields.io/badge/version-v0.1.0-2563eb?style=flat-square" alt="Version 0.1.0"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-f97316?style=flat-square" alt="License Apache-2.0"></a>
</p>

<p align="center">
  <strong>下载 Android 安装包</strong><br>
  <sub>首个版本准备中 · APK 下载即将开放</sub>
</p>

<!-- Release URL intentionally empty until the public repository is selected. -->
<p align="center">
  <a href="">
    <img
      src="https://img.shields.io/badge/Android%20APK-Coming%20soon-2563eb?style=for-the-badge&amp;logo=android&amp;logoColor=white"
      alt="下载 Android APK — 发布准备中"
    >
  </a>
</p>

</div>

SideByVR 是一个 Android 本地 SBS（左右并排）图片与视频查看器。选择文件夹、浏览图集，再通过手柄调整双目画面。本地查看无需账号、云端 API 配置或付费积分。

项目正在准备首个公开预览版。当前代码已通过 36 项自动化测试和 ARM64 Debug 构建，干净检出构建与真机回归仍待完成；暂未提供公开下载安装包。

## ✨ 功能特性

- 🖼️ **SBS 图片查看** — 打开包含左右眼画面的 JPG、JPEG、PNG 图片，文件名匹配不区分大小写。
- 📁 **本地媒体库** — 通过 Android 系统选择器授权目录，浏览子文件夹，并恢复上次授权的浏览位置。
- 📦 **ZIP 图集** — 打开 ZIP 内的图片集合，支持嵌套条目，使用与文件夹一致的媒体过滤规则。
- 🔀 **灵活的图片命名** — 默认识别带 `.sbs` 标记的媒体，也可主动开启普通 JPG/JPEG/PNG 文件名的 SBS 查看。
- 🎮 **手柄操作** — 切图、缩放、位移、调节眼间距，切换手机/VR 菜单并保存查看偏好。
- 🎬 **SBS 视频播放** — 打开 `.sbs.mp4`，支持播放定位和音量调整；编码兼容性取决于 Android 设备，仍需真机验证。
- 📂 **本地使用流程** — 读取用户授权的媒体并在本地缓存，无需接入账号或上传服务。

**开始查看：** 选择 **Select local folder** 并授权目录，然后打开图片组或 ZIP。对于普通图片文件名，点击 **Include ordinary images as SBS**，或按键盘 **R** / 手柄 **RB**。

| 媒体 | 选择规则 |
| --- | --- |
| `.sbs.jpg`、`.sbs.jpeg`、`.sbs.png` | 默认纳入，不区分大小写 |
| 普通 `.jpg`、`.jpeg`、`.png` | 需要明确开启普通图片 SBS 模式 |
| `.sbs.mp4` | 默认纳入，播放需要设备支持对应编码 |
| ZIP 图集 | 对压缩包内部条目应用相同的过滤规则 |

当前查看器采用 **Full-SBS、左图对应左眼** 的显示假设。Half-SBS 校正、眼序交换、上下排列、JPS/MPO 解析与 GIF 入口尚未实现。应用用于查看已有立体媒体，不生成 3D 内容；具体显示行为见[格式支持与限制](docs/usage_zh.md)。

## 🛠️ 技术栈

| 层级 | 技术 | 用途 |
| --- | --- | --- |
| 应用界面 | Flutter · Dart · Material UI | 菜单、浏览、双目显示与偏好设置 |
| Android 原生桥接 | Kotlin · Android Storage Access Framework | 目录授权、本地文件访问与手柄事件 |
| 图片处理 | `image` · Dart Isolates | 图片解码、左右眼拆分与图片缓存 |
| 视频播放 | `video_player` | 通过 Android 媒体组件播放视频 |
| 压缩包与存储 | `archive` · `path_provider` · `shared_preferences` | ZIP 解压、缓存目录与本地偏好 |
| 构建与验证 | Gradle · Java 17 · Flutter Test | Android 打包、静态分析与自动化测试 |

## 📚 文档

| 文档 | 内容 |
| --- | --- |
| [使用说明](docs/usage_zh.md) | 目录授权、操作方式、格式支持与已知限制 |
| [在线 SBS 样例](docs/samples/README_zh.md) | 在线缩略图预览与完整 SBS 原图下载链接 |
| [反馈说明](docs/feedback_zh.md) | 问题报告和设备兼容性反馈 |
| [路线图](docs/roadmap_zh.md) | 发布前待完成项与后续查看体验改进 |
| [更新日志](CHANGELOG_zh.md) | 用户可见变更及当前预览版状态 |
| [贡献指南](CONTRIBUTING_zh.md) | 贡献范围、验证要求与来源说明 |
| [第三方许可声明](THIRD_PARTY_NOTICES_zh.md) | 依赖许可证与随包署名声明 |

## 🚀 开发运行

### 环境要求

- **Flutter 3.47.0** 是当前已验证的开发基线；项目声明 Flutter ≥ 3.47.0、Dart ≥ 3.12.1 且 < 4.0.0。复现现有结果时建议使用基线版本。
- **Java 17**、**Android SDK 36**，以及 Flutter 所需的 SDK/NDK 组件。
- 交互播放和手柄验证需要 Android 设备；当前 APK 构建目标为 **ARM64**。

在仓库根目录执行以下命令，保留 `pubspec.lock` 以固定已审阅的依赖版本。

```sh
# 获取依赖
flutter pub get

# 静态检查与自动化测试
flutter analyze
flutter test

# 在已连接的 Android 设备上运行
flutter run

# 构建 ARM64 开发安装包
flutter build apk --debug --target-platform android-arm64
```

APK 生成于 `build/app/outputs/flutter-apk/app-debug.apk`。构建无需 `.env` 或生产凭据，应用标识为 `com.sidebyvr.viewer`，可与商店版并存。正式发布签名尚未配置；Debug APK 用于开发测试。

```text
lib/
├── pages/       # 菜单、本地浏览与查看器
├── widgets/     # 双目显示、图片缓存与 ZIP 处理
├── services/    # 存储桥接、手柄事件与偏好设置
└── models/      # 媒体类型与文件名选择规则
android/         # Android 工程与原生桥接
test/            # 自动化测试
docs/            # 使用说明、样例与公开文档
brand/           # 原创 SVG 图标母版
licenses/        # 分发时需保留的补充声明
```

## 📄 开源协议

应用代码、原创启动图标与生成的样例媒体均采用 **[Apache License 2.0](LICENSE)**。图标母版与说明见 [brand](brand/README_zh.md)。

第三方依赖保留各自的许可证，分发时需保留适用声明，详见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES_zh.md)。应用内可通过 **Settings → Open-source licenses** 查看随包许可证。
