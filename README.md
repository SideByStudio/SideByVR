# SideByVR Viewer

An Android viewer for local side-by-side (SBS) images and videos, built with Flutter. Browse a folder selected through Android's system picker, open ZIP collections, and control the viewer with a gamepad.

[简体中文](README.zh-CN.md)

## Development status

This repository contains the initial standalone viewer migration. It is not a published release. Physical-device playback and controller validation are still pending.

- Local `.sbs.jpg` images and `.sbs.mp4` videos; video codec support depends on the Android device.
- Local folders and ZIP archives, saved folder access, phone and VR menus.
- Gamepad navigation, zoom, image position, eye separation and viewing preferences.
- Local viewing requires no account, cloud API configuration or paid credits.

The current filename filter is case-sensitive and accepts only the suffixes above. General JPEG/PNG filenames, JPS, MPO, GIF selection and additional stereo layouts are not yet supported through the browser. This app views existing SBS media; it does not generate 3D images or video.

## Build and test

Install Flutter with Dart 3.12.1 or newer, Java 17 and Android SDK 36. The initial migration was prepared with Flutter 3.47.0. Keep the committed dependency lockfile for reproducible dependency resolution.

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --target-platform android-arm64
```

The debug APK is generated at `build/app/outputs/flutter-apk/app-debug.apk`. No `.env` file or production signing key is required. The application ID is `com.sidebyvr.viewer`, separate from the existing commercial player. Release signing is not configured yet.

## Use

1. Copy appropriately named SBS media or a ZIP collection onto your Android device.
2. Choose **Select local folder** and grant access in the Android folder picker.
3. Open **SBS media in this folder**, a subfolder, or a ZIP archive.
4. Use a gamepad or keyboard to control the viewer; see [controls and limitations](docs/usage.md).

## Project layout

`lib/pages` contains menus, browsing and viewing; `lib/widgets` contains stereo rendering and caching; `lib/services` contains storage, controller input and preferences. `android/` provides the Android app and native storage/gamepad bridge. `test/` contains automated checks.

## License

The project is licensed under [Apache-2.0](LICENSE). Third-party dependencies retain their own licenses. See [third-party notices](THIRD_PARTY_NOTICES.md) for the current review scope.
