# Android Release 发布流程

## 签名策略

GitHub Releases 使用 SideByVR 专用的长期 release keystore。它与 Google Play 的 Play App Signing 密钥独立，两个渠道的 APK 不保证可以相互覆盖安装。正式密钥只保存在维护者的安全存储中，不提交到仓库。

首次配置时，将本机安全位置的 keystore 信息写入 `android/key.properties`（可参考 `android/key.properties.example`）。该文件已被 Git 忽略。丢失 release keystore 将导致后续版本无法覆盖升级已发布的 GitHub APK。

## 构建与验证

```sh
flutter --no-version-check build apk --release \
  --target-platform android-arm64 --split-per-abi --no-pub

# 生成的 ARM64 文件：
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

$ANDROID_HOME/build-tools/<version>/apksigner verify --verbose \
  build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
sha256sum build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

确认 `apksigner` 显示 v2 或更高版本验证成功，并记录 SHA-256 到 GitHub Release 的说明中。上传前可将文件重命名为 README 约定的稳定名称：

`SideByVR-viewer-0.1.0-arm64.apk`

Debug APK 只用于本地开发和真机调试，不得作为公开 Release 上传。公开 APK 必须使用同一份 release keystore 重新构建。

## GitHub Release

创建版本标签（例如 `v0.1.0`），上传稳定命名的 ARM64 APK，并在 Release 说明中记录版本、架构、签名方式和 SHA-256。README 使用 `releases/latest/download/SideByVR-viewer-0.1.0-arm64.apk` 指向最新文件；更换文件名时必须同步更新两份 README。
