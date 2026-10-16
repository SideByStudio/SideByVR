# 第三方许可说明

[English](THIRD_PARTY_NOTICES.md) | 简体中文

应用代码采用 [Apache-2.0](LICENSE)。第三方代码、字体和工具保留各自许可证。此页为中文说明，法律文本以随包许可证原文为准。

## 核查范围

当前核查覆盖锁定的 `pubspec.lock`、Flutter 3.47.0（引擎 `5f77625673248ee5846fbcaf5d3e1a3878386fd7`）和 2026-10-16 解析的 Android ARM64 Debug 运行时依赖图，含 71 个 Dart/SDK 包及 100 个 Android Maven 组件。开发测试包、其他平台包及 BOM 也保守纳入，并非全部都会进入 APK。

## 分发声明

[补充声明原文](licenses/additional_notices.txt)保留额外上游署名和许可证。Flutter 自动将 Dart 包主许可证和引擎声明收集到应用。完整 POM 和哈希清单由维护者单独保存，不是构建本仓库的前提。

`image` 包包含衍生编解码代码，除 MIT 主声明外，还有 JPEG、WebP、TIFF、OpenEXR、PVRTC 和 QuickPVR 声明；`archive` 包含 zlib/JZLib、bzip2 和 Bouncy Castle 衍生代码。相关补充文本完整保留。

Android 依赖主要声明 Apache-2.0，例外是 DataStore 重打包的 Protocol Buffers（BSD-3-Clause）和 Flutter 引擎聚合声明。Protocol Buffers 的版权为 Copyright 2008 Google Inc.；保留的通用上游 BSD 文本来自 v3.25.5，但 DataStore 的 POM 没有确定内部 protobuf 的准确版本，因此不能据此认定使用该版本。

Material Icons 由 Google 提供；当前 Flutter SDK 实际附带许可为 **CC BY 4.0**，原文收录在补充声明中。来源：https://github.com/google/material-design-icons 。字体源文件未修改，Release 构建可能执行字形子集化；不暗示 Google 背书。未使用或打包 Cupertino Icons。

[启动图标母版](brand/sideby-vr-icon-master.svg)由项目作者创作，母版和 Android 衍生资源与代码共同采用 Apache-2.0。使用说明的设备插画经用户提供并授权用于文档，经过缩小与 JPEG 压缩。在线样例仅引用网站 URL，其媒体条款以网站为准，不自动适用本仓库的代码许可证。Gradle wrapper 由 Flutter 在本地生成且不跟踪，Gradle 保留其 Apache-2.0 许可。

## 应用内查看与分发

打开 **Settings → Open-source licenses** 查看 Flutter 生成的许可证列表。项目许可证及包声明自动收集；`pubspec.yaml` 的 `flutter.licenses` 额外加入 image/archive、Material Icons、Android Apache-2.0 组件、ExifInterface 提取声明和 protobuf 署名。

分发时保留适用声明。升级依赖、Flutter、构建模式或 ABI 后，需要刷新审计清单并检查 APK 声明。POM 和保留文本是依赖审阅证据，不是上游全部代码作者身份或设备媒体编解码专利许可的证明。
