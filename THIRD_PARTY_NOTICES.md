# Third-party notices

English | [简体中文](THIRD_PARTY_NOTICES_zh.md)

SideByVR Viewer application code is licensed under [Apache-2.0](LICENSE). Third-party code, fonts and tools retain their own licenses.

The current review covers the committed `pubspec.lock`, Flutter 3.47.0 (engine `5f77625673248ee5846fbcaf5d3e1a3878386fd7`), and the Android ARM64 Debug runtime dependency graph resolved on 2026-10-16. It includes 71 Dart/SDK packages and 100 Android Maven components; test-only packages, other-platform packages and BOM entries are included conservatively.

## Distributed notices

[Supplemental notices](licenses/additional_notices.txt) preserve additional upstream attribution and license texts. Flutter automatically collects primary Dart package and engine notices into the application. Full POM copies and hash inventories are maintained separately by the project maintainer and are not required to build this repository.

## Included acknowledgments

The `image` package contains derived image codec code; its MIT header is not the only applicable statement. Its additional notices cover JPEG, WebP, TIFF, OpenEXR, PVRTC and QuickPVR sources. The `archive` package includes zlib/JZLib, bzip2 and Bouncy Castle-derived code. The original supplemental texts are preserved in full.

Android dependencies declare Apache-2.0, except the DataStore repackaged Protocol Buffers component (BSD-3-Clause) and Flutter artifacts (engine aggregate notices). Protocol Buffers is Copyright 2008 Google Inc.; its upstream BSD notice is retained. DataStore's POM establishes the component license but does not identify its internal protobuf version; the retained canonical upstream text is sourced from protobuf v3.25.5 and is not a claim that this exact version is embedded.

Material Icons are by Google, supplied with this Flutter SDK. The SDK's actual `MaterialIcons_LICENSE.txt` identifies **CC BY 4.0**; this exact text is retained in [font notices](licenses/additional_notices.txt). Source: <https://github.com/google/material-design-icons>. The source font is unmodified; Flutter release builds may subset glyphs. No endorsement by Google is implied. Cupertino Icons are not used or bundled.

The [launcher icon master](brand/sideby-vr-icon-master.svg) was created by the project author; the master and its derived Android resources are licensed under Apache-2.0 together with the code. The equipment illustration in the usage guide was supplied by the user for documentation and resized/recompressed. Online samples are referenced by URL only; their media terms follow the website and are not automatically replaced by this repository's code license. Gradle wrapper tooling is generated locally by Flutter and is not tracked in the source repository; Gradle retains its own Apache-2.0 license.

## In-app access and distribution

The **Settings → Open-source licenses** item is informational and non-clickable. Flutter-generated notices remain bundled in the APK. The project's Apache-2.0 license and package notices are collected by Flutter. [Supplemental notices](licenses/additional_notices.txt) add image/archive attribution, Material Icons, native Apache-2.0 components, the extracted ExifInterface notice and protobuf attribution through `flutter.licenses` in `pubspec.yaml`.

Preserve these notices when distributing the app. Updating dependencies, Flutter, build mode or ABI requires refreshing the inventory and inspecting the resulting APK notice bundle. POM declarations and retained notices provide a documented dependency review; they are not proof of authorship of all upstream code or patent clearance for device-provided media codecs.

The language feature adds Flutter SDK localizations and intl 0.20.3 (BSD-3-Clause); Flutter collects their license notices automatically.
