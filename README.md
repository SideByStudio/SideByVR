<div align="center">

<img src="brand/sideby-vr-icon-master.svg" alt="SideByVR Logo" width="120" height="120">

# SideByVR Viewer

**Your local SBS images and videos, ready for a closer look.**

English | [简体中文](README_zh.md)

<p align="center">
  <a href="VERSION"><img src="https://img.shields.io/badge/version-v0.1.0-2563eb?style=flat-square" alt="Version 0.1.0"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-f97316?style=flat-square" alt="License Apache-2.0"></a>
</p>

<p align="center">
  <strong>Download for Android</strong><br>
  <sub>First release in preparation · APK download coming soon</sub>
</p>

<!-- Release URL intentionally empty until the public repository is selected. -->
<p align="center">
  <a href="">
    <img
      src="https://img.shields.io/badge/Android%20APK-Coming%20soon-2563eb?style=for-the-badge&amp;logo=android&amp;logoColor=white"
      alt="Android APK — coming soon"
    >
  </a>
</p>

</div>

SideByVR turns an Android phone into a local viewer for existing side-by-side (SBS) images and videos. Select a folder, browse your collections, and use a gamepad to adjust the view. Local viewing requires no account, cloud API configuration or paid credits.

The project is preparing its first public preview. The current code has passed 36 automated tests and an ARM64 Debug build; clean-checkout and physical-device validation are still pending. An installable public release is not available yet.

## ✨ Features

- 🖼️ **SBS image viewing** — Open JPG, JPEG and PNG images containing left/right eye views. Filename matching is case-insensitive.
- 📁 **Your local library** — Choose a folder through Android's system picker, browse subfolders, and return to the previously authorized folder.
- 📦 **ZIP collections** — Browse image collections directly from ZIP archives, including nested entries, with the same media filters as folders.
- 🔀 **Flexible image filenames** — Keep the default `.sbs` filter or explicitly include ordinary JPG/JPEG/PNG filenames with **Include ordinary images as SBS**.
- 🎮 **Gamepad controls** — Switch images, zoom, pan and adjust eye separation; switch between phone and VR menus and save viewing preferences.
- 🎬 **SBS video playback** — Open `.sbs.mp4` videos, seek and adjust volume. Codec compatibility depends on the Android device and remains subject to hardware testing.
- 📂 **Local-first workflow** — Read the media you authorize and cache it locally, without a hosted account or upload flow.

**Start viewing:** select **Select local folder**, grant access, then open the media group or a ZIP. For ordinary image filenames, enable **Include ordinary images as SBS** with the on-screen button, keyboard **R** or gamepad **RB**.

| Media | Selection behavior |
| --- | --- |
| `.sbs.jpg`, `.sbs.jpeg`, `.sbs.png` | Included by default; letter case does not matter |
| Ordinary `.jpg`, `.jpeg`, `.png` | Explicit Images as SBS opt-in required |
| `.sbs.mp4` | Included by default; device codec support required |
| ZIP archives | The same filter applies to entries inside the archive |

The current viewer assumes **Full-SBS, left image for the left eye**. Half-SBS correction, eye swapping, top/bottom layouts, JPS/MPO parsing and GIF selection are not implemented. It displays existing stereo media and does not generate 3D content. See the [format matrix and limitations](docs/usage.md) for rendering details.

## 🛠️ Stack

| Layer | Technologies | Purpose |
| --- | --- | --- |
| Application | Flutter · Dart · Material UI | Menus, browsing, stereo presentation and preferences |
| Android bridge | Kotlin · Android Storage Access Framework | Directory authorization, local file access and gamepad events |
| Image processing | `image` · Dart Isolates | Decode images, split eye views and maintain an image cache |
| Video playback | `video_player` | Playback through the Android media stack |
| Archives and storage | `archive` · `path_provider` · `shared_preferences` | ZIP extraction, cache directories and local preferences |
| Build and verification | Gradle · Java 17 · Flutter Test | Android packaging, static analysis and automated tests |

## 📚 Documentation

| Document | Contents |
| --- | --- |
| [Usage guide](docs/usage.md) | Folder access, controls, supported formats and known limitations |
| [Online SBS samples](docs/samples/README.md) | Remote thumbnail gallery and full SBS image download links |
| [Feedback](docs/feedback.md) | Bug reports and device compatibility information |
| [Roadmap](docs/roadmap.md) | Release prerequisites and future viewer improvements |
| [Changelog](CHANGELOG.md) | User-visible changes and current preview status |
| [Contributing](CONTRIBUTING.md) | Contribution scope, validation and source attribution |
| [Third-party notices](THIRD_PARTY_NOTICES.md) | Dependency licenses and bundled acknowledgments |

## 🚀 Development

### Requirements

- **Flutter 3.47.0** is the verified development baseline; the project declares Flutter ≥ 3.47.0 and Dart ≥ 3.12.1, < 4.0.0. Prefer the baseline SDK when reproducing the current results.
- **Java 17** and **Android SDK 36**, with the SDK/NDK components required by Flutter.
- An Android device for interactive playback and gamepad testing. The current APK build target is **ARM64**.

Run these commands from the repository root. Keep `pubspec.lock` to preserve the reviewed dependency versions.

```sh
# Resolve dependencies
flutter pub get

# Analyze and test
flutter analyze
flutter test

# Run on a connected Android device
flutter run

# Build an ARM64 development APK
flutter build apk --debug --target-platform android-arm64
```

The APK is generated at `build/app/outputs/flutter-apk/app-debug.apk`. Building the viewer requires no `.env` file or production credentials. Its application ID is `com.sidebyvr.viewer`, allowing it to coexist with the commercial player. Release signing is not configured; Debug APKs are development artifacts.

```text
lib/
├── pages/       # Menus, local browsing and viewer
├── widgets/     # Stereo rendering, image cache and ZIP handling
├── services/    # Storage bridge, gamepad events and preferences
└── models/      # Media types and filename selection
android/         # Android app and native bridge
test/            # Automated tests
docs/            # Usage, samples and contributor-facing documentation
brand/           # Original SVG icon master
licenses/        # Supplemental distribution notices
```

## 📄 License

Application code, the original launcher icon and generated sample media are licensed under **[Apache License 2.0](LICENSE)**. See [brand documentation](brand/README.md) for the icon source.
