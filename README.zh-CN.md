# SideByVR Viewer

基于 Flutter 的 Android 本地 SBS 图片与视频查看器。通过系统文件夹选择器授权目录，浏览本地文件和 ZIP 图集，使用手柄操作双目显示。

当前是独立 Viewer 的首次迁移版本，尚未公开发布，真机播放和手柄回归仍待完成。

## 当前能力

- 本地 JPG/JPEG/PNG SBS 图片、`.sbs.mp4` 视频；文件名不区分大小写，视频解码能力取决于设备。
- 系统目录授权、上次目录恢复、子目录和 ZIP 图集浏览。
- 手机/VR 菜单、手柄操作、缩放、位移、眼间距和查看偏好。
- 本地查看无需账号、云端 API 配置或 Credit。

默认仅显示 `.sbs.jpg`、`.sbs.jpeg`、`.sbs.png`、`.sbs.mp4`。在浏览页点击 **Include ordinary images as SBS**，或按键盘 R / 手柄 RB，可将普通文件名的 JPG/JPEG/PNG 纳入 SBS 查看，文件夹和 ZIP 均适用。该模式要求图片本身已经包含左右眼画面；退出浏览页后恢复默认。JPS、MPO、GIF 浏览入口和其他立体布局尚未支持。该应用用于查看已有 SBS 媒体，不生成立体图片或视频。

## 构建

准备 Flutter >= 3.47.0、Java 17 和 Android SDK 36。首次迁移使用 Flutter 3.47.0。保留锁文件以固定依赖解析结果。

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --target-platform android-arm64
```

产物为 `build/app/outputs/flutter-apk/app-debug.apk`。构建无需 `.env` 或生产签名密钥，应用标识为 `com.sidebyvr.viewer`，可与原商店版并存。发布签名尚未配置。

启动后选择 **Select local folder**，授权文件夹，再打开 **SBS media in this folder**、子目录或 ZIP。详细操作见 [使用说明](docs/usage.md)。

## 许可证

采用 [Apache-2.0](LICENSE)。第三方依赖保留各自的许可证，设置页的 **Open-source licenses** 可查看随包声明；随包声明与核查范围见 [第三方说明](THIRD_PARTY_NOTICES.md)。
