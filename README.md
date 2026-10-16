# SideByVR Viewer

An Android viewer for local side-by-side (SBS) images and videos, built with Flutter. Browse a folder selected through Android's system picker, open ZIP collections, and control the viewer with a gamepad.

[简体中文](README.zh-CN.md)

## Development status

This repository contains the initial standalone viewer migration. It is not a published release. Physical-device playback and controller validation are still pending.

- Local JPG/JPEG/PNG SBS images and `.sbs.mp4` videos; filename matching is case-insensitive and video codec support depends on the Android device.
- Local folders and ZIP archives, saved folder access, phone and VR menus.
- Gamepad navigation, zoom, image position, eye separation and viewing preferences.
- Local viewing requires no account, cloud API configuration or paid credits.

By default the browser includes only `.sbs.jpg`, `.sbs.jpeg`, `.sbs.png` and `.sbs.mp4`. Choose **Include ordinary images as SBS** to include JPG/JPEG/PNG with any filename in folders and ZIPs. Only enable this for images that already contain left/right eye views. JPS, MPO, GIF selection and additional stereo layouts are not supported. This app views existing SBS media; it does not generate 3D images or video.

## Build and test

Install Flutter 3.47.0 or newer, Java 17 and Android SDK 36. The initial migration was prepared with Flutter 3.47.0. Keep the committed dependency lockfile for reproducible dependency resolution.

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --target-platform android-arm64
```

The debug APK is generated at `build/app/outputs/flutter-apk/app-debug.apk`. No `.env` file or production signing key is required. The application ID is `com.sidebyvr.viewer`, separate from the existing commercial player. Release signing is not configured yet.

## Use

1. Copy existing SBS media or a ZIP collection onto your Android device.
2. Choose **Select local folder** and grant access in the Android folder picker.
3. For ordinary image filenames, choose **Include ordinary images as SBS** (keyboard R / gamepad RB). Then open the folder media group, a subfolder, or a ZIP archive.
4. Use a gamepad or keyboard to control the viewer; see [controls and limitations](docs/usage.md).

## Project layout

`lib/pages` contains menus, browsing and viewing; `lib/widgets` contains stereo rendering and caching; `lib/services` contains storage, controller input and preferences. `android/` provides the Android app and native storage/gamepad bridge. `test/` contains automated checks.

## License

The project is licensed under [Apache-2.0](LICENSE). Third-party dependencies retain their own licenses. Open **Settings → Open-source licenses** for bundled notices. See [third-party notices](THIRD_PARTY_NOTICES.md) for distributed attribution and review scope.
